defmodule Algora.Payments.Jobs.ExecutePendingTransfers do
  @moduledoc false
  use Oban.Worker, queue: :transfers

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.MoneyUtils
  alias Algora.Payments.Account
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{user_id: user_id, group_id: group_id}}) do
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

    pending_amount = Money.sub!(total_credits, total_transfers)

    with {:ok, account} <- Repo.fetch_by(Account, user_id: user_id, provider: :stripe, payouts_enabled: true),
         true <- Money.positive?(pending_amount) do
      {:ok, transaction} =
        %Transaction{}
        |> change(%{
          provider: "stripe",
          type: :credit,
          status: :initialized,
          user_id: user_id,
          gross_amount: pending_amount,
          net_amount: pending_amount,
          total_fee: Money.zero(:USD),
          group_id: group_id
        })
        |> Algora.Validations.validate_positive(:gross_amount)
        |> Algora.Validations.validate_positive(:net_amount)
        |> foreign_key_constraint(:user_id)
        |> Repo.insert()

      Repo.transact(fn ->
        # TODO: set other params
        # TODO: provide idempotency key
        {:ok, transfer} =
          Stripe.Transfer.create(%{
            amount: MoneyUtils.to_minor_units(pending_amount),
            currency: to_string(pending_amount.currency),
            destination: account.stripe_account_id
          })

        {:ok, transaction} =
          transaction
          |> change(%{
            status: if(transfer.status == :succeeded, do: :succeeded, else: :failed),
            provider_id: transfer.id,
            provider_meta: Util.normalize_struct(transfer)
          })
          |> Repo.update()

        {:ok, transaction}
      end)
    else
      _ -> :ok
    end
  end
end
