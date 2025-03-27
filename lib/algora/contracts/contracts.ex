defmodule Algora.Contracts do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Activities
  alias Algora.Contracts.Contract
  alias Algora.Contracts.Timesheet
  alias Algora.FeeTier
  alias Algora.MoneyUtils
  alias Algora.Payments
  alias Algora.Payments.Account
  alias Algora.Payments.Transaction
  alias Algora.PSP.Invoice
  alias Algora.Repo
  alias Algora.Util

  require Algora.SQL

  @type payment_status ::
          {:paid, Contract.t()}
          | {:pending_release, Contract.t()}
          | {:pending_payment, Contract.t()}
          | {:pending_timesheet, Contract.t()}

  @type criterion ::
          {:id, binary()}
          | {:client_id, binary()}
          | {:contractor_id, binary()}
          | {:original_contract_id, binary()}
          | {:open?, true}
          | {:active_or_paid?, true}
          | {:original?, true}
          | {:status, Contract.status() | {:in, [Contract.status()]}}
          | {:after, non_neg_integer()}
          | {:before, non_neg_integer()}
          | {:order, :asc | :desc}
          | {:limit, non_neg_integer()}
          | {:tech_stack, [String.t()]}

  def create_contract(attrs) do
    case %Contract{} |> Contract.changeset(attrs) |> Repo.insert() do
      {:ok, contract} ->
        Algora.Admin.alert("Contract created: #{contract.id}", :info)
        {:ok, contract}

      {:error, error} ->
        Algora.Admin.alert("Error creating contract: #{inspect(error)}", :error)
        {:error, error}
    end
  end

  @spec get_payment_status(Contract.t()) :: payment_status()
  def get_payment_status(contract) do
    cond do
      is_nil(contract.timesheet) -> {:pending_timesheet, contract}
      Money.positive?(contract.amount_credited) -> {:paid, contract}
      true -> {:pending_release, contract}
    end
  end

  def calculate_fee_data(contract) do
    total_paid = Payments.get_total_paid(contract.client_id, contract.contractor_id)
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
    List.flatten([
      build_initial_prepayment(contract),
      build_contract_renewal(contract, index),
      build_timesheet_submission(contract),
      build_payment_releases(contract)
    ])
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

  defp maybe_initialize_charge(%{line_items: []}), do: {:ok, nil}

  defp maybe_initialize_charge(%{
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
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> Algora.Validations.validate_positive(:total_fee)
    |> foreign_key_constraint(:original_contract_id)
    |> foreign_key_constraint(:contract_id)
    |> foreign_key_constraint(:timesheet_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp initialize_debit(%{id: id, contract: contract, amount: amount, linked_transaction_id: linked_transaction_id}) do
    %Transaction{}
    |> change(%{
      id: id,
      provider: "stripe",
      type: :debit,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: contract.timesheet.id,
      user_id: contract.client_id,
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      linked_transaction_id: linked_transaction_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:original_contract_id)
    |> foreign_key_constraint(:contract_id)
    |> foreign_key_constraint(:timesheet_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp initialize_credit(%{id: id, contract: contract, amount: amount, linked_transaction_id: linked_transaction_id}) do
    %Transaction{}
    |> change(%{
      id: id,
      provider: "stripe",
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      type: :credit,
      status: :initialized,
      contract_id: contract.id,
      original_contract_id: contract.original_contract_id,
      timesheet_id: contract.timesheet.id,
      user_id: contract.contractor_id,
      linked_transaction_id: linked_transaction_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
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
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
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
           maybe_initialize_charge(%{
             contract: contract,
             line_items: line_items,
             gross_amount: gross_charge_amount,
             net_amount: net_charge_amount,
             total_fee: total_fee
           }) do
      {:ok, %{charge: charge}}
    end
  end

  defp initialize_release_transactions(contract, renew) do
    balance = Contract.balance(contract)
    fee_data = calculate_fee_data(contract)

    transfer_amount = calculate_transfer_amount(contract)

    new_prepayment =
      if renew,
        do: Money.mult!(contract.hourly_rate, contract.hours_per_week),
        else: Money.zero(:USD)

    net_charge_amount = Money.sub!(Money.add!(transfer_amount, new_prepayment), balance)
    platform_fee = Money.mult!(net_charge_amount, fee_data.current_fee)
    transaction_fee = Money.mult!(net_charge_amount, fee_data.transaction_fee)
    total_fee = Money.add!(platform_fee, transaction_fee)
    gross_charge_amount = Money.add!(net_charge_amount, total_fee)

    line_items =
      if Money.positive?(net_charge_amount) do
        [
          build_transfer_line_item(contract, transfer_amount),
          build_balance_line_item(balance),
          build_prepayment_line_item(contract, new_prepayment),
          build_platform_fee_line_item(platform_fee, fee_data),
          build_transaction_fee_line_item(transaction_fee, fee_data)
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.reject(&Money.zero?(&1.amount))
      else
        []
      end

    debit_id = Nanoid.generate()
    credit_id = Nanoid.generate()

    charge_params = %{
      contract: contract,
      line_items: line_items,
      gross_amount: gross_charge_amount,
      net_amount: net_charge_amount,
      total_fee: total_fee
    }

    debit_params = %{
      id: debit_id,
      linked_transaction_id: credit_id,
      contract: contract,
      amount: transfer_amount
    }

    credit_params = %{
      id: credit_id,
      linked_transaction_id: debit_id,
      contract: contract,
      amount: transfer_amount
    }

    Repo.transact(fn ->
      with {:ok, charge} <- maybe_initialize_charge(charge_params),
           {:ok, debit} <- initialize_debit(debit_params),
           {:ok, credit} <- initialize_credit(credit_params),
           {:ok, transfer} <- initialize_transfer(%{contract: contract, amount: transfer_amount}) do
        {:ok, %{charge: charge, debit: debit, credit: credit, transfer: transfer}}
      end
    end)
  end

  def release_contract(contract, renew \\ false) do
    with {:ok, txs} <- initialize_release_transactions(contract, renew),
         {:ok, invoice} <- maybe_generate_invoice(contract, txs.charge),
         {:ok, _invoice} <- maybe_pay_invoice(contract, invoice, txs) do
      {:ok, txs}
    end
  end

  def release_and_renew_contract(contract) do
    with {:ok, txs} <- release_contract(contract, true),
         {:ok, new_contract} <- renew_contract(contract) do
      {:ok, {txs, new_contract}}
    end
  end

  def prepay_contract(contract) do
    with {:ok, txs} <- initialize_prepayment_transaction(contract),
         {:ok, invoice} <- maybe_generate_invoice(contract, txs.charge),
         {:ok, _invoice} <- maybe_pay_invoice(contract, invoice, txs) do
      Activities.insert(contract, %{type: :contract_prepaid})

      {:ok, txs}
    else
      error ->
        Activities.insert(contract, %{
          type: :contract_prepayment_failed
        })

        error
    end
  end

  defp maybe_generate_invoice(_contract, nil), do: {:ok, nil}

  defp maybe_generate_invoice(contract, charge) do
    invoice_params = %{auto_advance: false, customer: contract.client.customer.provider_id}

    with {:ok, invoice} <- Invoice.create(invoice_params, %{idempotency_key: "contract-#{contract.id}"}),
         {:ok, _line_items} <- create_line_items(contract, invoice, charge.line_items) do
      {:ok, invoice}
    end
  end

  defp build_transfer_line_item(contract, amount) do
    %{
      amount: amount,
      description:
        "Payment for completed work - #{contract.timesheet.hours_worked} hours @ #{Money.to_string!(contract.hourly_rate)}/hr"
    }
  end

  defp build_balance_line_item(balance) do
    %{
      amount: Money.negate!(balance),
      description: "Less: Previously prepaid amount"
    }
  end

  defp build_prepayment_line_item(contract, amount) do
    if Money.positive?(amount) do
      %{
        amount: amount,
        description:
          "Prepayment for upcoming period - #{contract.hours_per_week} hours @ #{Money.to_string!(contract.hourly_rate)}/hr"
      }
    end
  end

  defp build_platform_fee_line_item(fee, fee_data) do
    %{
      amount: fee,
      description: "Algora platform fee (#{Util.format_pct(fee_data.current_fee)})"
    }
  end

  defp build_transaction_fee_line_item(fee, fee_data) do
    %{
      amount: fee,
      description: "Transaction fee (#{Util.format_pct(fee_data.transaction_fee)})"
    }
  end

  defp create_line_items(contract, invoice, line_items) do
    line_items
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {line_item, index}, {:ok, acc} ->
      case Algora.PSP.Invoiceitem.create(
             %{
               invoice: invoice.id,
               customer: contract.client.customer.provider_id,
               amount: MoneyUtils.to_minor_units(line_item.amount),
               currency: to_string(line_item.amount.currency),
               description: line_item.description
             },
             %{idempotency_key: "contract-#{contract.id}-#{index}"}
           ) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp maybe_pay_invoice(contract, nil, txs), do: release_funds(contract, nil, txs)

  defp maybe_pay_invoice(contract, invoice, txs) do
    pm_id = contract.client.customer.default_payment_method.provider_id

    case Invoice.pay(invoice.id, %{off_session: true, payment_method: pm_id}, %{
           idempotency_key: "contract-#{contract.id}"
         }) do
      {:ok, stripe_invoice} ->
        if stripe_invoice.paid, do: release_funds(contract, stripe_invoice, txs)
        {:ok, stripe_invoice}

      {:error, error} ->
        update_transaction_status(txs.charge, {:error, error})
        {:error, error}
    end
  end

  defp release_funds(contract, metadata, txs) do
    if txs[:debit], do: update_transaction_status(txs.debit, metadata, :succeeded)
    if txs[:credit], do: update_transaction_status(txs.credit, metadata, :succeeded)
    if txs[:transfer], do: transfer_funds(contract, txs.transfer)
    {:ok, :ok}
  end

  # TODO: do we need to lock the transactions here?
  defp transfer_funds(contract, %Transaction{type: :transfer} = transaction) when transaction.status != :succeeded do
    with {:ok, account} <- Repo.fetch_by(Account, user_id: transaction.user_id),
         {:ok, stripe_transfer} <-
           Algora.PSP.Transfer.create(
             %{
               amount: MoneyUtils.to_minor_units(transaction.net_amount),
               currency: to_string(transaction.net_amount.currency),
               destination: account.provider_id
             },
             %{idempotency_key: transaction.id}
           ) do
      update_transaction_status(transaction, stripe_transfer, :succeeded)
      mark_contract_as_paid(contract)
      {:ok, stripe_transfer}
    else
      {:error, error} ->
        update_transaction_status(transaction, {:error, error})
        Activities.insert(contract, %{type: :contract_prepayment_failed})
        {:error, error}
    end
  end

  defp update_transaction_status(transaction, {:error, error}) do
    transaction
    |> change(%{
      provider_meta: Util.normalize_struct(%{error: error}),
      status: :failed
    })
    |> Repo.update()
  end

  defp update_transaction_status(transaction, nil, status) do
    transaction
    |> change(%{
      status: status,
      succeeded_at: if(status == :succeeded, do: DateTime.utc_now())
    })
    |> Repo.update()
  end

  defp update_transaction_status(transaction, record, status) do
    transaction
    |> change(%{
      provider_id: record.id,
      provider_meta: Util.normalize_struct(record),
      status: status,
      succeeded_at: if(status == :succeeded, do: DateTime.utc_now())
    })
    |> Repo.update()
  end

  defp mark_contract_as_paid(contract) do
    change(contract, %{status: :paid})
  end

  defp renew_contract(contract) do
    %Contract{}
    |> change(%{
      id: Nanoid.generate(),
      status: :active,
      start_date: contract.end_date,
      end_date: DateTime.add(contract.end_date, 7, :day),
      sequence_number: contract.sequence_number + 1,
      original_contract_id: contract.original_contract_id,
      client_id: contract.client_id,
      contractor_id: contract.contractor_id,
      hourly_rate: contract.hourly_rate,
      hours_per_week: contract.hours_per_week
    })
    |> Repo.insert_with_activity(%{
      type: :contract_renewed,
      notify_users: []
    })
  end

  def calculate_transfer_amount(contract) do
    Money.mult!(contract.hourly_rate, contract.timesheet.hours_worked)
  end

  def fetch_contract(criteria) when is_list(criteria) do
    case list_contract_chain(criteria) do
      [contract] -> {:ok, contract}
      [] -> {:error, :not_found}
      _ -> {:error, :multiple_contracts}
    end
  end

  def fetch_contract(id) do
    fetch_contract(id: id)
  end

  def fetch_last_contract(id) do
    fetch_contract(original_contract_id: id, limit: 1, order: :desc)
  end

  def list_contracts(criteria \\ []) do
    list_contract_chain(criteria)
  end

  # TODO: rename
  def list_contract_chain(criteria \\ []) do
    criteria = Keyword.merge([order: :desc, limit: 50], criteria)

    transaction_amounts =
      Transaction
      |> maybe_filter_txs_by_contract_id(criteria)
      |> maybe_filter_txs_by_original_contract_id(criteria)
      |> group_by([t], t.contract_id)
      |> select([t], %{
        contract_id: t.contract_id,
        amount_credited: Algora.SQL.sum_by_type(t, "credit"),
        amount_debited: Algora.SQL.sum_by_type(t, "debit")
      })

    transaction_totals =
      Transaction
      |> maybe_filter_txs_by_original_contract_id(criteria)
      |> group_by([t], t.original_contract_id)
      |> select([t], %{
        original_contract_id: t.original_contract_id,
        total_charged: Algora.SQL.sum_by_type(t, "charge"),
        total_credited: Algora.SQL.sum_by_type(t, "credit"),
        total_debited: Algora.SQL.sum_by_type(t, "debit"),
        total_deposited: Algora.SQL.sum_by_type(t, "deposit"),
        total_transferred: Algora.SQL.sum_by_type(t, "transfer"),
        total_withdrawn: Algora.SQL.sum_by_type(t, "withdrawal")
      })

    base_contracts = Contract |> apply_criteria(criteria) |> select([c], c.id)

    from(c in Contract)
    |> join(:inner, [c], bc in subquery(base_contracts), on: c.id == bc.id)
    |> join(:inner, [c], cl in assoc(c, :client), as: :cl)
    |> join(:left, [c], ct in assoc(c, :contractor), as: :ct)
    |> join(:left, [c, cl: cl], cu in assoc(cl, :customer), as: :cu)
    |> join(:left, [c, cu: cu], dpm in assoc(cu, :default_payment_method), as: :dpm)
    |> join(:left, [c], ts in assoc(c, :timesheet), as: :ts)
    |> join(:left, [c], txs in assoc(c, :transactions), as: :txs)
    |> join(:left, [c], ta in subquery(transaction_amounts),
      on: ta.contract_id == c.id,
      as: :ta
    )
    |> join(:left, [c], tt in subquery(transaction_totals),
      on: tt.original_contract_id == c.original_contract_id,
      as: :tt
    )
    |> join(:left, [c], act in assoc(c, :activities), as: :act)
    |> select_merge([ta: ta, tt: tt], %{
      amount_credited: Algora.SQL.money_or_zero(ta.amount_credited),
      amount_debited: Algora.SQL.money_or_zero(ta.amount_debited),
      total_charged: Algora.SQL.money_or_zero(tt.total_charged),
      total_credited: Algora.SQL.money_or_zero(tt.total_credited),
      total_debited: Algora.SQL.money_or_zero(tt.total_debited),
      total_deposited: Algora.SQL.money_or_zero(tt.total_deposited),
      total_transferred: Algora.SQL.money_or_zero(tt.total_transferred),
      total_withdrawn: Algora.SQL.money_or_zero(tt.total_withdrawn)
    })
    |> preload([ts: ts, txs: txs, cl: cl, ct: ct, cu: cu, dpm: dpm, act: act],
      timesheet: ts,
      transactions: txs,
      client: {cl, customer: {cu, default_payment_method: dpm}},
      contractor: ct,
      activities: act
    )
    |> Repo.all()
    |> Enum.map(&Contract.after_load/1)
  end

  @spec apply_criteria(Ecto.Queryable.t(), [criterion()]) :: Ecto.Queryable.t()
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:id, id}, query ->
        from([c] in query, where: c.id == ^id)

      {:contractor_id, contractor_id}, query ->
        from([c] in query, where: c.contractor_id == ^contractor_id)

      {:client_id, client_id}, query ->
        from([c] in query, where: c.client_id == ^client_id)

      {:original_contract_id, original_contract_id}, query ->
        from([c] in query, where: c.original_contract_id == ^original_contract_id)

      {:open?, true}, query ->
        from([c] in query, where: is_nil(c.contractor_id))

      {:active_or_paid?, true}, query ->
        from([c] in query, where: c.status in [:active, :paid])

      {:original?, true}, query ->
        from([c] in query, where: c.id == c.original_contract_id)

      {:status, {:in, statuses}}, query ->
        from([c] in query, where: c.status in ^statuses)

      {:status, status}, query ->
        from([c] in query, where: c.status == ^status)

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
