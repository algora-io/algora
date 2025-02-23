defmodule AlgoraWeb.Webhooks.StripeController do
  @behaviour Stripe.WebhookHandler

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Bounties
  alias Algora.Payments
  alias Algora.Payments.Customer
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

      jobs_result =
        from(t in Transaction,
          where: t.group_id == ^group_id,
          where: t.type == :credit,
          where: t.status == :succeeded
        )
        |> Repo.all()
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

  @impl true
  def handle_event(%Stripe.Event{
        type: "checkout.session.completed",
        data: %{object: %Stripe.Session{customer: customer_id, mode: "setup", setup_intent: setup_intent_id}}
      }) do
    with {:ok, setup_intent} <- Algora.Stripe.SetupIntent.retrieve(setup_intent_id, %{}),
         pm_id = setup_intent.payment_method,
         {:ok, payment_method} <- Algora.Stripe.PaymentMethod.attach(%{payment_method: pm_id, customer: customer_id}),
         {:ok, customer} <- Repo.fetch_by(Customer, provider: "stripe", provider_id: customer_id),
         {:ok, _} <- Payments.create_payment_method(customer, payment_method) do
      Payments.broadcast()
      :ok
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
