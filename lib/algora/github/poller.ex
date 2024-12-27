defmodule Algora.Github.Poller do
  use GenServer
  import Ecto.Query, warn: false
  require Logger
  alias Algora.Events
  alias Algora.Github
  alias Algora.Github.Command

  @per_page 10
  @poll_interval :timer.seconds(1)

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

    schedule_poll()

    {:ok,
     %{
       repo_owner: repo_owner,
       repo_name: repo_name,
       supervisor: supervisor
     }}
  end

  @impl true
  def handle_info(:poll, state) do
    token = get_token(state.supervisor)
    poll(token, state.repo_owner, state.repo_name)
    schedule_poll()
    {:noreply, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  def poll(token, repo_owner, repo_name) do
    Logger.info("Polling #{repo_owner}/#{repo_name} events")

    {:ok, event_poller} = get_or_create_poller(repo_owner, repo_name)

    events_to_process = collect_new_events(token, event_poller)

    if events_to_process != [] do
      Algora.Repo.transact(fn ->
        process_events(events_to_process)
        update_last_polled(event_poller, List.first(events_to_process))
        {:ok, nil}
      end)
    else
      {:ok, nil}
    end
  end

  defp collect_new_events(token, event_poller, page \\ 1, acc \\ []) do
    {:ok, events} =
      Github.list_repository_events(token, event_poller.repo_owner, event_poller.repo_name,
        per_page: @per_page,
        page: page
      )

    {new_events, old_events} =
      Enum.split_while(events, fn event -> event["id"] != event_poller.last_event_id end)

    acc = acc ++ new_events

    cond do
      event_poller.last_event_id == nil -> acc |> Enum.take(1)
      old_events != [] -> acc
      length(events) < @per_page -> acc
      true -> collect_new_events(token, event_poller, page + 1, acc)
    end
  end

  defp process_events(events) do
    Enum.each(events, &process_event/1)
    {:ok, nil}
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

  defp update_last_polled(_event_poller, _), do: :ok

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
          |> Algora.Github.CommandWorker.new()
          |> Oban.insert()
        end)

      {:error, _} ->
        Logger.error("Failed to parse commands from event: #{inspect(event)}")
        :ok
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

  defp extract_body(%{"type" => type}), do: nil
end
