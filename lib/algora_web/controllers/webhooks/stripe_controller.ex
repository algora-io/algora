defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Changeset

  alias Algora.Bounties
  alias Algora.Payments
  alias Algora.Payments.Customer
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util

  require Logger

  @metadata_version Payments.metadata_version()

  @impl true
  def handle_event(%Stripe.Event{} = event) do
    result =
      case process_event(event) do
        :ok -> :ok
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
        :error -> {:error, :unknown_error}
      end

    case result do
      :ok ->
        Logger.debug("✅ #{inspect(event.type)}")
        alert(event, :ok)
        :ok

      {:error, reason} ->
        Logger.error("❌ #{inspect(event.type)}: #{inspect(reason)}")
        alert(event, {:error, reason})
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("❌ #{inspect(event.type)}: #{inspect(error)}")
      alert(event, {:error, error})
      {:error, error}
  end

  defp process_event(%Stripe.Event{
         type: type,
         data: %{object: %Stripe.Charge{metadata: %{"version" => @metadata_version, "group_id" => group_id}} = charge}
       })
       when type in ["charge.succeeded", "charge.captured"] and is_binary(group_id) do
    Payments.process_charge(type, charge, group_id)
  end

  defp process_event(%Stripe.Event{type: type, data: %{object: %Stripe.Charge{invoice: invoice_id} = charge}})
       when type in ["charge.succeeded", "charge.captured"] do
    with {:ok, invoice} <- Algora.PSP.Invoice.retrieve(invoice_id),
         %{"version" => @metadata_version, "group_id" => group_id} <- invoice.metadata do
      Payments.process_charge(type, charge, group_id)
    end
  end

  defp process_event(%Stripe.Event{
         type: "transfer.created",
         data: %{object: %Stripe.Transfer{metadata: %{"version" => @metadata_version}} = transfer}
       }) do
    with {:ok, transaction} <- Repo.fetch_by(Transaction, provider: "stripe", provider_id: transfer.id),
         {:ok, _transaction} <- maybe_update_transaction(transaction, transfer),
         {:ok, _job} <- Oban.insert(Bounties.Jobs.NotifyTransfer.new(%{transfer_id: transaction.id})) do
      Payments.broadcast()
      {:ok, nil}
    else
      error ->
        Logger.error("Failed to update transaction: #{inspect(error)}")
        {:error, :failed_to_update_transaction}
    end
  end

  defp process_event(%Stripe.Event{
         type: "checkout.session.completed",
         data: %{object: %Stripe.Session{customer: customer_id, mode: "setup", setup_intent: setup_intent_id}}
       }) do
    with {:ok, setup_intent} <- Algora.PSP.SetupIntent.retrieve(setup_intent_id, %{}),
         pm_id = setup_intent.payment_method,
         {:ok, payment_method} <- Algora.PSP.PaymentMethod.attach(%{payment_method: pm_id, customer: customer_id}),
         {:ok, customer} <- Repo.fetch_by(Customer, provider: "stripe", provider_id: customer_id),
         {:ok, _} <- Payments.create_payment_method(customer, payment_method) do
      Payments.broadcast()
      :ok
    end
  end

  defp process_event(
         %Stripe.Event{
           type: "checkout.session.completed",
           data: %{object: %Stripe.Session{customer_details: %{name: name, email: email}}}
         } = event
       ) do
    Algora.Activities.alert("#{event.type} #{event.id} by #{name} (#{email})", :info)
    :ok
  end

  defp process_event(%Stripe.Event{type: type} = event)
       when type in ["charge.succeeded", "charge.captured", "transfer.created", "checkout.session.completed"] do
    Algora.Activities.alert("Unhandled Stripe event: #{event.type} #{event.id}", :error)
    :ok
  end

  defp process_event(_event), do: :ok

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

  defp alert(%Stripe.Event{} = event, :ok) do
    Algora.Activities.alert(
      "Stripe event: #{event.type} #{event.id} https://dashboard.stripe.com/logs?success=true",
      :debug
    )
  end

  defp alert(%Stripe.Event{} = event, {:error, error}) do
    Algora.Activities.alert(
      "Stripe event: #{event.type} #{event.id} https://dashboard.stripe.com/logs?success=false Error: #{inspect(error)}",
      :error
    )
  end
end
