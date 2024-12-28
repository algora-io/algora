defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler
  require Logger
  alias Algora.Repo
  alias Algora.Payments.Transaction
  import Ecto.Query

  @impl true
  def handle_event(%Stripe.Event{type: "charge.succeeded"} = event) do
    Logger.info("Stripe #{event.type} event: #{event.id}")

    charge_id = get_in(event.data.object.metadata, ["charge_id"])
    debit_id = get_in(event.data.object.metadata, ["debit_id"])
    credit_id = get_in(event.data.object.metadata, ["credit_id"])

    transaction_ids = Enum.reject([charge_id, debit_id, credit_id], &is_nil/1)

    if Enum.empty?(transaction_ids) do
      Logger.error("No transaction IDs found in Stripe event metadata: #{event.id}")
      {:error, :no_transaction_ids}
    else
      Repo.transaction(fn ->
        from(t in Transaction, where: t.id in ^transaction_ids)
        |> Repo.update_all(set: [status: :succeeded, succeeded_at: DateTime.utc_now()])

        # TODO: initiate transfer
        # if debit_id do
        #   %{id: debit_id}
        #   |> Algora.Workers.InitiateTransfer.new()
        #   |> Oban.insert()
        # end

        :ok
      end)
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
