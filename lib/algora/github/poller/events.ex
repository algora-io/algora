defmodule Algora.Github.Poller.Events do
  use GenServer
  import Ecto.Query, warn: false
  require Logger
  alias Algora.Events
  alias Algora.Github
  alias Algora.Github.Command
  alias Algora.Repo
  alias Algora.Util

  @per_page 10
  @poll_interval :timer.seconds(1)

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
    repo_owner = Keyword.fetch!(opts, :repo_owner)
    repo_name = Keyword.fetch!(opts, :repo_name)
    backfill_limit = Keyword.get(opts, :backfill_limit, 1)

    {:ok,
     %{
       repo_owner: repo_owner,
       repo_name: repo_name,
       backfill_limit: backfill_limit,
       cursor: nil,
       paused: Mix.env() == :dev
     }, {:continue, :setup}}
  end

  @impl true
  def handle_continue(:setup, state) do
    {:ok, cursor} = get_or_create_cursor(state.repo_owner, state.repo_name)
    schedule_poll()

    {:noreply, %{state | cursor: cursor}}
  end

  @impl true
  def handle_info(:poll, %{paused: true} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, state) do
    token = Github.TokenPool.get_token()
    {:ok, new_state} = poll(token, state)
    schedule_poll()
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:pause, state) do
    {:noreply, %{state | paused: true}}
  end

  @impl true
  def handle_cast(:resume, state) do
    schedule_poll()
    {:noreply, %{state | paused: false}}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  def poll(token, state) do
    with {:ok, events} <- collect_new_events(token, state),
         if(length(events) > 0, do: Logger.debug("Processing #{length(events)} events")),
         {:ok, updated_cursor} <- process_batch(events, state.cursor) do
      {:ok, %{state | cursor: updated_cursor}}
    end
  end

  defp filter_new_events(events, acc, state) do
    {new_events, _total_count, has_more?} =
      Enum.reduce_while(
        events,
        {[], length(acc), true},
        fn event, {page_acc, total_count, _} ->
          case should_continue_processing?(event, state, total_count) do
            true -> {:cont, {[event | page_acc], total_count + 1, true}}
            false -> {:halt, {page_acc, total_count, false}}
          end
        end
      )

    {Enum.reverse(new_events), has_more?}
  end

  defp should_continue_processing?(event, state, total_count) do
    cond do
      event["id"] == state.cursor.last_event_id -> false
      state.cursor.last_event_id != nil -> true
      state.backfill_limit == :infinity -> true
      total_count + 1 > state.backfill_limit -> false
      true -> true
    end
  end

  defp collect_new_events(token, state, page \\ 1, acc \\ []) do
    case fetch_events(token, state, page) do
      {:ok, events} ->
        {new_events, has_more?} = filter_new_events(events, acc, state)
        acc = acc ++ new_events

        if has_more? do
          collect_new_events(token, state, page + 1, acc)
        else
          {:ok, acc}
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch repository events: #{inspect(reason)}")
        error
    end
  end

  defp process_batch([], event_cursor), do: {:ok, event_cursor}

  defp process_batch(events, event_cursor) do
    Repo.transact(fn ->
      with :ok <- process_events(events),
           {:ok, updated_cursor} <- update_last_polled(event_cursor, List.first(events)) do
        {:ok, updated_cursor}
      end
    end)
  end

  defp process_events(events) do
    Enum.reduce_while(events, :ok, fn event, _acc ->
      case process_event(event) do
        {:ok, _} -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp fetch_events(token, state, page) do
    Github.list_repository_events(
      token,
      state.repo_owner,
      state.repo_name,
      per_page: @per_page,
      page: page
    )
  end

  defp get_or_create_cursor(repo_owner, repo_name) do
    case Events.get_event_cursor("github", repo_owner, repo_name) do
      nil ->
        Events.create_event_cursor(%{
          provider: "github",
          repo_owner: repo_owner,
          repo_name: repo_name
        })

      event_cursor ->
        {:ok, event_cursor}
    end
  end

  defp update_last_polled(event_cursor, %{"id" => event_id}) when not is_nil(event_id) do
    Events.update_event_cursor(event_cursor, %{
      last_event_id: event_id,
      last_polled_at: DateTime.utc_now()
    })
  end

  defp process_event(%{"updated_at" => updated_at} = event) do
    with {:ok, updated_at, _} <- DateTime.from_iso8601(updated_at),
         body = extract_body(event),
         {:ok, commands} <- Command.parse(body) do
      Logger.info("Latency: #{DateTime.diff(DateTime.utc_now(), updated_at, :second)}s")

      Enum.reduce_while(commands, :ok, fn command, _acc ->
        res =
          %{event: event, command: Util.term_to_base64(command)}
          |> Github.Poller.EventConsumer.new()
          |> Oban.insert()

        case res do
          {:ok, _job} -> {:cont, :ok}
          error -> {:halt, error}
        end
      end)
    else
      {:error, reason} ->
        Logger.error(
          "Failed to parse commands from event: #{inspect(event)}. Reason: #{inspect(reason)}"
        )

        :ok
    end
  end

  defp extract_body(%{
         "type" => "IssueCommentEvent",
         "payload" => %{
           "action" => action,
           "comment" => %{"body" => body}
         }
       })
       when action in ["created", "edited"] do
    body
  end

  defp extract_body(%{
         "type" => "IssuesEvent",
         "payload" => %{
           "action" => action,
           "issue" => %{"body" => body}
         }
       })
       when action in ["opened", "edited"] do
    body
  end

  defp extract_body(_event), do: nil
end
