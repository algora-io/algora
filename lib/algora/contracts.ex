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
  alias Algora.Stripe
  alias Algora.MoneyUtils

  @type payment_status ::
          {:paid, Contract.t()}
          | {:pending_release, Contract.t()}
          | {:pending_payment, Contract.t()}
          | {:pending_timesheet, Contract.t()}

  def create_contract(attrs) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_payment_status(Contract.t()) :: payment_status()
  def get_payment_status(contract) do
    zero = Money.zero(:USD)

    case {contract.timesheet, contract.amount_credited} do
      {nil, _} -> {:pending_timesheet, contract}
      {_, ^zero} -> {:pending_release, contract}
      {_, _} -> {:paid, contract}
    end
  end

  def calculate_fee_data(contract) do
    total_paid = contract.total_charged
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

  def build_contract_timeline(contract_chain) do
    contract_chain
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
        amount: calculate_transfer_amount(contract)
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

  defp initialize_charge(%{
         contract: contract,
         gross_amount: gross_amount,
         net_amount: net_amount,
         total_fee: total_fee,
         line_items: line_items
       }) do
    %Transaction{}
    |> change(%{
      id: Nanoid.generate(),
      provider: "stripe",
      type: :charge,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: contract.timesheet && contract.timesheet.id,
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

  defp initialize_debit(%{contract: contract, amount: amount}) do
    %Transaction{}
    |> change(%{
      id: Nanoid.generate(),
      provider: "stripe",
      type: :debit,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: contract.timesheet.id,
      user_id: contract.client_id,
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD)
    })
    |> validate_positive(:gross_amount)
    |> validate_positive(:net_amount)
    |> foreign_key_constraint(:original_contract_id)
    |> foreign_key_constraint(:contract_id)
    |> foreign_key_constraint(:timesheet_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp initialize_credit(%{contract: contract, amount: amount}) do
    %Transaction{}
    |> change(%{
      id: Nanoid.generate(),
      provider: "stripe",
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      type: :credit,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: contract.timesheet.id,
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

  defp initialize_transfer(%{contract: contract, amount: amount}) do
    %Transaction{}
    |> change(%{
      id: Nanoid.generate(),
      provider: "stripe",
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      type: :transfer,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: contract.timesheet.id,
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

  defp initialize_prepayment_transaction(contract) do
    fee_data = calculate_fee_data(contract)

    net_charge_amount = Money.mult!(contract.hourly_rate, contract.hours_per_week)
    platform_fee = Money.mult!(net_charge_amount, fee_data.current_fee)
    transaction_fee = Money.mult!(net_charge_amount, fee_data.transaction_fee)
    total_fee = Money.add!(platform_fee, transaction_fee)
    gross_charge_amount = Money.add!(net_charge_amount, total_fee)

    line_items = [
      %{
        amount: net_charge_amount,
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

    with {:ok, charge} <-
           initialize_charge(%{
             contract: contract,
             line_items: line_items,
             gross_amount: gross_charge_amount,
             net_amount: net_charge_amount,
             total_fee: total_fee
           }) do
      {:ok, %{charge: charge}}
    end
  end

  defp initialize_release_transactions(contract) do
    balance = Contract.balance(contract)
    fee_data = calculate_fee_data(contract)

    transfer_amount = calculate_transfer_amount(contract)
    new_prepayment = Money.mult!(contract.hourly_rate, contract.hours_per_week)
    net_charge_amount = Money.sub!(Money.add!(transfer_amount, new_prepayment), balance)
    platform_fee = Money.mult!(net_charge_amount, fee_data.current_fee)
    transaction_fee = Money.mult!(net_charge_amount, fee_data.transaction_fee)
    total_fee = Money.add!(platform_fee, transaction_fee)
    gross_charge_amount = Money.add!(net_charge_amount, total_fee)

    line_items = [
      %{
        amount: transfer_amount,
        description:
          "Payment for completed work - #{contract.timesheet.hours_worked} hours @ #{Money.to_string!(contract.hourly_rate)}/hr"
      },
      %{
        amount: Money.negate!(balance),
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
               line_items: line_items,
               gross_amount: gross_charge_amount,
               net_amount: net_charge_amount,
               total_fee: total_fee
             }),
           {:ok, debit} <- initialize_debit(%{contract: contract, amount: transfer_amount}),
           {:ok, credit} <- initialize_credit(%{contract: contract, amount: transfer_amount}),
           {:ok, transfer} <- initialize_transfer(%{contract: contract, amount: transfer_amount}) do
        {:ok, %{charge: charge, debit: debit, credit: credit, transfer: transfer}}
      end
    end)
  end

  def release_contract(contract) do
    with {:ok, txs} <- initialize_release_transactions(contract),
         {:ok, invoice} <- generate_invoice(contract, txs.charge.line_items),
         {:ok, _invoice} <- pay_invoice(contract, invoice, txs) do
      {:ok, txs}
    end
  end

  def release_and_renew_contract(contract) do
    with {:ok, txs} <- release_contract(contract),
         {:ok, new_contract} <- renew_contract(contract) do
      {:ok, {txs, new_contract}}
    end
  end

  def prepay_contract(contract) do
    with {:ok, txs} <- initialize_prepayment_transaction(contract),
         {:ok, invoice} <- generate_invoice(contract, txs.charge.line_items),
         {:ok, _invoice} <- pay_invoice(contract, invoice, txs) do
      {:ok, txs}
    end
  end

  defp generate_invoice(contract, line_items) do
    invoice_params = %{auto_advance: false, customer: contract.client.customer.provider_id}

    with {:ok, invoice} <- Stripe.create_invoice(invoice_params),
         {:ok, _line_items} <- create_line_items(contract, invoice, line_items) do
      {:ok, invoice}
    end
  end

  defp create_line_items(contract, invoice, line_items) do
    line_items
    |> Enum.reduce_while({:ok, []}, fn line_item, {:ok, acc} ->
      case Stripe.create_invoice_item(%{
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

  defp pay_invoice(contract, invoice, txs) do
    pm_id = contract.client.customer.default_payment_method.provider_id

    case Stripe.pay_invoice(invoice.id, %{off_session: true, payment_method: pm_id}) do
      {:ok, stripe_invoice} ->
        status = if stripe_invoice.paid, do: :succeeded, else: :processing

        # TODO: do we need to lock the transactions here?
        Repo.transact(fn ->
          update_transaction_status(txs.charge, stripe_invoice, status)
          if txs["debit"], do: update_transaction_status(txs.debit, stripe_invoice, status)
          if txs["credit"], do: update_transaction_status(txs.credit, stripe_invoice, status)
          {:ok, %{}}
        end)

        if txs["transfer"], do: transfer_funds(contract, txs.transfer)

        {:ok, stripe_invoice}

      {:error, error} ->
        update_transaction_status(txs.charge, %{error: error}, :failed)
        {:error, error}
    end
  end

  defp transfer_funds(contract, %Transaction{type: :transfer} = transaction)
       when transaction.status != :succeeded do
    case Stripe.create_transfer(%{
           amount: MoneyUtils.to_minor_units(transaction.net_amount),
           currency: to_string(transaction.net_amount.currency),
           destination: transaction.user_id
         }) do
      {:ok, stripe_transfer} ->
        update_transaction_status(transaction, stripe_transfer, :succeeded)
        mark_contract_as_paid(contract)
        {:ok, stripe_transfer}

      {:error, error} ->
        update_transaction_status(transaction, %{error: error}, :failed)
        {:error, error}
    end
  end

  defp update_transaction_status(transaction, %{error: error}, :failed) do
    transaction
    |> change(%{
      provider_meta: Util.normalize_struct(%{error: error}),
      status: :failed
    })
    |> Repo.update()
  end

  defp update_transaction_status(transaction, record, status) do
    transaction
    |> change(%{
      provider_id: record.id,
      provider_meta: Util.normalize_struct(record),
      status: status,
      succeeded_at: if(status == :succeeded, do: DateTime.utc_now(), else: nil)
    })
    |> Repo.update()
  end

  defp mark_contract_as_paid(contract) do
    contract
    |> change(%{status: :paid})
    |> Repo.update()
  end

  defp renew_contract(contract) do
    %Contract{}
    |> change(%{
      id: Nanoid.generate(),
      status: :active,
      start_date: contract.end_date,
      end_date: contract.end_date |> DateTime.add(7, :day),
      sequence_number: contract.sequence_number + 1,
      original_contract_id: contract.original_contract_id,
      client_id: contract.client_id,
      contractor_id: contract.contractor_id,
      hourly_rate: contract.hourly_rate,
      hours_per_week: contract.hours_per_week
    })
    |> Repo.insert()
  end

  def calculate_transfer_amount(contract) do
    Money.mult!(contract.hourly_rate, contract.timesheet.hours_worked)
  end

  defmacrop sum_by_type(t, type) do
    quote do
      sum(
        fragment(
          "CASE WHEN ? = ? THEN ? ELSE ('USD', 0)::money_with_currency END",
          unquote(t).type,
          unquote(type),
          unquote(t).net_amount
        )
      )
    end
  end

  defmacrop coalesce0(t) do
    quote do
      coalesce(unquote(t), fragment("('USD', 0)::money_with_currency"))
    end
  end

  def fetch_contract!(id) do
    {:ok, contract} = fetch_contract(id)
    contract
  end

  def fetch_contract(id) do
    case list_contract_chain(id: id, limit: 1) do
      [contract] -> {:ok, contract}
      _ -> {:error, :not_found}
    end
  end

  def fetch_last_contract!(id) do
    {:ok, contract} = fetch_last_contract(id)
    contract
  end

  def fetch_last_contract(id) do
    case list_contract_chain(original_contract_id: id, limit: 1, order: :desc) do
      [contract] -> {:ok, contract}
      _ -> {:error, :not_found}
    end
  end

  def list_contract_chain(criteria \\ []) do
    criteria = Keyword.merge([order: :desc, limit: 50], criteria)

    transaction_amounts =
      Transaction
      |> maybe_filter_txs_by_contract_id(criteria)
      |> maybe_filter_txs_by_original_contract_id(criteria)
      |> group_by([t], t.contract_id)
      |> select([t], %{
        contract_id: t.contract_id,
        amount_credited: sum_by_type(t, "credit"),
        amount_debited: sum_by_type(t, "debit")
      })

    transaction_totals =
      Transaction
      |> maybe_filter_txs_by_contract_id(criteria)
      |> maybe_filter_txs_by_original_contract_id(criteria)
      |> group_by([t], t.original_contract_id)
      |> select([t], %{
        original_contract_id: t.original_contract_id,
        total_charged: sum_by_type(t, "charge"),
        total_credited: sum_by_type(t, "credit"),
        total_debited: sum_by_type(t, "debit"),
        total_deposited: sum_by_type(t, "deposit"),
        total_transferred: sum_by_type(t, "transfer"),
        total_withdrawn: sum_by_type(t, "withdrawal")
      })

    base_contracts = Contract |> apply_criteria(criteria) |> select([c], c.id)

    from(c in Contract)
    |> join(:inner, [c], bc in subquery(base_contracts), on: c.id == bc.id)
    |> join(:inner, [c], client in assoc(c, :client), as: :cl)
    |> join(:inner, [c], contractor in assoc(c, :contractor), as: :ct)
    |> join(:left, [c], timesheet in assoc(c, :timesheet), as: :ts)
    |> join(:left, [c], transactions in assoc(c, :transactions), as: :txs)
    |> join(:left, [c], amounts in subquery(transaction_amounts),
      on: amounts.contract_id == c.id,
      as: :ta
    )
    |> join(:left, [c], totals in subquery(transaction_totals),
      on: totals.original_contract_id == c.original_contract_id,
      as: :tt
    )
    |> select_merge([ta: ta, tt: tt], %{
      amount_credited: coalesce0(ta.amount_credited),
      amount_debited: coalesce0(ta.amount_debited),
      total_charged: coalesce0(tt.total_charged),
      total_credited: coalesce0(tt.total_credited),
      total_debited: coalesce0(tt.total_debited),
      total_deposited: coalesce0(tt.total_deposited),
      total_transferred: coalesce0(tt.total_transferred),
      total_withdrawn: coalesce0(tt.total_withdrawn)
    })
    |> preload([ts: ts, txs: txs, cl: cl, ct: ct],
      timesheet: ts,
      transactions: txs,
      client: cl,
      contractor: ct
    )
    |> Repo.all()
    |> Enum.map(&Contract.after_load/1)
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:id, id}, query ->
        from([c] in query, where: c.id == ^id)

      {:original_contract_id, original_contract_id}, query ->
        from([c] in query, where: c.original_contract_id == ^original_contract_id)

      {:after, sequence_number}, query ->
        from([c] in query, where: c.sequence_number > ^sequence_number)

      {:before, sequence_number}, query ->
        from([c] in query, where: c.sequence_number < ^sequence_number)

      {:order, :asc}, query ->
        from([c] in query, order_by: [asc: c.sequence_number])

      {:order, :desc}, query ->
        from([c] in query, order_by: [desc: c.sequence_number])

      {:limit, limit}, query ->
        from([c] in query, limit: ^limit)

      _, query ->
        query
    end)
  end

  defp maybe_filter_txs_by_contract_id(query, criteria) do
    case Keyword.get(criteria, :id) do
      nil -> query
      id -> from([t] in query, where: t.contract_id == ^id)
    end
  end

  defp maybe_filter_txs_by_original_contract_id(query, criteria) do
    case Keyword.get(criteria, :original_contract_id) do
      nil -> query
      id -> from([t] in query, where: t.original_contract_id == ^id)
    end
  end
end
