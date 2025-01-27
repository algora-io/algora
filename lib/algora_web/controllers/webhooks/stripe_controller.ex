defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Payments
  alias Algora.Payments.Jobs.ExecutePendingTransfers
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util

  require Logger

  @metadata_version Payments.metadata_version()

  @impl true
  def handle_event(%Stripe.Event{
        type: "charge.succeeded",
        data: %{object: %Stripe.Charge{metadata: %{"version" => @metadata_version, "group_id" => group_id}}}
      })
      when is_binary(group_id) do
    Repo.transact(fn ->
      update_result =
        Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id),
          set: [status: :succeeded, succeeded_at: DateTime.utc_now()]
        )

      # TODO: split into two groups:
      #     - has active payout account -> execute pending transfers
      #     - has no active payout account -> notify user to connect payout account
      jobs_result =
        from(t in Transaction,
          where: t.group_id == ^group_id,
          where: t.type == :credit,
          where: t.status == :succeeded
        )
        |> Repo.all()
        |> Enum.map(fn %{user_id: user_id} -> user_id end)
        |> Enum.uniq()
        |> Enum.reduce_while(:ok, fn user_id, :ok ->
          case %{user_id: user_id}
               |> ExecutePendingTransfers.new()
               |> Oban.insert() do
            {:ok, _job} -> {:cont, :ok}
            error -> {:halt, error}
          end
        end)

      with {count, _} when count > 0 <- update_result,
           :ok <- jobs_result do
        Payments.broadcast()
        {:ok, nil}
      else
        {:error, reason} ->
          Logger.error("Failed to update transactions: #{inspect(reason)}")
          {:error, :failed_to_update_transactions}

        _error ->
          Logger.error("Failed to update transactions")
          {:error, :failed_to_update_transactions}
      end
    end)
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "transfer.created",
        data: %{object: %Stripe.Transfer{metadata: %{"version" => @metadata_version}} = transfer}
      }) do
    with {:ok, transaction} <- Repo.fetch_by(Transaction, provider: "stripe", provider_id: transfer.id),
         {:ok, _transaction} <- maybe_update_transaction(transaction, transfer) do
      # TODO: notify user
      Payments.broadcast()
      {:ok, nil}
    else
      error ->
        Logger.error("Failed to update transaction: #{inspect(error)}")
        {:error, :failed_to_update_transaction}
    end
  end

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    Logger.info("Stripe #{event.type} event: #{event.id}")
  end

  @impl true
  def handle_event(_event), do: :ok

  defp maybe_update_transaction(transaction, transfer) do
    if transaction.status == :succeeded do
      {:ok, transaction}
    else
      transaction
      |> change(%{
        status: :succeeded,
        succeeded_at: DateTime.utc_now(),
        provider_meta: Util.normalize_struct(transfer)
      })
      |> Repo.update()
    end
  end
end
