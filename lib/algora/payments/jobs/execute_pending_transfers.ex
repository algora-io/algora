defmodule Algora.Payments.Jobs.ExecutePendingTransfers do
  @moduledoc false
  use Oban.Worker,
    queue: :transfers,
    max_attempts: 1

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
    pending_amount = get_pending_amount(user_id)

    with {:ok, account} <- Repo.fetch_by(Account, user_id: user_id, provider: :stripe, payouts_enabled: true),
         true <- Money.positive?(pending_amount) do
      initialize_and_execute_transfer(user_id, group_id, pending_amount, account)
    else
      _ -> :ok
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

  defp initialize_and_execute_transfer(user_id, group_id, pending_amount, account) do
    with {:ok, transaction} <- initialize_transfer(user_id, group_id, pending_amount),
         {:ok, transfer} <- execute_transfer(transaction, account) do
      {:ok, transfer}
    else
      error ->
        Logger.error("Failed to execute transfer: #{inspect(error)}")
        error
    end
  end

  defp initialize_transfer(user_id, group_id, pending_amount) do
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
  end

  defp execute_transfer(transaction, account) do
    # TODO: set other params
    # TODO: provide idempotency key
    case Stripe.Transfer.create(%{
           amount: MoneyUtils.to_minor_units(transaction.net_amount),
           currency: to_string(transaction.net_amount.currency),
           destination: account.stripe_account_id
         }) do
      {:ok, transfer} ->
        # it's fine if this fails since we'll receive a webhook
        _result = try_update_transaction(transaction, transfer)
        {:ok, transfer}

      {:error, error} ->
        {:error, error}
    end
  end

  defp try_update_transaction(transaction, transfer) do
    transaction
    |> change(%{
      status: if(transfer.status == :succeeded, do: :succeeded, else: :failed),
      provider_id: transfer.id,
      provider_meta: Util.normalize_struct(transfer)
    })
    |> Repo.update()
  end
end
