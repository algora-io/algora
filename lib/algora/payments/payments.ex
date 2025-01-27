defmodule Algora.Payments do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.MoneyUtils
  alias Algora.Payments.Account
  alias Algora.Payments.Customer
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Stripe.ConnectCountries
  alias Algora.Util

  require Logger

  def metadata_version, do: "2"

  def broadcast do
    Phoenix.PubSub.broadcast(Algora.PubSub, "payments:all", :payments_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "payments:all")
  end

  @spec create_stripe_session(
          line_items :: [Stripe.Session.line_item_data()],
          payment_intent_data :: Stripe.Session.payment_intent_data()
        ) ::
          {:ok, Stripe.Session.t()} | {:error, Stripe.Error.t()}
  def create_stripe_session(line_items, payment_intent_data) do
    Algora.Stripe.create_session(%{
      mode: "payment",
      billing_address_collection: "required",
      line_items: line_items,
      # TODO: handle invoice creation which is not supported by current version
      # invoice_creation: %{enabled: true},
      success_url: "#{AlgoraWeb.Endpoint.url()}/payment/success",
      cancel_url: "#{AlgoraWeb.Endpoint.url()}/payment/canceled",
      payment_intent_data: payment_intent_data
    })
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
    case Stripe.Invoice.retrieve(id, expand: ["charge.balance_transaction"]) do
      {:ok, invoice} ->
        get_provider_fee_from_balance_transaction(invoice.charge.balance_transaction)

      _ ->
        nil
    end
  end

  # TODO: This is not used anymore
  def get_provider_fee_from_payment_intent(pi) do
    with [ch] <- pi.charges.data,
         {:ok, txn} <- Stripe.BalanceTransaction.retrieve(ch.balance_transaction) do
      get_provider_fee_from_balance_transaction(txn)
    else
      _ -> nil
    end
  end

  def get_customer_by(fields), do: Repo.get_by(Customer, fields)

  def get_default_payment_method(org) do
    Repo.one(
      from(pm in PaymentMethod,
        join: c in assoc(pm, :customer),
        join: u in assoc(c, :user),
        where: u.id == ^org.id and pm.is_default == true
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
    Transaction
    |> where([t], ^Enum.to_list(criteria))
    |> preload(linked_transaction: :user)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
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

  @spec create_account(user :: User.t(), country :: String.t()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(user, country) do
    type = ConnectCountries.account_type(country)

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
          {:ok, Stripe.Account.t()} | {:error, Stripe.Error.t()}
  defp create_stripe_account(%{country: country, type: type}) do
    case Stripe.Account.create(%{country: country, type: to_string(type)}) do
      {:ok, account} -> {:ok, account}
      {:error, _reason} -> Stripe.Account.create(%{type: to_string(type)})
    end
  end

  @spec create_account_link(account :: Account.t(), base_url :: String.t()) ::
          {:ok, Stripe.AccountLink.t()} | {:error, Stripe.Error.t()}
  def create_account_link(account, base_url) do
    Stripe.AccountLink.create(%{
      account: account.provider_id,
      refresh_url: "#{base_url}/callbacks/stripe/refresh",
      return_url: "#{base_url}/callbacks/stripe/return",
      type: "account_onboarding"
    })
  end

  @spec create_login_link(account :: Account.t()) ::
          {:ok, Stripe.LoginLink.t()} | {:error, Stripe.Error.t()}
  def create_login_link(account) do
    Stripe.LoginLink.create(account.provider_id, %{})
  end

  @spec update_account(account :: Account.t(), stripe_account :: Stripe.Account.t()) ::
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
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_found} | {:error, Stripe.Error.t()}
  def refresh_stripe_account(user) do
    with {:ok, account} <- fetch_account(user),
         {:ok, stripe_account} <- Stripe.Account.retrieve(account.provider_id, []),
         {:ok, updated_account} <- update_account(account, stripe_account) do
      user = Accounts.get_user(account.user_id)

      if user && stripe_account.charges_enabled do
        Accounts.update_settings(user, %{country: stripe_account.country})
      end

      {:ok, updated_account}
    end
  end

  @spec get_service_agreement(account :: Stripe.Account.t()) :: String.t()
  defp get_service_agreement(%{tos_acceptance: %{service_agreement: agreement}} = _account) when not is_nil(agreement) do
    agreement
  end

  @spec get_service_agreement(account :: Stripe.Account.t()) :: String.t()
  defp get_service_agreement(%{capabilities: capabilities}) do
    if is_nil(capabilities[:card_payments]), do: "recipient", else: "full"
  end

  @spec delete_account(account :: Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def delete_account(account) do
    with {:ok, _stripe_account} <- Stripe.Account.delete(account.provider_id) do
      Repo.delete(account)
    end
  end

  def execute_pending_transfers(user_id) do
    pending_amount = get_pending_amount(user_id)

    with {:ok, account} <- Repo.fetch_by(Account, user_id: user_id, provider: "stripe", payouts_enabled: true),
         true <- Money.positive?(pending_amount) do
      initialize_and_execute_transfer(user_id, pending_amount, account)
    else
      _ -> {:ok, nil}
    end
  end

  defp get_pending_amount(user_id) do
    total_credits =
      Repo.one(
        from(t in Transaction,
          where: t.user_id == ^user_id,
          where: t.type == :credit,
          where: t.status == :succeeded,
          select: sum(t.net_amount)
        )
      ) || Money.zero(:USD)

    total_transfers =
      Repo.one(
        from(t in Transaction,
          where: t.user_id == ^user_id,
          where: t.type == :transfer,
          where: t.status == :succeeded or t.status == :processing or t.status == :initialized,
          select: sum(t.net_amount)
        )
      ) || Money.zero(:USD)

    Money.sub!(total_credits, total_transfers)
  end

  defp initialize_and_execute_transfer(user_id, pending_amount, account) do
    with {:ok, transaction} <- initialize_transfer(user_id, pending_amount),
         {:ok, transfer} <- execute_transfer(transaction, account) do
      broadcast()
      {:ok, transfer}
    else
      error ->
        Logger.error("Failed to execute transfer: #{inspect(error)}")
        error
    end
  end

  defp initialize_transfer(user_id, pending_amount) do
    %Transaction{}
    |> change(%{
      id: Nanoid.generate(),
      provider: "stripe",
      type: :transfer,
      status: :initialized,
      user_id: user_id,
      gross_amount: pending_amount,
      net_amount: pending_amount,
      total_fee: Money.zero(:USD)
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp execute_transfer(transaction, account) do
    # TODO: set other params
    # TODO: provide idempotency key
    case Algora.Stripe.create_transfer(%{
           amount: MoneyUtils.to_minor_units(transaction.net_amount),
           currency: MoneyUtils.to_stripe_currency(transaction.net_amount),
           destination: account.provider_id,
           metadata: %{"version" => metadata_version()}
         }) do
      {:ok, transfer} ->
        # it's fine if this fails since we'll receive a webhook
        transaction
        |> change(%{
          status: :succeeded,
          succeeded_at: DateTime.utc_now(),
          provider_id: transfer.id,
          provider_meta: Util.normalize_struct(transfer)
        })
        |> Repo.update()

        {:ok, transfer}

      {:error, error} ->
        # TODO: inconsistent state if this fails
        transaction
        |> change(%{status: :failed})
        |> Repo.update()

        {:error, error}
    end
  end
end
