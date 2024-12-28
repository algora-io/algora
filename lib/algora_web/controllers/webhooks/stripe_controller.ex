defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler
  require Logger
  alias Algora.Repo
  alias Algora.Payments
  alias Algora.Payments.Transaction
  import Ecto.Query

  @impl true
  def handle_event(
        %Stripe.Event{
          type: "charge.succeeded",
          data: %{
            object: %{
              metadata: %{
                "version" => "2",
                "group_id" => group_id
              }
            }
          }
        } = event
      )
      when is_binary(group_id) do
    {:ok, count} =
      Repo.transact(fn ->
        {count, _} =
          from(t in Transaction, where: t.group_id == ^group_id)
          |> Repo.update_all(set: [status: :succeeded, succeeded_at: DateTime.utc_now()])

        # TODO: initiate pending transfers if any recipient has a payout account
        # %{transfer_id: transfer_id, user_id: user_id}
        # |> Algora.Workers.InitiateTransfer.new()
        # |> Oban.insert()

        {:ok, count}
      end)

    if count == 0 do
      {:error, :no_transactions_found}
    else
      Payments.broadcast!()
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
