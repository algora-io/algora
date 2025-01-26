defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Query

  alias Algora.Payments
  alias Algora.Payments.Jobs.ExecutePendingTransfers
  alias Algora.Payments.Transaction
  alias Algora.Repo

  require Logger

  @metadata_version "2"

  @impl true
  def handle_event(%Stripe.Event{
        type: "charge.succeeded",
        data: %{object: %{metadata: %{"version" => @metadata_version, "group_id" => group_id}}}
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
          case %{user_id: user_id, group_id: group_id}
               |> ExecutePendingTransfers.new()
               |> Oban.insert() do
            {:ok, _job} -> {:cont, :ok}
            error -> {:halt, error}
          end
        end)

      with {count, _} when count > 0 <- update_result,
           :ok <- jobs_result do
        Payments.broadcast()
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
  def handle_event(%Stripe.Event{type: "transfer.created"} = event) do
    # TODO: update transaction
    # TODO: broadcast
    # TODO: notify user
    Logger.info("Stripe #{event.type} event: #{event.id}")
  end

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    Logger.info("Stripe #{event.type} event: #{event.id}")
  end

  @impl true
  def handle_event(_event), do: :ok
end
