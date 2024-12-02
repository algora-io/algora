defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler
  require Logger

  @impl true
  def handle_event(%Stripe.Event{type: "charge.succeeded"} = event) do
    Logger.info("Stripe #{event.type} event: #{event.id}")
    dbg(event)
    :ok
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
