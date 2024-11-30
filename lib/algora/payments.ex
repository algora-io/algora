defmodule Algora.Payments do
  require Logger

  import Ecto.Query
  import Ecto.Changeset

  alias Algora.{Repo, Util, Users.User, MoneyUtils}
  alias Algora.Payments.Transaction

  @spec create_charge(String.t(), Money.t()) :: {:ok, Stripe.PaymentIntent.t()} | {:error, any()}
  def create_charge(org_handle, amount) do
    org =
      from(u in User,
        where: u.handle == ^org_handle,
        preload: [customer: :default_payment_method]
      )
      |> Repo.one!()

    transaction =
      Repo.insert!(%Transaction{
        id: Nanoid.generate(),
        amount: amount,
        provider: "stripe",
        provider_id: nil,
        provider_meta: nil,
        type: :charge,
        status: :pending,
        succeeded_at: nil
      })

    case Stripe.PaymentIntent.create(%{
           amount: MoneyUtils.to_minor_units(amount),
           currency: to_string(amount.currency),
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
