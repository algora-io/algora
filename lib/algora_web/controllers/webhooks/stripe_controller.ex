defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Query

  alias Algora.Payments
  alias Algora.Payments.Jobs.ExecuteTransfer
  alias Algora.Payments.Transaction
  alias Algora.Repo

  require Logger

  @impl true
  def handle_event(%Stripe.Event{
        type: "charge.succeeded",
        data: %{object: %{metadata: %{"version" => "2", "group_id" => group_id}}}
      })
      when is_binary(group_id) do
    {:ok, count} =
      Repo.transact(fn ->
        {count, _} =
          Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id),
            set: [status: :succeeded, succeeded_at: DateTime.utc_now()]
          )

        # TODO: get pending transfers (recipient with active payout accounts)
        transfers = []

        Enum.map(transfers, fn %{transfer_id: transfer_id, user_id: user_id} ->
          %{transfer_id: transfer_id, user_id: user_id}
          |> ExecuteTransfer.new()
          |> Oban.insert()
        end)

        {:ok, count}
      end)

    if count == 0 do
      {:error, :no_transactions_found}
    else
      Payments.broadcast()
      {:ok, nil}
    end
  end

  @impl true
  def handle_event(%Stripe.Event{type: "transfer.created"} = event) do
    Logger.info("Stripe #{event.type} event: #{event.id}")
  end

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    Logger.info("Stripe #{event.type} event: #{event.id}")
  end

  @impl true
  def handle_event(_event), do: :ok
end
