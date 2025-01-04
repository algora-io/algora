defmodule Algora.Payments do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Payments.Account
  alias Algora.Payments.Customer
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Stripe.ConnectCountries
  alias Algora.Util

  require Logger

  def broadcast! do
    Phoenix.PubSub.broadcast!(Algora.PubSub, "payments:all", :payments_updated)
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
    Stripe.Session.create(%{
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

  def get_account(user_id, region) do
    Account
    |> where([a], a.user_id == ^user_id and a.region == ^region)
    |> Repo.one()
  end

  @spec create_account(user :: User.t(), attrs :: %{optional(atom()) => any()}) ::
          {:ok, Account.t()} | {:error, any()}
  def create_account(user, attrs) do
    attrs = Map.put(attrs, :type, ConnectCountries.account_type(attrs.country))

    with {:ok, stripe_account} <- create_stripe_account(attrs) do
      attrs = %{
        provider: "stripe",
        provider_id: stripe_account.id,
        provider_meta: Util.normalize_struct(stripe_account),
        type: attrs.type,
        region: :US,
        user_id: user.id,
        country: attrs.country
      }

      %Account{}
      |> Account.changeset(attrs)
      |> Repo.insert()
    end
  end

  @spec create_stripe_account(attrs :: %{optional(atom()) => any()}) ::
          {:ok, Stripe.Account.t()} | {:error, Stripe.Error.t()}
  defp create_stripe_account(%{country: country, type: type}) do
    case Stripe.Account.create(%{country: country, type: type}) do
      {:ok, account} -> {:ok, account}
      {:error, _reason} -> Stripe.Account.create(%{type: type})
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
          {:ok, Stripe.Account.t()} | {:error, Stripe.Error.t()}
  def create_login_link(account) do
    Stripe.Account.create_login_link(account.provider_id, %{})
  end

  @spec refresh_stripe_account(user_id :: binary()) ::
          {:ok, Account.t()} | {:error, :account_not_found} | {:error, any()}
  def refresh_stripe_account(user_id) do
    case get_account(user_id, :US) do
      nil ->
        {:error, :account_not_found}

      account ->
        with {:ok, stripe_account} <- Stripe.Account.retrieve(account.provider_id) do
          attrs = %{
            charges_enabled: stripe_account.charges_enabled,
            details_submitted: stripe_account.details_submitted,
            country: stripe_account.country,
            service_agreement: get_service_agreement(stripe_account),
            provider_meta: Util.normalize_struct(stripe_account)
          }

          account
          |> Account.changeset(attrs)
          |> Repo.update()
          |> case do
            {:ok, updated_account} ->
              if stripe_account.charges_enabled do
                account.user_id
                |> Accounts.get_user!()
                |> Accounts.update_settings(%{country: stripe_account.country})
              end

              # TODO: enqueue pending transfers

              {:ok, updated_account}

            error ->
              error
          end
        end
    end
  end

  defp get_service_agreement(%{tos_acceptance: %{service_agreement: agreement}} = _account) when not is_nil(agreement) do
    agreement
  end

  defp get_service_agreement(%{capabilities: capabilities}) do
    if is_nil(capabilities[:card_payments]), do: "recipient", else: "full"
  end
end
