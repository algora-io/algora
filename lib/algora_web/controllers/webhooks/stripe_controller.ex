defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Tip
  alias Algora.Contracts.Contract
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

  defp process_event(
         %Stripe.Event{
           type: type,
           data: %{object: %Stripe.Charge{metadata: %{"version" => @metadata_version, "group_id" => group_id}}}
         } = event
       )
       when type in ["charge.succeeded", "charge.captured"] and is_binary(group_id) do
    process_charge_succeeded(event, group_id)
  end

  defp process_event(%Stripe.Event{type: type, data: %{object: %Stripe.Charge{invoice: invoice_id}}} = event)
       when type in ["charge.succeeded", "charge.captured"] do
    with {:ok, invoice} <- Algora.PSP.Invoice.retrieve(invoice_id),
         %{"version" => @metadata_version, "group_id" => group_id} <- invoice.metadata do
      process_charge_succeeded(event, group_id)
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
    Algora.Admin.alert("#{event.type} #{event.id} by #{name} (#{email})", :info)
    :ok
  end

  defp process_event(%Stripe.Event{type: type} = event)
       when type in ["charge.succeeded", "transfer.created", "checkout.session.completed"] do
    Algora.Admin.alert("Unhandled Stripe event: #{event.type} #{event.id}", :error)
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

  defp process_charge_succeeded(
         %Stripe.Event{
           type: type,
           data: %{object: %Stripe.Charge{id: charge_id, captured: captured, payment_intent: payment_intent_id}}
         },
         group_id
       )
       when type in ["charge.succeeded", "charge.captured"] and is_binary(group_id) do
    Repo.transact(fn ->
      status = if captured, do: :succeeded, else: :requires_capture
      succeeded_at = if captured, do: DateTime.utc_now()

      {_, txs} =
        Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id, select: t),
          set: [
            status: status,
            succeeded_at: succeeded_at,
            provider: "stripe",
            provider_id: charge_id,
            provider_charge_id: charge_id,
            provider_payment_intent_id: payment_intent_id
          ]
        )

      if status == :succeeded do
        bounty_ids = txs |> Enum.map(& &1.bounty_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
        tip_ids = txs |> Enum.map(& &1.tip_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
        contract_ids = txs |> Enum.map(& &1.contract_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
        claim_ids = txs |> Enum.map(& &1.claim_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()

        Repo.update_all(from(b in Bounty, where: b.id in ^bounty_ids), set: [status: :paid])
        Repo.update_all(from(t in Tip, where: t.id in ^tip_ids), set: [status: :paid])
        Repo.update_all(from(c in Contract, where: c.id in ^contract_ids), set: [status: :paid])
        # TODO: add and use a new "paid" status for claims
        Repo.update_all(from(c in Claim, where: c.id in ^claim_ids), set: [status: :approved])

        activities_result =
          txs
          |> Enum.filter(&(&1.type == :credit))
          |> Enum.reduce_while(:ok, fn tx, :ok ->
            case Repo.insert_activity(tx, %{type: :transaction_succeeded, notify_users: [tx.user_id]}) do
              {:ok, _} -> {:cont, :ok}
              error -> {:halt, error}
            end
          end)

        jobs_result =
          txs
          |> Enum.filter(&(&1.type == :credit))
          |> Enum.reduce_while(:ok, fn credit, :ok ->
            case Payments.fetch_active_account(credit.user_id) do
              {:ok, _account} ->
                case %{credit_id: credit.id}
                     |> Payments.Jobs.ExecutePendingTransfer.new()
                     |> Oban.insert() do
                  {:ok, _job} -> {:cont, :ok}
                  error -> {:halt, error}
                end

              {:error, :no_active_account} ->
                case %{credit_id: credit.id}
                     |> Bounties.Jobs.PromptPayoutConnect.new()
                     |> Oban.insert() do
                  {:ok, _job} -> {:cont, :ok}
                  error -> {:halt, error}
                end
            end
          end)

        with txs when txs != [] <- txs,
             :ok <- activities_result,
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
      else
        Payments.broadcast()
        {:ok, nil}
      end
    end)
  end

  defp alert(%Stripe.Event{} = event, :ok) do
    Algora.Admin.alert("Stripe event: #{event.type} #{event.id} https://dashboard.stripe.com/logs?success=true", :debug)
  end

  defp alert(%Stripe.Event{} = event, {:error, error}) do
    Algora.Admin.alert(
      "Stripe event: #{event.type} #{event.id} https://dashboard.stripe.com/logs?success=false Error: #{inspect(error)}",
      :error
    )
  end
end
