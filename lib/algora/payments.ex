defmodule Algora.Payments do
  require Logger

  import Ecto.Query
  import Ecto.Changeset

  alias Algora.{Repo, Util, Users.User, MoneyUtils}
  alias Algora.Payments.Transaction

  def get_transaction_fee_pct(), do: Decimal.new("0.04")

  def get_provider_fee(:stripe, pi) do
    with [ch] <- pi.charges.data,
         {:ok, txn} <- Stripe.BalanceTransaction.retrieve(ch.balance_transaction),
         %Money{} = amount <- Money.from_integer(txn.fee, txn.currency) do
      amount
    else
      _ -> nil
    end
  end

  @spec create_charge(String.t(), Money.t(), Money.t()) ::
          {:ok, Stripe.PaymentIntent.t()} | {:error, any()}
  def create_charge(org_handle, net_amount, total_fee) do
    org =
      from(u in User,
        where: u.handle == ^org_handle,
        preload: [customer: :default_payment_method]
      )
      |> Repo.one!()

    gross_amount = Money.add!(net_amount, total_fee)

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
        succeeded_at: nil
      })

    case Stripe.PaymentIntent.create(%{
           amount: MoneyUtils.to_minor_units(gross_amount),
           currency: to_string(gross_amount.currency),
           customer: org.customer.provider_id,
           payment_method: org.customer.default_payment_method.provider_id,
           off_session: true,
           confirm: true
         }) do
      {:ok, ch} ->
        transaction
        |> change(%{
          provider_id: ch.id,
          provider_meta: Util.normalize_struct(ch),
          provider_fee: get_provider_fee(:stripe, ch),
          status: if(ch.status == "succeeded", do: :succeeded, else: :processing),
          succeeded_at: if(ch.status == "succeeded", do: DateTime.utc_now(), else: nil)
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
end
