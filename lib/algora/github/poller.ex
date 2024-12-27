defmodule Algora.Github.Poller do
  use GenServer
  import Ecto.Query, warn: false
  require Logger
  alias Algora.Events
  alias Algora.Github
  alias Algora.Github.Command
  alias Algora.Repo

  @per_page 10
  @poll_interval :timer.seconds(1)
  @default_backfill_limit 1

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get_token(supervisor) do
    GenServer.call(supervisor, :get_token)
  end

  # Server callbacks
  @impl true
  def init(opts) do
    repo_owner = Keyword.fetch!(opts, :repo_owner)
    repo_name = Keyword.fetch!(opts, :repo_name)
    supervisor = Keyword.fetch!(opts, :supervisor)
    backfill_limit = Keyword.get(opts, :backfill_limit, @default_backfill_limit)

    schedule_poll()

    {:ok,
     %{
       repo_owner: repo_owner,
       repo_name: repo_name,
       supervisor: supervisor,
       backfill_limit: backfill_limit
     }}
  end

  @impl true
  def handle_info(:poll, state) do
    token = get_token(state.supervisor)
    poll(token, state.repo_owner, state.repo_name, backfill_limit: state.backfill_limit)
    schedule_poll()
    {:noreply, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  def poll(token, repo_owner, repo_name, opts \\ []) do
    Logger.debug("Polling #{repo_owner}/#{repo_name} events")
    backfill_limit = Keyword.get(opts, :backfill_limit, @default_backfill_limit)

    with {:ok, event_poller} <- get_or_create_poller(repo_owner, repo_name),
         {:ok, events} <- collect_new_events(token, event_poller, backfill_limit),
         {:ok, _} <- process_batch(events, event_poller) do
      {:ok, nil}
    end
  end

  defp collect_new_events(token, event_poller, backfill_limit, page \\ 1, acc \\ []) do
    case fetch_events(token, event_poller, page) do
      {:ok, events} ->
        {new_events, _total_count, has_more} =
          Enum.reduce_while(
            events,
            {[], length(acc), true},
            fn event, {page_acc, total_count, _} ->
              has_more =
                cond do
                  # Stop when we hit last processed event
                  event["id"] == event_poller.last_event_id -> false
                  # Keep going if we're not in backfill mode
                  event_poller.last_event_id != nil -> true
                  # No limit for infinite backfill
                  backfill_limit == :infinity -> true
                  # Respect backfill limit during initial load
                  total_count + 1 > backfill_limit -> false
                  # Otherwise continue
                  true -> true
                end

              if has_more do
                {:cont, {[event | page_acc], total_count + 1, true}}
              else
                {:halt, {page_acc, total_count, false}}
              end
            end
          )

        acc = acc ++ Enum.reverse(new_events)

        if has_more do
          collect_new_events(token, event_poller, backfill_limit, page + 1, acc)
        else
          {:ok, acc}
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch repository events: #{inspect(reason)}")
        error
    end
  end

  defp process_batch([], _event_poller), do: {:ok, nil}

  defp process_batch(events, event_poller) do
    Repo.transact(fn ->
      with :ok <- process_events(events),
           {:ok, _} <- update_last_polled(event_poller, List.first(events)) do
        {:ok, nil}
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

  defp fetch_events(token, event_poller, page) do
    Github.list_repository_events(
      token,
      event_poller.repo_owner,
      event_poller.repo_name,
      per_page: @per_page,
      page: page
    )
  end

  defp get_or_create_poller(repo_owner, repo_name) do
    case Events.get_event_poller("github", repo_owner, repo_name) do
      nil ->
        Events.create_event_poller(%{
          provider: "github",
          repo_owner: repo_owner,
          repo_name: repo_name
        })

      event_poller ->
        {:ok, event_poller}
    end
  end

  defp update_last_polled(event_poller, %{"id" => event_id}) when not is_nil(event_id) do
    Events.update_event_poller(event_poller, %{
      last_event_id: event_id,
      last_polled_at: DateTime.utc_now()
    })
  end

  defp process_event(event) do
    body = extract_body(event)

    case Command.parse(body) do
      {:ok, commands} ->
        commands
        |> Enum.each(fn command ->
          encoded_command =
            command
            |> :erlang.term_to_binary()
            |> Base.encode64()

          %{event: event, command: encoded_command}
          |> Github.CommandWorker.new()
          |> Oban.insert()
        end)

      {:error, _} ->
        Logger.error("Failed to parse commands from event: #{inspect(event)}")
        {:ok, nil}
    end
  end

  defp extract_body(%{
         "type" => "IssueCommentEvent",
         "payload" => %{"comment" => %{"body" => body}}
       }) do
    body
  end

  defp extract_body(%{
         "type" => "IssuesEvent",
         "payload" => %{"issue" => %{"body" => body}}
       }) do
    body
  end

  defp extract_body(_event), do: nil
end
