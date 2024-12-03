defmodule Algora.Contracts do
  import Ecto.Changeset
  import Ecto.Query
  import Algora.Validators

  alias Algora.Repo
  alias Algora.Contracts.Contract
  alias Algora.FeeTier
  alias Algora.Contracts.Timesheet
  alias Algora.Payments.Transaction
  alias Algora.Payments
  alias Algora.Util
  alias Algora.MoneyUtils

  @type payment_status ::
          nil
          | {:paid, Timesheet.t(), Transaction.t()}
          | {:pending_release, Timesheet.t()}
          | {:reversed, Timesheet.t()}

  def get_contract(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Repo.one(from c in Contract, where: c.id == ^id, preload: ^preload)
  end

  def contract_chain_query(opts \\ []) do
    order_by = Keyword.get(opts, :order_by, desc: :start_date)
    preload = Keyword.get(opts, :preload, [])

    from(c in Contract, order_by: ^order_by, preload: ^preload)
  end

  def create_contract(attrs) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_payment_status(Contract.t()) :: payment_status()
  def get_payment_status(contract) do
    case {contract.timesheet, contract.latest_transfer, contract.latest_charge} do
      {nil, _, _} ->
        nil

      {timesheet, %Transaction{status: :succeeded} = transfer, _} ->
        {:paid, timesheet, transfer}

      {timesheet, _, %Transaction{status: :succeeded}} ->
        {:pending_release, timesheet}

      {timesheet, nil, nil} ->
        {:reversed, timesheet}
    end
  end

  def calculate_fee_data(contract) do
    total_paid = calculate_total_charged_to_client_net(contract)
    fee_tiers = FeeTier.all()
    current_fee = FeeTier.calculate_fee_percentage(total_paid)

    %{
      total_paid: total_paid,
      fee_tiers: fee_tiers,
      current_fee: current_fee,
      transaction_fee: Payments.get_transaction_fee_pct(),
      total_fee: Decimal.add(current_fee, Payments.get_transaction_fee_pct()),
      progress: FeeTier.calculate_progress(total_paid)
    }
  end

  def calculate_weekly_amount(contract) do
    Money.mult!(contract.hourly_rate, contract.hours_per_week)
  end

  def calculate_monthly_amount(contract) do
    contract
    |> calculate_weekly_amount()
    |> Money.mult!(4)
  end

  def list_contract_activity(contract) do
    contract
    |> Ecto.reset_fields([:chain])
    |> Repo.preload(chain: contract_chain_query(order_by: [asc: :start_date]))
    |> build_contract_timeline()
  end

  defp build_contract_timeline(contract) do
    contract.chain
    |> Enum.with_index()
    |> Enum.flat_map(&build_contract_period/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.date, {:desc, DateTime})
  end

  defp build_contract_period({contract, index}) do
    [
      build_initial_prepayment(contract),
      build_contract_renewal(contract, index),
      build_timesheet_submission(contract),
      build_payment_releases(contract)
    ]
    |> List.flatten()
  end

  defp build_initial_prepayment(contract) do
    contract.transactions
    |> Enum.filter(&(&1.type == :charge))
    |> Enum.map(
      &%{
        type: :prepayment,
        description: "Prepayment: #{Money.to_string!(&1.net_amount)}",
        date: &1.inserted_at,
        amount: &1.net_amount
      }
    )
  end

  defp build_contract_renewal(contract, index) do
    if index != 0 do
      %{
        type: :renewal,
        description: "Contract renewed for another period",
        date: contract.inserted_at,
        amount: nil
      }
    end
  end

  defp build_timesheet_submission(contract) do
    if contract.timesheet do
      %{
        type: :timesheet,
        description: "Timesheet submitted for #{contract.timesheet.hours_worked} hours",
        date: contract.timesheet.inserted_at,
        amount: calculate_transfer_amount(contract, contract.timesheet)
      }
    end
  end

  defp build_payment_releases(contract) do
    contract.transactions
    |> Enum.filter(&(&1.type == :transfer))
    |> Enum.sort_by(& &1.inserted_at)
    |> Enum.map(
      &%{
        type: :release,
        description: "Payment released: #{Money.to_string!(&1.net_amount)}",
        date: &1.inserted_at,
        amount: &1.net_amount
      }
    )
  end

  def get_timesheet(id), do: Repo.get(Timesheet, id)
  def get_timesheet!(id), do: Repo.get!(Timesheet, id)

  def initialize_charge(%{
        contract: contract,
        timesheet: timesheet,
        invoice: invoice,
        gross_amount: gross_amount,
        net_amount: net_amount,
        total_fee: total_fee,
        line_items: line_items
      }) do
    %Transaction{}
    |> change(%{
      provider: "stripe",
      provider_id: invoice.id,
      provider_meta: Util.normalize_struct(invoice),
      provider_invoice_id: invoice.id,
      type: :charge,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: timesheet.id,
      user_id: contract.client_id,
      gross_amount: gross_amount,
      net_amount: net_amount,
      total_fee: total_fee,
      line_items: line_items
    })
    |> validate_positive(:gross_amount)
    |> validate_positive(:net_amount)
    |> validate_positive(:total_fee)
    |> foreign_key_constraint(:original_contract_id)
    |> foreign_key_constraint(:contract_id)
    |> foreign_key_constraint(:timesheet_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  def initialize_transfer(%{
        contract: contract,
        timesheet: timesheet,
        invoice: invoice,
        transfer_amount: transfer_amount
      }) do
    %Transaction{}
    |> change(%{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: invoice.id,
      provider_meta: Util.normalize_struct(invoice),
      provider_invoice_id: invoice.id,
      gross_amount: transfer_amount,
      net_amount: transfer_amount,
      total_fee: Money.zero(:USD),
      type: :transfer,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: timesheet.id,
      user_id: contract.contractor_id
    })
    |> validate_positive(:gross_amount)
    |> validate_positive(:net_amount)
    |> foreign_key_constraint(:original_contract_id)
    |> foreign_key_constraint(:contract_id)
    |> foreign_key_constraint(:timesheet_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp initialize_transactions(contract, timesheet) do
    prepaid_amount = calculate_prepaid_balance(contract)
    fee_data = calculate_fee_data(contract)

    transfer_amount = calculate_transfer_amount(contract, timesheet)
    new_prepayment = Money.mult!(contract.hourly_rate, contract.hours_per_week)
    net_charge_amount = Money.sub!(Money.add!(transfer_amount, new_prepayment), prepaid_amount)
    platform_fee = Money.mult!(net_charge_amount, fee_data.current_fee)
    transaction_fee = Money.mult!(net_charge_amount, fee_data.transaction_fee)
    total_fee = Money.add!(platform_fee, transaction_fee)
    gross_charge_amount = Money.add!(net_charge_amount, total_fee)

    line_items = [
      %{
        amount: transfer_amount,
        description:
          "Payment for completed work - #{timesheet.hours_worked} hours @ #{Money.to_string!(contract.hourly_rate)}/hr"
      },
      %{
        amount: Money.negate!(prepaid_amount),
        description: "Less: Previously prepaid amount"
      },
      %{
        amount: new_prepayment,
        description:
          "Prepayment for upcoming period - #{contract.hours_per_week} hours @ #{Money.to_string!(contract.hourly_rate)}/hr"
      },
      %{
        amount: platform_fee,
        description: "Algora platform fee (#{Util.format_pct(fee_data.current_fee)})"
      },
      %{
        amount: transaction_fee,
        description: "Transaction fee (#{Util.format_pct(fee_data.transaction_fee)})"
      }
    ]

    Repo.transact(fn ->
      with {:ok, charge} <-
             initialize_charge(%{
               contract: contract,
               timesheet: timesheet,
               line_items: line_items,
               gross_amount: gross_charge_amount,
               net_amount: net_charge_amount,
               total_fee: total_fee
             }),
           {:ok, transfer} <-
             initialize_transfer(%{
               contract: contract,
               timesheet: timesheet,
               transfer_amount: transfer_amount
             }) do
        {:ok, {charge, transfer}}
      end
    end)
  end

  def release_and_renew(timesheet) do
    timesheet = timesheet |> Repo.preload(contract: [client: [customer: :default_payment_method]])
    contract = timesheet.contract

    with {:ok, {charge, _transfer}} <- initialize_transactions(contract, timesheet),
         {:ok, invoice} <- generate_invoice(contract, charge),
         {:ok, invoice} <- pay_invoice(contract, invoice, charge) do
      {:ok, invoice}
    end
  end

  defp generate_invoice(contract, charge) do
    with {:ok, invoice} <-
           Algora.Stripe.create_invoice(%{
             auto_advance: false,
             customer: contract.client.customer.provider_id
           }),
         {:ok, _line_items} <- create_line_items(contract, invoice, charge) do
      {:ok, invoice}
    end
  end

  defp create_line_items(contract, invoice, charge) do
    charge.line_items
    |> Enum.reduce_while({:ok, []}, fn line_item, {:ok, acc} ->
      case Algora.Stripe.create_invoice_item(%{
             invoice: invoice.id,
             customer: contract.client.customer.provider_id,
             amount: MoneyUtils.to_minor_units(line_item.amount),
             currency: to_string(line_item.amount.currency),
             description: line_item.description
           }) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp pay_invoice(contract, invoice, charge) do
    case Algora.Stripe.pay_invoice(
           invoice.id,
           %{
             off_session: true,
             payment_method: contract.client.customer.default_payment_method.provider_id
           }
         ) do
      {:ok, invoice} ->
        with {:ok, _charge} <- update_transaction_after_payment(charge, invoice),
             true <- invoice.paid,
             {:ok, contract} <- update_contract_status(contract, :paid),
             {:ok, _new_contract} <- renew_contract(contract) do
          {:ok, invoice}
        else
          _ -> {:ok, invoice}
        end

      {:error, error} ->
        charge
        |> change(%{status: :failed, provider_meta: %{error: error}})
        |> Repo.update()

        {:error, error}
    end
  end

  defp transfer_funds(%Transaction{type: :transfer} = transaction)
       when transaction.status != :succeeded do
    case Algora.Stripe.create_transfer(%{
           amount: MoneyUtils.to_minor_units(transaction.net_amount),
           currency: to_string(transaction.net_amount.currency),
           destination: transaction.user_id
         }) do
      {:ok, stripe_transfer} ->
        transaction
        |> change(%{provider_meta: Util.normalize_struct(stripe_transfer)})
        |> Repo.update()

      {:error, error} ->
        {:error, error}
    end
  end

  defp handle_charge_succeeded(contract) do
    with {:ok, contract} <- update_contract_status(contract, :paid) do
      {:ok, contract}
    end
  end

  defp update_transaction_after_payment(transaction, invoice) do
    transaction
    |> change(%{
      provider_meta: Util.normalize_struct(invoice),
      status: if(invoice.paid, do: :succeeded, else: :processing),
      succeeded_at: if(invoice.paid, do: DateTime.utc_now(), else: nil)
    })
    |> Repo.update()
  end

  defp update_contract_status(contract, status) do
    contract
    |> change(%{status: status})
    |> Repo.update()
  end

  defp renew_contract(contract) do
    Repo.insert(%Contract{
      id: Nanoid.generate(),
      contractor_id: contract.contractor_id,
      client_id: contract.client_id,
      status: :active,
      hourly_rate: contract.hourly_rate,
      hours_per_week: contract.hours_per_week,
      start_date: contract.end_date,
      end_date: contract.end_date |> DateTime.add(7, :day),
      sequence_number: contract.sequence_number + 1,
      original_contract_id: contract.original_contract_id,
      inserted_at: DateTime.utc_now()
    })
  end

  defp sum_transactions_query(contract, type, amount_field) do
    from(t in Transaction,
      join: c in Contract,
      on: c.original_contract_id == ^contract.original_contract_id,
      where: t.contract_id == c.id and t.type == ^type and t.status == :succeeded,
      select: sum(field(t, ^amount_field))
    )
    |> Repo.one()
    |> Kernel.||(Money.zero(:USD))
  end

  def calculate_total_transferred_to_contractor(contract) do
    sum_transactions_query(contract, :transfer, :net_amount)
  end

  def calculate_total_charged_to_client_gross(contract) do
    sum_transactions_query(contract, :charge, :gross_amount)
  end

  def calculate_total_charged_to_client_net(contract) do
    sum_transactions_query(contract, :charge, :net_amount)
  end

  # This represents money that has been charged to the client but not yet released to the contractor
  def calculate_prepaid_balance(contract) do
    total_charged = calculate_total_charged_to_client_net(contract)
    total_transferred = calculate_total_transferred_to_contractor(contract)
    Money.sub!(total_charged, total_transferred)
  end

  def calculate_transfer_amount(contract, timesheet) do
    Money.mult!(contract.hourly_rate, timesheet.hours_worked)
  end

  def prepay(contract) do
    # Calculate the initial prepayment amount
    prepayment_amount = Money.mult!(contract.hourly_rate, contract.hours_per_week)

    # Create a transaction for the prepayment
    transaction =
      Repo.insert!(%Transaction{
        id: Nanoid.generate(),
        contract_id: contract.id,
        original_contract_id: contract.original_contract_id,
        gross_amount: prepayment_amount,
        net_amount: prepayment_amount,
        total_fee: Money.zero(:USD),
        type: :charge,
        status: :succeeded,
        succeeded_at: DateTime.utc_now()
      })

    {:ok, transaction}
  end
end
