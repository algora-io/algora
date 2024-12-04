defmodule Algora.ContractsTest do
  use Algora.DataCase
  import Algora.Factory
  import Money.Sigil
  alias Algora.Contracts
  alias Algora.Payments.Transaction

  def card_declined_error(),
    do: %Stripe.Error{
      source: :stripe,
      code: :card_error,
      message: "Your card was declined."
    }

  # Mock implementation for Stripe API calls
  defmodule MockStripe do
    def create_invoice(params) do
      {:ok, %{id: "inv_mock", customer: params.customer}}
    end

    def create_invoice_item(params) do
      {:ok, %{id: "ii_mock", amount: params.amount}}
    end

    def pay_invoice(_invoice_id, _params) do
      {:ok, %{id: "inv_mock", paid: true, status: "paid"}}
    end

    def create_transfer(_params) do
      {:ok, %{id: "tr_mock"}}
    end
  end

  defmodule MockStripeWithFailure do
    def create_invoice(params) do
      {:ok, %{id: "inv_mock", customer: params.customer}}
    end

    def create_invoice_item(params) do
      {:ok, %{id: "ii_mock", amount: params.amount}}
    end

    def create_transfer(_params) do
      {:ok, %{id: "tr_mock"}}
    end

    def pay_invoice(_invoice_id, _params) do
      {:error, Algora.ContractsTest.card_declined_error()}
    end
  end

  setup do
    # Set the mock implementation for tests
    Application.put_env(:algora, :stripe_impl, MockStripe)

    on_exit(fn ->
      # Reset to default implementation after test
      Application.delete_env(:algora, :stripe_impl)
    end)
  end

  defp setup_contract_test_data(attrs) do
    client = insert!(:organization)
    contractor = insert!(:user)
    customer = insert!(:customer, %{user: client})
    payment_method = insert!(:payment_method, %{customer: customer})

    contract = insert!(:contract, Map.merge(%{client: client, contractor: contractor}, attrs))

    %{
      client: client,
      contractor: contractor,
      customer: customer,
      payment_method: payment_method,
      contract: contract
    }
  end

  describe "contract payments" do
    test "initial prepayment calculates correct amounts" do
      %{contract: contract} =
        setup_contract_test_data(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      # Calculate expected amounts
      net_amount = ~M[4000]usd
      platform_fee = ~M[760]usd
      transaction_fee = ~M[160]usd
      total_fee = ~M[920]usd
      gross_amount = ~M[4920]usd

      # Initialize the prepayment transaction
      {:ok, charge} = Contracts.prepay_contract(contract)

      # Verify amounts
      assert Money.equal?(charge.net_amount, net_amount)
      assert Money.equal?(charge.gross_amount, gross_amount)
      assert Money.equal?(charge.total_fee, total_fee)

      # Verify line items
      [prepayment, platform_fee_item, transaction_fee_item] = charge.line_items

      assert Money.equal?(prepayment.amount, net_amount)
      assert prepayment.description =~ "40 hours @ $100.00/hr"

      assert Money.equal?(platform_fee_item.amount, platform_fee)
      assert platform_fee_item.description =~ "19%"

      assert Money.equal?(transaction_fee_item.amount, transaction_fee)
      assert transaction_fee_item.description =~ "4%"
    end

    test "fees decrease appropriately across multiple contract cycles" do
      %{contract: contract0} =
        setup_contract_test_data(%{hourly_rate: ~M[50]usd, hours_per_week: 20})

      # Initial prepayment (19% fee tier)
      {:ok, initial_charge} = Contracts.prepay_contract(contract0)
      assert Money.equal?(initial_charge.net_amount, ~M[1000]usd)
      assert Money.equal?(initial_charge.total_fee, ~M[230]usd)

      # First cycle (still 19% tier)
      timesheet = insert!(:timesheet, %{contract_id: contract0.id, hours_worked: 40})
      {:ok, {charge1, transfer1, contract1}} = Contracts.release_and_renew_contract(timesheet)
      assert Money.equal?(charge1.net_amount, ~M[2000]usd)
      assert Money.equal?(transfer1.net_amount, ~M[2000]usd)
      assert Money.equal?(charge1.total_fee, Money.mult!(charge1.net_amount, Decimal.new("0.23")))

      # Second cycle (drops to 15% tier)
      timesheet = insert!(:timesheet, %{contract_id: contract1.id, hours_worked: 60})
      {:ok, {charge2, transfer2, contract2}} = Contracts.release_and_renew_contract(timesheet)
      assert Money.equal?(charge2.net_amount, ~M[3000]usd)
      assert Money.equal?(transfer2.net_amount, ~M[3000]usd)
      assert Money.equal?(charge2.total_fee, Money.mult!(charge2.net_amount, Decimal.new("0.19")))

      # Third cycle (drops to 10% tier)
      timesheet = insert!(:timesheet, %{contract_id: contract2.id, hours_worked: 80})
      {:ok, {charge3, transfer3, _contract3}} = Contracts.release_and_renew_contract(timesheet)
      assert Money.equal?(charge3.net_amount, ~M[4000]usd)
      assert Money.equal?(transfer3.net_amount, ~M[4000]usd)
      assert Money.equal?(charge3.total_fee, Money.mult!(charge3.net_amount, Decimal.new("0.14")))

      # Verify total charged to client
      total_charged = Contracts.calculate_total_charged_to_client_net(contract0)
      assert Money.equal?(total_charged, ~M[10_000]usd)

      # Verify total transferred to contractor
      total_transferred = Contracts.calculate_total_transferred_to_contractor(contract0)
      assert Money.equal?(total_transferred, ~M[9_000]usd)
    end

    test "prepayment fails when payment method is invalid" do
      %{contract: contract} =
        setup_contract_test_data(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      payment_error = card_declined_error()

      Application.put_env(:algora, :stripe_impl, MockStripeWithFailure)

      {:error, ^payment_error} = Contracts.prepay_contract(contract)

      # Verify charge was marked as failed
      charge = Repo.one(from t in Transaction, where: t.contract_id == ^contract.id)
      assert charge.status == :failed

      assert %{"error" => %{"code" => "card_error", "message" => "Your card was declined."}} =
               charge.provider_meta
    end

    test "release payment handles partial prepayment correctly" do
      %{contract: contract} =
        setup_contract_test_data(%{hourly_rate: ~M[100]usd, hours_per_week: 20})

      # Initial prepayment for 20 hours
      {:ok, _charge} = Contracts.prepay_contract(contract)

      # Submit timesheet for 30 hours (10 more than prepaid)
      timesheet = insert!(:timesheet, %{contract_id: contract.id, hours_worked: 30})
      {:ok, {charge, transfer}} = Contracts.release_contract(timesheet)

      # Verify amounts
      # Additional 10 hours @ $100
      assert Money.equal?(charge.net_amount, ~M[1000]usd)
      # Full 30 hours payment
      assert Money.equal?(transfer.net_amount, ~M[3000]usd)
    end

    test "contract renewal maintains correct chain relationship" do
      %{contract: original_contract} =
        setup_contract_test_data(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      timesheet = insert!(:timesheet, %{contract_id: original_contract.id, hours_worked: 40})

      {:ok, {_charge, _transfer, renewed_contract}} =
        Contracts.release_and_renew_contract(timesheet)

      # Verify chain relationships
      assert renewed_contract.original_contract_id == original_contract.id
      assert renewed_contract.sequence_number == 2

      # Verify dates
      assert DateTime.compare(renewed_contract.start_date, original_contract.end_date) == :eq
      assert DateTime.diff(renewed_contract.end_date, renewed_contract.start_date, :day) == 7
    end

    test "calculate_fee_data returns correct tier progression" do
      %{contract: contract} =
        setup_contract_test_data(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      fee_data = Contracts.calculate_fee_data(contract)

      assert Money.equal?(fee_data.total_paid, Money.zero(:USD))
      assert Decimal.equal?(fee_data.current_fee, Decimal.new("0.19"))
      assert fee_data.progress == Decimal.new("0.00")

      insert!(:transaction, %{
        contract_id: contract.id,
        type: :charge,
        status: :succeeded,
        net_amount: ~M[10000]usd
      })

      fee_data = Contracts.calculate_fee_data(contract)
      assert Money.equal?(fee_data.total_paid, ~M[10000]usd)
      assert Decimal.equal?(fee_data.current_fee, Decimal.new("0.10"))
      assert fee_data.progress > Decimal.new("0.00")
    end
  end
end
