defmodule Algora.Payments do
  require Logger

  import Ecto.Query
  import Ecto.Changeset
  import Algora.Validators

  alias Algora.Repo
  alias Algora.Util
  alias Algora.Payments.Customer
  alias Algora.Payments.Transaction
  alias Algora.Payments.PaymentMethod

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
end
