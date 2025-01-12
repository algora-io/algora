defmodule Algora.ContractsTest do
  use Algora.DataCase

  import Algora.Factory
  import Money.Sigil

  alias Algora.Activities
  alias Algora.Contracts
  alias Algora.Payments
  alias Algora.Payments.Transaction

  def card_declined_error, do: %Stripe.Error{source: :stripe, code: :card_error, message: "Your card was declined."}

  # Mock implementation for Stripe API calls
  defmodule MockStripe do
    @moduledoc false
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
    @moduledoc false
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

  defp setup_contract(attrs) do
    client = insert!(:organization)
    contractor = insert!(:user)
    customer = insert!(:customer, %{user: client})
    _payment_method = insert!(:payment_method, %{customer: customer})
    contract = insert!(:contract, Map.merge(%{client: client, contractor: contractor}, attrs))

    {:ok, contract} = Contracts.fetch_contract(contract.id)
    contract
  end

  describe "contract payments" do
    test "initial prepayment calculates correct amounts" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      # Calculate expected amounts
      net_amount = ~M[4000]usd
      platform_fee = ~M[760]usd
      transaction_fee = ~M[160]usd
      total_fee = ~M[920]usd
      gross_amount = ~M[4920]usd

      # Initialize the prepayment transaction
      {:ok, %{charge: charge}} = Contracts.prepay_contract(contract)

      # Verify amounts
      assert Money.equal?(charge.net_amount, net_amount)
      assert Money.equal?(charge.gross_amount, gross_amount)
      assert Money.equal?(charge.total_fee, total_fee)

      # Verify line items
      [prepayment, platform_fee_item, transaction_fee_item] = charge.line_items

      assert Money.equal?(prepayment.amount, net_amount)
      assert prepayment.description =~ "40 hours @ $100/hr"

      assert Money.equal?(platform_fee_item.amount, platform_fee)
      assert platform_fee_item.description =~ "19%"

      assert Money.equal?(transaction_fee_item.amount, transaction_fee)
      assert transaction_fee_item.description =~ "4%"
    end

    test "fees decrease appropriately across multiple contract cycles" do
      contract0 = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 30})

      # Initial prepayment (19% fee tier)
      {:ok, txs0} = Contracts.prepay_contract(contract0)
      fee0 = Money.mult!(txs0.charge.net_amount, Decimal.new("0.23"))
      assert Money.equal?(txs0.charge.total_fee, fee0)
      assert Money.equal?(txs0.charge.gross_amount, ~M[3690]usd)
      assert Money.equal?(txs0.charge.net_amount, ~M[3000]usd)
      assert txs0["debit"] == nil
      assert txs0["credit"] == nil
      assert txs0["transfer"] == nil

      # Before first cycle
      total_paid = Payments.get_total_paid(contract0.client_id, contract0.contractor_id)
      assert Money.equal?(total_paid, ~M[0]usd)

      # First cycle (still 19% tier)
      insert!(:timesheet, %{contract_id: contract0.id, hours_worked: 30})
      {:ok, contract0} = Contracts.fetch_contract(contract0.id)
      {:ok, {txs1, contract1}} = Contracts.release_and_renew_contract(contract0)
      fee1 = Money.mult!(txs1.charge.net_amount, Decimal.new("0.23"))
      assert Money.equal?(txs1.charge.total_fee, fee1)
      assert Money.equal?(txs1.charge.gross_amount, ~M[3690]usd)
      assert Money.equal?(txs1.charge.net_amount, ~M[3000]usd)
      assert Money.equal?(txs1.debit.net_amount, ~M[3000]usd)
      assert Money.equal?(txs1.credit.net_amount, ~M[3000]usd)
      assert Money.equal?(txs1.transfer.net_amount, ~M[3000]usd)

      # After first cycle
      total_paid = Payments.get_total_paid(contract1.client_id, contract1.contractor_id)
      assert Money.equal?(total_paid, ~M[3000]usd)

      # Second cycle (drops to 15% tier)
      insert!(:timesheet, %{contract_id: contract1.id, hours_worked: 20})
      {:ok, contract1} = Contracts.fetch_contract(contract1.id)
      {:ok, {txs2, contract2}} = Contracts.release_and_renew_contract(contract1)

      fee2 = Money.mult!(txs2.charge.net_amount, Decimal.new("0.19"))
      assert Money.equal?(txs2.charge.total_fee, fee2)
      assert Money.equal?(txs2.charge.gross_amount, ~M[2380]usd)
      assert Money.equal?(txs2.charge.net_amount, ~M[2000]usd)
      assert Money.equal?(txs2.debit.net_amount, ~M[2000]usd)
      assert Money.equal?(txs2.credit.net_amount, ~M[2000]usd)
      assert Money.equal?(txs2.transfer.net_amount, ~M[2000]usd)

      # After second cycle
      total_paid = Payments.get_total_paid(contract2.client_id, contract2.contractor_id)
      assert Money.equal?(total_paid, ~M[5000]usd)

      # Third cycle (drops to 10% tier)
      insert!(:timesheet, %{contract_id: contract2.id, hours_worked: 40})
      {:ok, contract2} = Contracts.fetch_contract(contract2.id)
      {:ok, {txs3, contract3}} = Contracts.release_and_renew_contract(contract2)
      fee3 = Money.mult!(txs3.charge.net_amount, Decimal.new("0.14"))
      assert Money.equal?(txs3.charge.total_fee, fee3)
      assert Money.equal?(txs3.charge.gross_amount, ~M[4560]usd)
      assert Money.equal?(txs3.charge.net_amount, ~M[4000]usd)
      assert Money.equal?(txs3.debit.net_amount, ~M[4000]usd)
      assert Money.equal?(txs3.credit.net_amount, ~M[4000]usd)
      assert Money.equal?(txs3.transfer.net_amount, ~M[4000]usd)

      # After third cycle
      total_paid = Payments.get_total_paid(contract3.client_id, contract3.contractor_id)
      assert Money.equal?(total_paid, ~M[9000]usd)

      {:ok, contract3} = Contracts.fetch_contract(contract3.id)
      assert Money.equal?(contract3.total_charged, ~M[12_000]usd)
      assert Money.equal?(contract3.total_debited, ~M[9_000]usd)
      assert Money.equal?(contract3.total_credited, ~M[9_000]usd)
      assert Money.equal?(contract3.total_transferred, ~M[9_000]usd)
    end

    test "produces activities" do
      # Group a
      contract_a_0 = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 30})
      {:ok, _txs0} = Contracts.prepay_contract(contract_a_0)

      # First cycle
      insert!(:timesheet, %{contract_id: contract_a_0.id, hours_worked: 30})
      {:ok, contract_a_0} = Contracts.fetch_contract(contract_a_0.id)
      {:ok, {_txs1, contract_a_1}} = Contracts.release_and_renew_contract(contract_a_0)

      # Second cycle
      insert!(:timesheet, %{contract_id: contract_a_1.id, hours_worked: 20})
      {:ok, contract_a_1} = Contracts.fetch_contract(contract_a_1.id)
      {:ok, {_txs2, _contract_a_2}} = Contracts.release_and_renew_contract(contract_a_1)

      # Group b
      contract_b_0 = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 30})
      {:ok, _txs0} = Contracts.prepay_contract(contract_b_0)

      # First cycle
      insert!(:timesheet, %{contract_id: contract_b_0.id, hours_worked: 30})
      {:ok, contract_b_0} = Contracts.fetch_contract(contract_b_0.id)
      {:ok, {_txs1, contract_b_1}} = Contracts.release_and_renew_contract(contract_b_0)

      # Second cycle
      insert!(:timesheet, %{contract_id: contract_b_1.id, hours_worked: 20})
      {:ok, contract_b_1} = Contracts.fetch_contract(contract_b_1.id)
      {:ok, {_txs2, _contract_b_2}} = Contracts.release_and_renew_contract(contract_b_1)

      activities_per_contract = [
        :transaction_created,
        :transaction_created,
        :transaction_created,
        :transaction_created,
        :transaction_status_change,
        :transaction_status_change,
        :transaction_status_change,
        :contract_paid
      ]

      activities_per_cycle =
        activities_per_contract ++
          [
            :contract_renewed
          ]

      activities_per_group =
        [
          :transaction_created,
          :contract_prepaid
        ] ++
          activities_per_cycle ++
          activities_per_cycle

      assert_activity_names(
        contract_a_0,
        [
          :transaction_created,
          :contract_prepaid
        ] ++ activities_per_contract
      )

      assert_activity_names(
        contract_a_1,
        [
          :contract_renewed
        ] ++ activities_per_contract
      )

      assert_activity_names(
        "contract_activities",
        activities_per_group ++ activities_per_group
      )

      assert_activity_names_for_user(
        contract_a_0.contractor_id,
        activities_per_group
      )

      assert_activity_names_for_user(
        contract_b_0.contractor_id,
        activities_per_group
      )

      assert Activities.all_for_user(contract_a_0.client_id) !=
               Activities.all_for_user(contract_b_0.client_id)

      assert Activities.all_for_user(contract_a_0.contractor_id) !=
               Activities.all_for_user(contract_b_0.contractor_id)
    end

    test "prepayment fails when payment method is invalid" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      payment_error = card_declined_error()

      Application.put_env(:algora, :stripe_impl, MockStripeWithFailure)

      {:error, ^payment_error} = Contracts.prepay_contract(contract)

      # Verify charge was marked as failed
      charge = Repo.one(from t in Transaction, where: t.contract_id == ^contract.id)
      assert charge.status == :failed

      assert %{"error" => %{"code" => "card_error", "message" => "Your card was declined."}} =
               charge.provider_meta
    end

    test "release payment handles exact prepayment hours correctly" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 20})

      # Initial prepayment for 20 hours
      {:ok, _charge} = Contracts.prepay_contract(contract)

      # Submit timesheet for exactly 20 hours (matching prepaid amount)
      insert!(:timesheet, %{contract_id: contract.id, hours_worked: 20})

      {:ok, contract} = Contracts.fetch_contract(contract.id)
      {:ok, txs} = Contracts.release_contract(contract)

      # Verify amounts
      # No additional charge needed
      assert txs.charge == nil
      # Full 20 hours payment
      assert Money.equal?(txs.debit.net_amount, ~M[2000]usd)
      assert Money.equal?(txs.credit.net_amount, ~M[2000]usd)
      assert Money.equal?(txs.transfer.net_amount, ~M[2000]usd)
    end

    test "release payment handles undertime correctly" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 20})

      # Initial prepayment for 20 hours
      {:ok, _charge} = Contracts.prepay_contract(contract)

      # Submit timesheet for 15 hours (5 less than prepaid)
      insert!(:timesheet, %{contract_id: contract.id, hours_worked: 15})
      {:ok, contract} = Contracts.fetch_contract(contract.id)
      {:ok, txs} = Contracts.release_contract(contract)

      # Verify amounts
      # No additional charge needed
      assert txs.charge == nil
      # Only pay for hours worked
      assert Money.equal?(txs.debit.net_amount, ~M[1500]usd)
      assert Money.equal?(txs.credit.net_amount, ~M[1500]usd)
      assert Money.equal?(txs.transfer.net_amount, ~M[1500]usd)
    end

    test "release payment handles overtime correctly" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 20})

      # Initial prepayment for 20 hours
      {:ok, _charge} = Contracts.prepay_contract(contract)

      # Submit timesheet for 30 hours (10 more than prepaid)
      insert!(:timesheet, %{contract_id: contract.id, hours_worked: 30})
      {:ok, contract} = Contracts.fetch_contract(contract.id)
      {:ok, txs} = Contracts.release_contract(contract)

      # Verify amounts
      # Additional 10 hours @ $100
      assert Money.equal?(txs.charge.net_amount, ~M[1000]usd)
      # Full 30 hours payment
      assert Money.equal?(txs.debit.net_amount, ~M[3000]usd)
      assert Money.equal?(txs.credit.net_amount, ~M[3000]usd)
      assert Money.equal?(txs.transfer.net_amount, ~M[3000]usd)
    end

    test "contract renewal maintains correct chain relationship" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      insert!(:timesheet, %{contract_id: contract.id, hours_worked: 40})

      {:ok, contract} = Contracts.fetch_contract(contract.id)
      {:ok, {_txs, new_contract}} = Contracts.release_and_renew_contract(contract)

      # Verify chain relationships
      assert new_contract.original_contract_id == contract.id
      assert new_contract.sequence_number == 2

      # Verify dates
      assert DateTime.compare(new_contract.start_date, contract.end_date) == :eq
      assert DateTime.diff(new_contract.end_date, new_contract.start_date, :day) == 7
    end

    test "calculate_fee_data returns correct tier progression" do
      contract = setup_contract(%{hourly_rate: ~M[100]usd, hours_per_week: 40})

      fee_data = Contracts.calculate_fee_data(contract)

      assert Money.equal?(fee_data.total_paid, Money.zero(:USD))
      assert Decimal.equal?(fee_data.current_fee, Decimal.new("0.19"))
      assert fee_data.progress == Decimal.new("0.00")

      Repo.transact(fn ->
        debit_id = Nanoid.generate()
        credit_id = Nanoid.generate()

        insert!(
          :transaction,
          %{
            id: debit_id,
            linked_transaction_id: credit_id,
            type: :debit,
            status: :succeeded,
            net_amount: ~M[10000]usd,
            user_id: contract.client_id
          }
        )

        insert!(
          :transaction,
          %{
            id: credit_id,
            linked_transaction_id: debit_id,
            type: :credit,
            status: :succeeded,
            net_amount: ~M[10000]usd,
            user_id: contract.contractor_id
          }
        )

        {:ok, :ok}
      end)

      {:ok, contract} = Contracts.fetch_contract(contract.id)
      fee_data = Contracts.calculate_fee_data(contract)
      assert Money.equal?(fee_data.total_paid, ~M[10000]usd)
      assert Decimal.equal?(fee_data.current_fee, Decimal.new("0.10"))
      assert Decimal.positive?(fee_data.progress)
    end
  end
end
