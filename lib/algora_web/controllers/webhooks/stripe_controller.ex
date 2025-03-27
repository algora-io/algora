defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Activities.SendDiscord
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
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
        notify_event(event, :ok)
        :ok

      {:error, reason} ->
        Logger.error("❌ #{inspect(event.type)}: #{inspect(reason)}")
        notify_event(event, {:error, reason})
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("❌ #{inspect(event.type)}: #{inspect(error)}")
      notify_event(event, {:error, error})
      {:error, error}
  end

  @tracked_events ["charge.succeeded", "transfer.created", "checkout.session.completed"]

  defp process_event(
         %Stripe.Event{
           type: "charge.succeeded",
           data: %{object: %Stripe.Charge{metadata: %{"version" => @metadata_version, "group_id" => group_id}}}
         } = event
       )
       when is_binary(group_id) do
    process_charge_succeeded(event, group_id)
  end

  defp process_event(
         %Stripe.Event{type: "charge.succeeded", data: %{object: %Stripe.Charge{invoice: invoice_id}}} = event
       ) do
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

  defp process_event(%Stripe.Event{type: type} = event) when type in @tracked_events do
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

  defp process_charge_succeeded(%Stripe.Event{type: "charge.succeeded"}, group_id) when is_binary(group_id) do
    Repo.transact(fn ->
      {_, txs} =
        Repo.update_all(from(t in Transaction, where: t.group_id == ^group_id, select: t),
          set: [status: :succeeded, succeeded_at: DateTime.utc_now()]
        )

      bounty_ids = txs |> Enum.map(& &1.bounty_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
      tip_ids = txs |> Enum.map(& &1.tip_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()
      contract_ids = txs |> Enum.map(& &1.contract_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()

      Repo.update_all(from(b in Bounty, where: b.id in ^bounty_ids), set: [status: :paid])
      Repo.update_all(from(t in Tip, where: t.id in ^tip_ids), set: [status: :paid])
      Repo.update_all(from(c in Contract, where: c.id in ^contract_ids), set: [status: :paid])

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
    end)
  end

  defp notify_event(%Stripe.Event{} = event, :ok) do
    discord_payload = %{
      payload: %{
        embeds: [
          %{
            color: 0x64748B,
            title: event.type,
            footer: %{
              text: "Stripe",
              icon_url: "https://github.com/stripe.png"
            },
            fields: [
              %{
                name: "Event",
                value: event.id,
                inline: true
              },
              %{
                name: event.data.object.object,
                value: event.data.object.id,
                inline: true
              }
            ],
            url: "https://dashboard.stripe.com/payments?status[0]=successful",
            timestamp: DateTime.utc_now()
          }
        ]
      }
    }

    case discord_payload |> SendDiscord.changeset() |> Oban.insert() do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Error sending discord notification: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp notify_event(%Stripe.Event{} = event, {:error, error}) do
    discord_payload = %{
      payload: %{
        embeds: [
          %{
            color: 0xEF4444,
            title: event.type,
            description: inspect(error),
            footer: %{
              text: "Stripe",
              icon_url: "https://github.com/stripe.png"
            },
            fields: [
              %{
                name: "Event",
                value: event.id,
                inline: true
              },
              %{
                name: event.data.object.object,
                value: event.data.object.id,
                inline: true
              }
            ],
            url: "https://dashboard.stripe.com/payments?status[0]=failed",
            timestamp: DateTime.utc_now()
          }
        ]
      }
    }

    case discord_payload |> SendDiscord.changeset() |> Oban.insert() do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Error sending discord notification: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
