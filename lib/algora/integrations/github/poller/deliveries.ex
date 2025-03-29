defmodule Algora.Github.Poller.Deliveries do
  @moduledoc false
  use GenServer

  import Ecto.Query, warn: false

  alias Algora.Github
  alias Algora.Repo
  alias Algora.Sync

  require Logger

  @per_page 100
  @poll_interval :timer.seconds(10)

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def pause(pid) do
    GenServer.cast(pid, :pause)
  end

  def resume(pid) do
    GenServer.cast(pid, :resume)
  end

  # Server callbacks
  @impl true
  def init(opts) do
    provider = Keyword.fetch!(opts, :provider)

    {:ok,
     %{
       provider: provider,
       cursor: nil,
       paused: not Algora.config([:auto_start_pollers])
     }, {:continue, :setup}}
  end

  @impl true
  def handle_continue(:setup, state) do
    {:ok, cursor} = get_or_create_cursor(state.provider, "deliveries")
    schedule_poll()

    {:noreply, %{state | cursor: cursor}}
  end

  @impl true
  def handle_info(:poll, %{paused: true} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, state) do
    {:ok, new_state} = poll(state)
    schedule_poll()
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:pause, state) do
    {:noreply, %{state | paused: true}}
  end

  @impl true
  def handle_cast(:resume, %{paused: true} = state) do
    schedule_poll()
    {:noreply, %{state | paused: false}}
  end

  @impl true
  def handle_cast(:resume, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_provider, _from, state) do
    {:reply, state.provider, state}
  end

  @impl true
  def handle_call(:is_paused, _from, state) do
    {:reply, state.paused, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  def poll(state) do
    with {:ok, deliveries} <- fetch_deliveries(state),
         if(length(deliveries) > 0, do: Logger.info("Processing #{length(deliveries)} deliveries")),
         {:ok, updated_cursor} <- process_batch(deliveries, state) do
      {:ok, %{state | cursor: updated_cursor}}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch deliveries: #{inspect(reason)}")
        {:ok, state}
    end
  end

  defp process_batch([], state), do: {:ok, state.cursor}

  defp process_batch(deliveries, state) do
    Repo.transact(fn ->
      with :ok <- process_deliveries(deliveries, state) do
        update_last_polled(state.cursor, List.first(deliveries))
      end
    end)
  end

  defp process_deliveries(deliveries, state) do
    Enum.reduce_while(deliveries, :ok, fn delivery, _acc ->
      case process_delivery(delivery, state) do
        {:ok, _} -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp fetch_deliveries(_state) do
    # TODO: paginate via the next and previous page cursors in the link header
    Github.list_deliveries(per_page: @per_page)
  end

  defp get_or_create_cursor(provider, resource) do
    case Sync.get_sync_cursor(provider, resource) do
      nil ->
        Sync.create_sync_cursor(%{provider: provider, resource: resource, timestamp: DateTime.utc_now()})

      sync_cursor ->
        {:ok, sync_cursor}
    end
  end

  defp update_last_polled(sync_cursor, %{"delivered_at" => timestamp}) do
    with {:ok, timestamp, _} <- DateTime.from_iso8601(timestamp),
         {:ok, cursor} <-
           Sync.update_sync_cursor(sync_cursor, %{
             timestamp: timestamp,
             last_polled_at: DateTime.utc_now()
           }) do
      {:ok, cursor}
    else
      {:error, reason} -> Logger.error("Failed to update sync cursor: #{inspect(reason)}")
    end
  end

  defp process_delivery(delivery, state) do
    case DateTime.from_iso8601(delivery["delivered_at"]) do
      {:ok, delivered_at, _} ->
        skip_reason =
          cond do
            not DateTime.after?(delivered_at, state.cursor.timestamp) -> :already_processed
            delivery["status_code"] < 400 -> :status_ok
            true -> nil
          end

        if skip_reason do
          {:ok, nil}
        else
          dbg("Enqueuing redelivery #{delivery["id"]}")

          %{delivery: delivery}
          |> Github.Poller.DeliveryConsumer.new()
          |> Oban.insert()
        end

      {:error, reason} ->
        Logger.error("Failed to parse delivery: #{inspect(delivery)}. Reason: #{inspect(reason)}")

        {:ok, nil}
    end
  end
end
