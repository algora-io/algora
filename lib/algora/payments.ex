defmodule Algora.Payments do
  require Logger

  import Ecto.Query

  alias Algora.Payments.Customer
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.Repo

  def broadcast! do
    Phoenix.PubSub.broadcast!(Algora.PubSub, "payments:all", :payments_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "payments:all")
  end

  def create_stripe_session(line_items, payment_intent_data) do
    params = %{
      mode: "payment",
      billing_address_collection: "required",
      line_items: line_items,
      invoice_creation: %{enabled: true},
      success_url: "#{AlgoraWeb.Endpoint.url()}/payment/success",
      cancel_url: "#{AlgoraWeb.Endpoint.url()}/payment/canceled",
      payment_intent_data: payment_intent_data
    }

    Stripe.Session.create(params)
  end

  def get_transaction_fee_pct(), do: Decimal.new("0.04")

  def get_provider_fee_from_balance_transaction(txn) do
    with %Money{} = amount <- Money.from_integer(txn.fee, txn.currency) do
      amount
    else
      _ -> nil
    end
  end

  def get_provider_fee_from_invoice(%{charge: %{balance_transaction: txn}})
      when not is_nil(txn) do
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
    from(pm in PaymentMethod,
      join: c in assoc(pm, :customer),
      join: u in assoc(c, :user),
      where: u.id == ^org.id and pm.is_default == true
    )
    |> Repo.one()
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
end
