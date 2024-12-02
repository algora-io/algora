defmodule Algora.Contracts do
  import Ecto.Changeset
  import Ecto.Query

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
          | {:completed, Timesheet.t(), Transaction.t()}
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
        {:completed, timesheet, transfer}

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
    weekly = calculate_weekly_amount(contract)
    # Assuming 4.33 weeks per month on average
    Money.mult!(weekly, Decimal.new("4.33"))
  end

  def list_contract_activity(contract) do
    contract =
      contract
      |> Ecto.reset_fields([:chain])
      |> Repo.preload(chain: contract_chain_query(order_by: [asc: :start_date]))

    # Build timeline by processing each contract period sequentially
    contract.chain
    |> Enum.with_index()
    |> Enum.flat_map(fn {contract, index} ->
      [
        # 0. Initial prepayment
        contract.transactions
        |> Enum.filter(&(&1.type == :charge))
        |> Enum.map(fn transaction ->
          %{
            type: :prepayment,
            description: "Prepayment: #{Money.to_string!(transaction.net_amount)}",
            date: transaction.inserted_at,
            amount: transaction.net_amount
          }
        end),

        # 1. Contract start
        if(index != 0) do
          %{
            type: :renewal,
            description: "Contract renewed for another period",
            date: contract.inserted_at,
            amount: nil
          }
        end,

        # 2. Timesheet submissions
        if contract.timesheet do
          %{
            type: :timesheet,
            description: "Timesheet submitted for #{contract.timesheet.hours_worked} hours",
            date: contract.timesheet.inserted_at,
            amount: calculate_transfer_amount(contract, contract.timesheet)
          }
        end,

        # 3. Payment releases (transfers)
        contract.transactions
        |> Enum.filter(&(&1.type == :transfer))
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.map(fn transaction ->
          %{
            type: :release,
            description: "Payment released: #{Money.to_string!(transaction.net_amount)}",
            date: transaction.inserted_at,
            amount: transaction.net_amount
          }
        end)
      ]
      |> List.flatten()
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.date, {:desc, DateTime})
  end

  def get_timesheet(id), do: Repo.get(Timesheet, id)
  def get_timesheet!(id), do: Repo.get!(Timesheet, id)

  def release_and_renew(timesheet) do
    timesheet = timesheet |> Repo.preload(contract: [client: [customer: :default_payment_method]])

    contract = timesheet.contract
    prepaid_amount = calculate_prepaid_balance(contract)
    fee_data = calculate_fee_data(contract)

    # Calculate amount for completed work
    transfer_amount = calculate_transfer_amount(contract, timesheet)

    # Calculate new prepayment for next period
    new_prepayment = Money.mult!(contract.hourly_rate, contract.hours_per_week)

    # Net amount is completed work + new prepayment - previous prepayment
    net_amount = Money.add!(Money.sub!(transfer_amount, prepaid_amount), new_prepayment)

    # Calculate platform and processing fees
    platform_fee = Money.mult!(net_amount, fee_data.current_fee)
    transaction_fee = Money.mult!(net_amount, fee_data.transaction_fee)
    total_fee = Money.add!(platform_fee, transaction_fee)

    # Total amount including all fees
    gross_amount = Money.add!(net_amount, total_fee)

    {:ok, invoice} =
      Stripe.Invoice.create(%{
        auto_advance: false,
        customer: contract.client.customer.provider_id
      })

    dbg(invoice)

    line_items = [
      %{
        amount: transfer_amount,
        description:
          "Payment for completed work - #{timesheet.hours_worked} hours @ #{Money.to_string!(contract.hourly_rate)}/hr"
      },
      %{
        amount: -prepaid_amount,
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

    for line_item <- line_items do
      {:ok, _} =
        Stripe.Invoiceitem.create(%{
          invoice: invoice.id,
          customer: contract.client.customer.provider_id,
          amount: MoneyUtils.to_minor_units(line_item.amount),
          currency: to_string(line_item.currency),
          description: line_item.description
        })
    end

    transaction =
      Repo.insert!(%Transaction{
        id: Nanoid.generate(),
        gross_amount: gross_amount,
        net_amount: net_amount,
        total_fee: total_fee,
        provider: "stripe",
        provider_id: nil,
        provider_meta: nil,
        type: :charge,
        status: :initialized,
        succeeded_at: nil,
        contract_id: contract.id,
        original_contract_id: contract.original_contract_id
      })

    case Stripe.Invoice.pay(invoice.id, %{
           off_session: true,
           payment_method: contract.client.customer.default_payment_method.provider_id
         })
         |> dbg() do
      {:ok, pi} ->
        transaction
        |> change(%{
          provider_id: pi.id,
          provider_meta: Util.normalize_struct(pi),
          provider_fee: Payments.get_provider_fee(:stripe, pi),
          status: if(pi.status == "succeeded", do: :succeeded, else: :processing),
          succeeded_at: if(pi.status == "succeeded", do: DateTime.utc_now(), else: nil)
        })
        |> Repo.update!()

      {:error, error} ->
        transaction
        |> change(%{
          status: :failed,
          provider_meta: %{error: error}
        })
        |> Repo.update!()

        {:error, error}
    end
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
end
