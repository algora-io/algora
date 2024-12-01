defmodule Algora.Contracts do
  alias Algora.Repo
  alias Algora.Contracts.Contract
  alias Algora.FeeTier

  @transaction_fee Decimal.new("0.04")

  @type payment_status ::
          nil
          | {:completed, Timesheet.t(), Transaction.t()}
          | {:pending_release, Timesheet.t()}
          | {:reversed, Timesheet.t()}

  def get_contract!(id), do: Repo.get!(Contract, id)

  def create_contract(attrs) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  def get_contract_chain(contract) do
    case contract.original_contract_id do
      nil -> [contract | contract.renewals]
      _ -> [contract.original_contract | contract.original_contract.renewals]
    end
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.start_date, {:desc, DateTime})
  end

  @spec get_payment_status(Contract.t()) :: payment_status()

  def get_payment_status(contract) do
    case {get_latest_timesheet(contract), get_latest_transaction(contract)} do
      {nil, _} ->
        nil

      {timesheet, transaction} ->
        cond do
          transaction.type == :transfer -> {:completed, timesheet, transaction}
          transaction.type == :charge -> {:pending_release, timesheet}
          transaction.type == :reversal -> {:reversed, timesheet}
        end
    end
  end

  def get_latest_timesheet(contract) do
    contract.timesheets
    |> Enum.sort_by(& &1.end_date, {:desc, DateTime})
    |> List.first()
  end

  def get_latest_transaction(contract) do
    contract.transactions
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> List.first()
  end

  def calculate_amount(contract, timesheet) do
    Money.mult!(contract.hourly_rate, timesheet.hours_worked)
  end

  def calculate_total_paid(contract_chain) do
    contract_chain
    |> Enum.flat_map(& &1.transactions)
    |> Enum.filter(&(&1.type == :transfer))
    |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))
  end

  def calculate_total_charged(contract_chain) do
    contract_chain
    |> Enum.flat_map(& &1.transactions)
    |> Enum.filter(&(&1.type == :charge))
    |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))
  end

  def calculate_escrow_amount(contract_chain) do
    total_charged = calculate_total_charged(contract_chain)
    total_paid = calculate_total_paid(contract_chain)
    Money.sub!(total_charged, total_paid)
  end

  def calculate_fee_data(contract_chain) do
    total_paid =
      contract_chain
      |> Enum.flat_map(& &1.transactions)
      |> Enum.filter(&(&1.type == :transfer))
      |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))

    fee_tiers = FeeTier.all()
    current_fee = FeeTier.calculate_fee_percentage(total_paid)

    %{
      total_paid: total_paid,
      fee_tiers: fee_tiers,
      current_fee: current_fee,
      transaction_fee: @transaction_fee,
      total_fee: Decimal.add(current_fee, @transaction_fee),
      progress: FeeTier.calculate_progress(total_paid)
    }
  end

  def get_latest_charge(contract) do
    contract.transactions
    |> Enum.filter(&(&1.type == :charge))
    |> Enum.sort_by(& &1.inserted_at, :desc)
    |> List.first()
  end

  def get_latest_transfer(contract) do
    contract.transactions
    |> Enum.filter(&(&1.type == :transfer))
    |> Enum.sort_by(& &1.inserted_at, :desc)
    |> List.first()
  end

  def calculate_weekly_amount(contract) do
    Money.mult!(contract.hourly_rate, contract.hours_per_week)
  end

  def calculate_monthly_amount(contract) do
    weekly = calculate_weekly_amount(contract)
    # Assuming 4.33 weeks per month on average
    Money.mult!(weekly, Decimal.new("4.33"))
  end

  def get_contract_activity(contract) do
    # Get all contracts in the chain ordered by start date (oldest first)
    contracts =
      get_contract_chain(contract)
      |> Enum.sort_by(& &1.start_date, :asc)

    # Build timeline by processing each contract period sequentially
    contracts
    |> Enum.with_index()
    |> Enum.flat_map(fn {contract, index} ->
      [
        # 0. Initial escrow charge
        contract.transactions
        |> Enum.filter(&(&1.type == :charge))
        |> Enum.map(fn transaction ->
          %{
            type: :escrow,
            description: "Payment escrowed: #{Money.to_string!(transaction.amount)}",
            date: transaction.inserted_at,
            amount: transaction.amount
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
        contract.timesheets
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.map(fn timesheet ->
          %{
            type: :timesheet,
            description: "Timesheet submitted for #{timesheet.hours_worked} hours",
            date: timesheet.inserted_at,
            amount: calculate_amount(contract, timesheet)
          }
        end),

        # 3. Payment releases (transfers)
        contract.transactions
        |> Enum.filter(&(&1.type == :transfer))
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.map(fn transaction ->
          %{
            type: :release,
            description: "Payment released: #{Money.to_string!(transaction.amount)}",
            date: transaction.inserted_at,
            amount: transaction.amount
          }
        end)
      ]
      |> List.flatten()
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.date, {:desc, DateTime})
  end
end
