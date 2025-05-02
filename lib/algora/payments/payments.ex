defmodule Algora.Payments do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Admin
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs.PromptPayoutConnect
  alias Algora.Bounties.Tip
  alias Algora.Jobs.JobPosting
  alias Algora.MoneyUtils
  alias Algora.Payments.Account
  alias Algora.Payments.Customer
  alias Algora.Payments.Jobs
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.PSP
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace.Ticket

  require Logger

  def metadata_version, do: "2"

  def broadcast do
    Phoenix.PubSub.broadcast(Algora.PubSub, "payments:all", :payments_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "payments:all")
  end

  @spec create_stripe_session(
          user :: User.t() | nil,
          line_items :: [PSP.Session.line_item_data()],
          payment_intent_data :: PSP.Session.payment_intent_data(),
          opts :: [
            {:success_url, String.t()},
            {:cancel_url, String.t()}
          ]
        ) ::
          {:ok, PSP.session()} | {:error, PSP.error()}
  def create_stripe_session(user, line_items, payment_intent_data, opts \\ [])

  def create_stripe_session(nil, line_items, payment_intent_data, opts) do
    opts = %{
      mode: "payment",
      billing_address_collection: "required",
      line_items: line_items,
      success_url: opts[:success_url] || "#{AlgoraWeb.Endpoint.url()}/payment/success",
      cancel_url: opts[:cancel_url] || "#{AlgoraWeb.Endpoint.url()}/payment/canceled",
      payment_intent_data: payment_intent_data
    }

    opts =
      if payment_intent_data[:capture_method] == :manual do
        opts
      else
        Map.put(opts, :invoice_creation, %{enabled: true})
      end

    PSP.Session.create(opts)
  end

  def create_stripe_session(user, line_items, payment_intent_data, opts) do
    with {:ok, customer} <- fetch_or_create_customer(user) do
      opts = %{
        mode: "payment",
        customer: customer.provider_id,
        billing_address_collection: "required",
        line_items: line_items,
        success_url: opts[:success_url] || "#{AlgoraWeb.Endpoint.url()}/payment/success",
        cancel_url: opts[:cancel_url] || "#{AlgoraWeb.Endpoint.url()}/payment/canceled",
        payment_intent_data: payment_intent_data
      }

      opts =
        if payment_intent_data[:capture_method] == :manual do
          opts
        else
          Map.put(opts, :invoice_creation, %{enabled: true})
        end

      PSP.Session.create(opts)
    end
  end

  def get_transaction_fee_pct, do: Decimal.new("0.04")

  def get_provider_fee_from_balance_transaction(txn) do
    case Money.from_integer(txn.fee, txn.currency) do
      %Money{} = amount -> amount
      _ -> nil
    end
  end

  def get_provider_fee_from_invoice(%{charge: %{balance_transaction: txn}}) when not is_nil(txn) do
    get_provider_fee_from_balance_transaction(txn)
  end

  def get_provider_fee_from_invoice(%{id: id}) do
    case PSP.Invoice.retrieve(id, expand: ["charge.balance_transaction"]) do
      {:ok, invoice} ->
        get_provider_fee_from_balance_transaction(invoice.charge.balance_transaction)

      _ ->
        nil
    end
  end

  # TODO: This is not used anymore
  def get_provider_fee_from_payment_intent(pi) do
    with [ch] <- pi.charges.data,
         {:ok, txn} <- PSP.BalanceTransaction.retrieve(ch.balance_transaction) do
      get_provider_fee_from_balance_transaction(txn)
    else
      _ -> nil
    end
  end

  def get_customer_by(fields), do: Repo.get_by(Customer, fields)

  def fetch_customer_by(fields), do: Repo.fetch_by(Customer, fields)

  @spec fetch_default_payment_method(user_id :: String.t()) ::
          {:ok, PaymentMethod.t()} | {:error, :not_found}
  def fetch_default_payment_method(user_id) do
    Repo.fetch_one(
      from(pm in PaymentMethod,
        join: c in assoc(pm, :customer),
        where: c.user_id == ^user_id and pm.is_default == true
      )
    )
  end

  @spec has_default_payment_method?(user_id :: String.t()) :: boolean()
  def has_default_payment_method?(user_id) do
    Repo.exists?(
      from(pm in PaymentMethod,
        join: c in assoc(pm, :customer),
        where: c.user_id == ^user_id and pm.is_default == true
      )
    )
  end

  def get_total_paid(client_id, contractor_id) do
    Transaction
    |> join(:inner, [t], lt in Transaction,
      as: :lt,
      on: t.linked_transaction_id == lt.id
    )
    |> where([t], t.user_id == ^client_id)
    |> where([lt: lt], lt.user_id == ^contractor_id)
    |> where([t], t.type == :debit)
    |> where([lt: lt], lt.type == :credit)
    |> where([t], t.status == :succeeded)
    |> select([t], sum(t.net_amount))
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> Money.zero(:USD)
      amount -> amount
    end
  end

  def get_max_paid_to_single_contractor(client_id) do
    Transaction
    |> join(:inner, [t], lt in Transaction,
      as: :lt,
      on: t.linked_transaction_id == lt.id
    )
    |> where([t], t.user_id == ^client_id)
    |> where([t], t.type == :debit)
    |> where([lt: lt], lt.type == :credit)
    |> where([t], t.status == :succeeded)
    |> group_by([lt: lt], lt.user_id)
    |> select([t, lt: lt], {lt.user_id, sum(t.net_amount)})
    |> order_by([t], desc: sum(t.net_amount))
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> {nil, Money.zero(:USD)}
      {user_id, amount} -> {user_id, amount}
    end
  end

  def list_transactions(criteria \\ []) do
    criteria
    |> Enum.reduce(Transaction, fn {key, value}, query ->
      case value do
        v when is_list(v) -> where(query, [t], field(t, ^key) in ^v)
        v -> where(query, [t], field(t, ^key) == ^v)
      end
    end)
    |> preload(linked_transaction: :user)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @spec fetch_or_create_customer(user :: User.t()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, PSP.error()}
  def fetch_or_create_customer(user) do
    case fetch_customer_by(user_id: user.id) do
      {:ok, customer} -> {:ok, customer}
      {:error, :not_found} -> create_customer(user)
    end
  end

  @spec create_customer(user :: User.t()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, PSP.error()}
  def create_customer(user) do
    with {:ok, stripe_customer} <- PSP.Customer.create(%{name: user.name}) do
      %Customer{}
      |> Customer.changeset(%{
        provider: "stripe",
        provider_id: stripe_customer.id,
        provider_meta: Util.normalize_struct(stripe_customer),
        user_id: user.id,
        name: user.name
      })
      |> Repo.insert()
    end
  end

  @spec create_payment_method(customer :: Customer.t(), payment_method :: PSP.payment_method()) ::
          {:ok, PaymentMethod.t()} | {:error, Ecto.Changeset.t()}
  def create_payment_method(customer, payment_method) do
    %PaymentMethod{}
    |> PaymentMethod.changeset(%{
      provider: "stripe",
      provider_id: payment_method.id,
      provider_meta: Util.normalize_struct(payment_method),
      provider_customer_id: customer.provider_id,
      customer_id: customer.id,
      is_default: true
    })
    |> Repo.insert()
  end

  @spec create_stripe_setup_session(customer :: Customer.t(), success_url :: String.t(), cancel_url :: String.t()) ::
          {:ok, PSP.session()} | {:error, PSP.error()}
  def create_stripe_setup_session(customer, success_url, cancel_url) do
    PSP.Session.create(%{
      mode: "setup",
      billing_address_collection: "required",
      payment_method_types: ["card"],
      success_url: success_url,
      cancel_url: cancel_url,
      customer: customer.provider_id
    })
  end

  @spec fetch_or_create_account(user :: User.t(), country :: String.t()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def fetch_or_create_account(user, country) do
    case fetch_account(user) do
      {:ok, account} -> {:ok, account}
      {:error, :not_found} -> create_account(user, country)
    end
  end

  @spec fetch_account(user :: User.t()) ::
          {:ok, Account.t()} | {:error, :not_found}
  def fetch_account(user) do
    Repo.fetch_by(Account, user_id: user.id)
  end

  @spec get_account(user :: User.t()) :: Account.t() | nil
  def get_account(user) do
    Repo.get_by(Account, user_id: user.id)
  end

  @spec create_account(user :: User.t(), country :: String.t()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(user, country) do
    type = PSP.ConnectCountries.account_type(country)

    with {:ok, stripe_account} <- create_stripe_account(%{country: country, type: type}) do
      attrs = %{
        provider: "stripe",
        provider_id: stripe_account.id,
        provider_meta: Util.normalize_struct(stripe_account),
        type: type,
        user_id: user.id,
        country: country
      }

      %Account{}
      |> Account.changeset(attrs)
      |> Repo.insert()
    end
  end

  @spec create_stripe_account(attrs :: map()) ::
          {:ok, PSP.account()} | {:error, PSP.error()}
  defp create_stripe_account(%{country: country, type: type}) do
    case PSP.Account.create(%{country: country, type: to_string(type)}) do
      {:ok, account} -> {:ok, account}
      {:error, _reason} -> PSP.Account.create(%{type: to_string(type)})
    end
  end

  @spec create_account_link(account :: Account.t(), base_url :: String.t()) ::
          {:ok, PSP.account_link()} | {:error, PSP.error()}
  def create_account_link(account, base_url) do
    PSP.AccountLink.create(%{
      account: account.provider_id,
      refresh_url: "#{base_url}/callbacks/stripe/refresh",
      return_url: "#{base_url}/callbacks/stripe/return",
      type: "account_onboarding"
    })
  end

  @spec create_login_link(account :: Account.t()) ::
          {:ok, PSP.login_link()} | {:error, PSP.error()}
  def create_login_link(account) do
    PSP.LoginLink.create(account.provider_id)
  end

  @spec update_account(account :: Account.t(), stripe_account :: PSP.account()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update_account(account, stripe_account) do
    account
    |> Account.changeset(%{
      provider: "stripe",
      provider_id: stripe_account.id,
      provider_meta: Util.normalize_struct(stripe_account),
      charges_enabled: stripe_account.charges_enabled,
      payouts_enabled: stripe_account.payouts_enabled,
      payout_interval: stripe_account.settings.payouts.schedule.interval,
      payout_speed: stripe_account.settings.payouts.schedule.delay_days,
      default_currency: stripe_account.default_currency,
      details_submitted: stripe_account.details_submitted,
      country: stripe_account.country,
      service_agreement: get_service_agreement(stripe_account)
    })
    |> Repo.update()
  end

  @spec refresh_stripe_account(user :: User.t()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_found} | {:error, PSP.error()}
  def refresh_stripe_account(user) do
    with {:ok, account} <- fetch_account(user),
         {:ok, stripe_account} <- PSP.Account.retrieve(account.provider_id),
         {:ok, updated_account} <- update_account(account, stripe_account) do
      user = Accounts.get_user(account.user_id)

      if user && stripe_account.payouts_enabled do
        Accounts.update_settings(user, %{country: stripe_account.country})
        enqueue_pending_transfers(account.user_id)
      end

      {:ok, updated_account}
    end
  end

  @spec get_service_agreement(account :: PSP.account()) :: String.t()
  defp get_service_agreement(%{tos_acceptance: %{service_agreement: agreement}} = _account) when not is_nil(agreement) do
    agreement
  end

  @spec get_service_agreement(account :: PSP.account()) :: String.t()
  defp get_service_agreement(%{capabilities: capabilities}) do
    if is_nil(capabilities[:card_payments]), do: "recipient", else: "full"
  end

  @spec delete_account(account :: Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def delete_account(account) do
    with {:ok, _stripe_account} <- PSP.Account.delete(account.provider_id) do
      Repo.delete(account)
    end
  end

  @spec execute_pending_transfer(credit_id :: String.t()) ::
          {:ok, PSP.transfer()} | {:error, :not_found} | {:error, :duplicate_transfer_attempt}
  def execute_pending_transfer(credit_id) do
    with {:ok, credit} <- Repo.fetch_by(Transaction, id: credit_id, type: :credit, status: :succeeded) do
      case fetch_active_account(credit.user_id) do
        {:ok, account} ->
          with {:ok, transaction} <- fetch_or_create_transfer(credit),
               {:ok, transfer} <- execute_transfer(transaction, account) do
            broadcast()
            {:ok, transfer}
          else
            error ->
              Logger.error("Failed to execute transfer: #{inspect(error)}")
              error
          end

        _ ->
          Logger.error("Attempted to execute transfer to inactive account")
          {:error, :no_active_account}
      end
    end
  end

  def list_payable_credits(user_id) do
    Repo.all(
      from(cr in Transaction,
        left_join: tr in Transaction,
        on:
          tr.user_id == cr.user_id and tr.group_id == cr.group_id and tr.type == :transfer and
            tr.status in [:initialized, :processing, :succeeded],
        where: cr.user_id == ^user_id,
        where: cr.type == :credit,
        where: cr.status == :succeeded,
        where: is_nil(tr.id)
      )
    )
  end

  def list_hosted_transactions(user_id, opts \\ []) do
    query =
      from tx in Transaction,
        where: tx.type == :credit,
        where: not is_nil(tx.succeeded_at),
        join: ltx in assoc(tx, :linked_transaction),
        join: recipient in assoc(tx, :user),
        left_join: bounty in assoc(tx, :bounty),
        left_join: tip in assoc(tx, :tip),
        join: t in Ticket,
        on: t.id == bounty.ticket_id or t.id == tip.ticket_id,
        left_join: r in assoc(t, :repository),
        where: ltx.user_id == ^user_id or r.user_id == ^user_id,
        left_join: o in assoc(r, :user),
        select: %{transaction: tx, recipient: recipient, ticket: %{t | repository: %{r | user: o}}},
        order_by: [desc: tx.succeeded_at]

    query =
      if cursor = opts[:before] do
        from [tx] in query,
          where: {tx.succeeded_at, tx.id} < {^cursor.succeeded_at, ^cursor.id}
      else
        query
      end

    query = from q in query, limit: ^opts[:limit]

    Repo.all(query)
  end

  def list_received_transactions(user_id, opts \\ []) do
    query =
      from tx in Transaction,
        where: tx.user_id == ^user_id,
        where: tx.type == :credit,
        where: not is_nil(tx.succeeded_at),
        join: ltx in assoc(tx, :linked_transaction),
        join: sender in assoc(ltx, :user),
        left_join: bounty in assoc(tx, :bounty),
        left_join: tip in assoc(tx, :tip),
        join: t in Ticket,
        on: t.id == bounty.ticket_id or t.id == tip.ticket_id,
        left_join: r in assoc(t, :repository),
        left_join: o in assoc(r, :user),
        select: %{transaction: tx, sender: sender, ticket: %{t | repository: %{r | user: o}}},
        order_by: [desc: tx.succeeded_at]

    query =
      if cursor = opts[:before] do
        from [tx] in query,
          where: {tx.succeeded_at, tx.id} < {^cursor.succeeded_at, ^cursor.id}
      else
        query
      end

    query = from q in query, limit: ^opts[:limit]

    Repo.all(query)
  end

  @spec enqueue_pending_transfers(user_id :: String.t()) :: {:ok, nil} | {:error, term()}
  def enqueue_pending_transfers(user_id) do
    Repo.transact(fn ->
      with {:ok, _account} <- fetch_active_account(user_id),
           credits = list_payable_credits(user_id),
           :ok <-
             Enum.reduce_while(credits, :ok, fn credit, :ok ->
               case %{credit_id: credit.id}
                    |> Jobs.ExecutePendingTransfer.new()
                    |> Oban.insert() do
                 {:ok, _job} -> {:cont, :ok}
                 error -> {:halt, error}
               end
             end) do
        {:ok, nil}
      else
        {:error, reason} ->
          Logger.error("Failed to execute pending transfers: #{inspect(reason)}")
          {:error, reason}
      end
    end)
  end

  @spec fetch_active_account(user_id :: String.t()) :: {:ok, Account.t()} | {:error, :no_active_account}
  def fetch_active_account(user_id) do
    case Repo.fetch_by(Account, user_id: user_id, provider: "stripe", payouts_enabled: true) do
      {:ok, account} -> {:ok, account}
      {:error, :not_found} -> {:error, :no_active_account}
    end
  end

  def fetch_or_create_transfer(%Transaction{} = credit) do
    idempotency_key = "credit_#{credit.id}"

    case Repo.get_by(Transaction, idempotency_key: idempotency_key) do
      nil ->
        %Transaction{}
        |> change(%{
          id: Nanoid.generate(),
          provider: "stripe",
          type: :transfer,
          status: :initialized,
          tip_id: credit.tip_id,
          bounty_id: credit.bounty_id,
          contract_id: credit.contract_id,
          claim_id: credit.claim_id,
          user_id: credit.user_id,
          gross_amount: credit.net_amount,
          net_amount: credit.net_amount,
          total_fee: Money.zero(:USD),
          group_id: credit.group_id,
          idempotency_key: idempotency_key
        })
        |> Algora.Validations.validate_positive(:gross_amount)
        |> Algora.Validations.validate_positive(:net_amount)
        |> unique_constraint(:idempotency_key)
        |> foreign_key_constraint(:user_id)
        |> foreign_key_constraint(:tip_id)
        |> foreign_key_constraint(:bounty_id)
        |> foreign_key_constraint(:contract_id)
        |> foreign_key_constraint(:claim_id)
        |> Repo.insert()

      transfer ->
        {:ok, transfer}
    end
  end

  def execute_transfer(%Transaction{} = transaction, account) do
    charge = Repo.get_by(Transaction, type: :charge, status: :succeeded, group_id: transaction.group_id)

    transfer_params =
      %{
        amount: MoneyUtils.to_minor_units(transaction.net_amount),
        currency: MoneyUtils.to_stripe_currency(transaction.net_amount),
        destination: account.provider_id,
        metadata: %{"version" => metadata_version()}
      }
      |> Map.merge(if transaction.group_id, do: %{transfer_group: transaction.group_id}, else: %{})
      |> Map.merge(if charge && charge.provider_id, do: %{source_transaction: charge.provider_id}, else: %{})

    case PSP.Transfer.create(transfer_params, %{idempotency_key: transaction.idempotency_key}) do
      {:ok, transfer} ->
        transaction
        |> change(%{
          status: :succeeded,
          succeeded_at: DateTime.utc_now(),
          provider_id: transfer.id,
          provider_transfer_id: transfer.id,
          provider_meta: Util.normalize_struct(transfer)
        })
        |> Repo.update()

        {:ok, transfer}

      {:error, error} ->
        transaction
        |> change(%{status: :failed})
        |> Repo.update()

        {:error, error}
    end
  end

  def process_charge(%Stripe.Event{type: "charge.succeeded", data: %{object: %Stripe.Charge{}}}, group_id)
      when not is_binary(group_id) do
    {:error, :invalid_group_id}
  end

  def process_charge(
        "charge.succeeded",
        %Stripe.Charge{id: charge_id, captured: false, payment_intent: payment_intent_id},
        group_id
      ) do
    Repo.transact(fn ->
      Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id, where: t.type == :charge),
        set: [
          status: :requires_capture,
          provider: "stripe",
          provider_id: charge_id,
          provider_charge_id: charge_id,
          provider_payment_intent_id: payment_intent_id
        ]
      )

      broadcast()
      {:ok, nil}
    end)
  end

  def process_charge(
        "charge.captured",
        %Stripe.Charge{id: charge_id, captured: true, payment_intent: payment_intent_id},
        group_id
      ) do
    Repo.transact(fn ->
      Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id, where: t.type == :charge),
        set: [
          status: :succeeded,
          provider: "stripe",
          provider_id: charge_id,
          provider_charge_id: charge_id,
          provider_payment_intent_id: payment_intent_id
        ]
      )

      Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id, where: t.type != :charge),
        set: [
          status: :requires_release,
          provider: "stripe",
          provider_id: charge_id,
          provider_charge_id: charge_id,
          provider_payment_intent_id: payment_intent_id
        ]
      )

      broadcast()
      {:ok, nil}
    end)
  end

  def process_charge(
        "charge.succeeded",
        %Stripe.Charge{id: charge_id, captured: true, payment_intent: payment_intent_id},
        group_id
      ) do
    Repo.transact(fn ->
      {_, txs} =
        Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id, select: t),
          set: [
            status: :processing,
            provider: "stripe",
            provider_id: charge_id,
            provider_charge_id: charge_id,
            provider_payment_intent_id: payment_intent_id
          ]
        )

      bounty_ids = txs |> Enum.map(& &1.bounty_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()

      bounties =
        from(b in Bounty,
          where: b.id in ^bounty_ids,
          join: u in assoc(b, :owner),
          join: t in assoc(b, :ticket),
          select: %{b | ticket: t, owner: u}
        )
        |> Repo.all()
        |> Map.new(&{&1.id, &1})

      {auto_bounty_ids, manual_bounty_ids} =
        Enum.split_with(bounty_ids, fn id ->
          bounty = bounties[id]
          bounty && bounty.contract_type != :marketplace
        end)

      tip_ids = txs |> Enum.map(& &1.tip_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
      claim_ids = txs |> Enum.map(& &1.claim_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
      job_ids = txs |> Enum.map(& &1.job_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()

      Repo.update_all(from(b in Bounty, where: b.id in ^auto_bounty_ids), set: [status: :paid])
      Repo.update_all(from(t in Tip, where: t.id in ^tip_ids), set: [status: :paid])
      # TODO: add and use a new "paid" status for claims
      Repo.update_all(from(c in Claim, where: c.id in ^claim_ids), set: [status: :approved])

      {_, job_postings} =
        Repo.update_all(from(j in JobPosting, where: j.id in ^job_ids, select: j), set: [status: :active])

      job_postings = Repo.preload(job_postings, :user)

      Repo.update_all(from(u in User, where: u.id in ^Enum.map(job_postings, & &1.user_id)),
        set: [hiring_subscription: :active]
      )

      for job <- job_postings do
        Algora.Admin.alert("Job payment received! #{job.company_name} #{job.email} #{job.url}", :critical)
      end

      auto_txs =
        Enum.filter(txs, fn tx ->
          bounty = bounties[tx.bounty_id]

          manual? = tx.bounty_id in manual_bounty_ids

          if tx.type == :credit and manual? do
            Admin.alert(
              "Contract payment received. URL: #{AlgoraWeb.Endpoint.url()}/#{bounty.owner.handle}/contracts/#{bounty.id}",
              :info
            )
          end

          tx.type != :credit or not manual?
        end)

      Repo.update_all(
        from(t in Transaction, where: t.group_id == ^group_id and t.id in ^Enum.map(auto_txs, & &1.id), select: t),
        set: [status: :succeeded, succeeded_at: DateTime.utc_now()]
      )

      activities_result =
        auto_txs
        |> Enum.filter(&(&1.type == :credit))
        |> Enum.reduce_while(:ok, fn tx, :ok ->
          case Repo.insert_activity(tx, %{type: :transaction_succeeded, notify_users: [tx.user_id]}) do
            {:ok, _} -> {:cont, :ok}
            error -> {:halt, error}
          end
        end)

      jobs_result =
        auto_txs
        |> Enum.filter(&(&1.type == :credit))
        |> Enum.reduce_while(:ok, fn credit, :ok ->
          case fetch_active_account(credit.user_id) do
            {:ok, _account} ->
              case %{credit_id: credit.id}
                   |> Jobs.ExecutePendingTransfer.new()
                   |> Oban.insert() do
                {:ok, _job} -> {:cont, :ok}
                error -> {:halt, error}
              end

            {:error, :no_active_account} ->
              case %{credit_id: credit.id}
                   |> PromptPayoutConnect.new()
                   |> Oban.insert() do
                {:ok, _job} -> {:cont, :ok}
                error -> {:halt, error}
              end
          end
        end)

      with txs when txs != [] <- txs,
           :ok <- activities_result,
           :ok <- jobs_result do
        broadcast()
        {:ok, nil}
      else
        {:error, reason} ->
          Logger.error("Failed to update transactions: #{inspect(reason)}")
          {:error, :failed_to_update_transactions}

        error ->
          Logger.error("Failed to update transactions: #{inspect(error)}")
          {:error, :failed_to_update_transactions}
      end
    end)
  end

  def process_release(
        %Stripe.Charge{id: charge_id, captured: true, payment_intent: payment_intent_id},
        group_id,
        amount,
        recipient
      ) do
    Repo.transact(fn ->
      tx = Repo.get_by(Transaction, group_id: group_id, type: :charge, status: :succeeded)

      user = Repo.get_by(User, id: tx.user_id)
      bounty = Repo.get_by(Bounty, id: tx.bounty_id)

      Algora.Admin.alert(
        "Release #{amount} escrow to #{recipient.handle} for #{AlgoraWeb.Endpoint.url()}/#{user.handle}/contracts/#{bounty.id}",
        :critical
      )

      debit_id = Nanoid.generate()
      credit_id = Nanoid.generate()

      with {:ok, debit0} <- Repo.fetch_by(Transaction, group_id: group_id, type: :debit, status: :requires_release),
           {:ok, _} <-
             debit0
             |> change(%{
               net_amount: Money.sub!(debit0.net_amount, amount),
               gross_amount: Money.sub!(debit0.gross_amount, amount)
             })
             |> Repo.update(),
           {:ok, credit0} <- Repo.fetch_by(Transaction, group_id: group_id, type: :credit, status: :requires_release),
           {:ok, _} <-
             credit0
             |> change(%{
               net_amount: Money.add!(credit0.net_amount, amount),
               gross_amount: Money.add!(credit0.gross_amount, amount)
             })
             |> Repo.update(),
           {:ok, _debit} <-
             Repo.insert(%Transaction{
               id: debit_id,
               provider: "stripe",
               provider_id: charge_id,
               provider_charge_id: charge_id,
               provider_payment_intent_id: payment_intent_id,
               type: :debit,
               status: :succeeded,
               succeeded_at: DateTime.utc_now(),
               bounty_id: tx.bounty_id,
               user_id: tx.user_id,
               gross_amount: amount,
               net_amount: amount,
               total_fee: Money.zero(:USD),
               linked_transaction_id: credit_id,
               group_id: group_id
             }),
           {:ok, _credit} <-
             Repo.insert(%Transaction{
               id: credit_id,
               provider: "stripe",
               provider_id: charge_id,
               provider_charge_id: charge_id,
               provider_payment_intent_id: payment_intent_id,
               type: :credit,
               status: :initialized,
               succeeded_at: DateTime.utc_now(),
               bounty_id: tx.bounty_id,
               user_id: recipient.id,
               gross_amount: amount,
               net_amount: amount,
               total_fee: Money.zero(:USD),
               linked_transaction_id: debit_id,
               group_id: group_id
             }) do
        {:ok, nil}
      end
    end)
  end
end
