defmodule Algora.Github.Poller.Search do
  @moduledoc false
  use GenServer

  import Ecto.Query, warn: false

  alias Algora.Admin
  alias Algora.Github
  alias Algora.Github.Command
  alias Algora.Parser
  alias Algora.Repo
  alias Algora.Search
  alias Algora.Util

  require Logger

  @per_page 10
  @poll_interval :timer.seconds(3)

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
    {:ok, cursor} = get_or_create_cursor()
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
  def handle_cast(:resume, state) do
    schedule_poll()
    {:noreply, %{state | paused: false}}
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
    with {:ok, tickets} <- fetch_tickets(state),
         if(length(tickets) > 0, do: Logger.debug("Processing #{length(tickets)} tickets")),
         {:ok, updated_cursor} <- process_batch(tickets, state.cursor) do
      {:ok, %{state | cursor: updated_cursor}}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch tickets: #{inspect(reason)}")
        {:ok, state}
    end
  end

  defp process_batch([], search_cursor), do: {:ok, search_cursor}

  defp process_batch(tickets, search_cursor) do
    Repo.transact(fn ->
      with :ok <- process_tickets(tickets) do
        update_last_polled(search_cursor, List.last(tickets))
      end
    end)
  end

  defp process_tickets(tickets) do
    Enum.reduce_while(tickets, :ok, fn ticket, _acc ->
      case process_ticket(ticket) do
        {:ok, _} -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  def fetch_tickets(state) do
    case search("bounty", since: DateTime.to_iso8601(state.cursor.timestamp)) do
      {:ok, %{"data" => %{"search" => %{"nodes" => tickets}}}} ->
        {:ok, tickets}

      _ ->
        {:error, :no_tickets_found}
    end
  end

  defp get_or_create_cursor do
    case Search.get_search_cursor("github") do
      nil ->
        Search.create_search_cursor(%{provider: "github", timestamp: DateTime.utc_now()})

      search_cursor ->
        {:ok, search_cursor}
    end
  end

  defp update_last_polled(search_cursor, %{"updatedAt" => updated_at}) do
    with {:ok, updated_at, _} <- DateTime.from_iso8601(updated_at),
         {:ok, cursor} <-
           Search.update_search_cursor(search_cursor, %{
             timestamp: updated_at,
             last_polled_at: DateTime.utc_now()
           }) do
      {:ok, cursor}
    else
      {:error, reason} -> Logger.error("Failed to update search cursor: #{inspect(reason)}")
    end
  end

  defp process_ticket(%{"updatedAt" => updated_at, "url" => url} = ticket, state) do
    dbg(ticket)

    with {:ok, updated_at, _} <- DateTime.from_iso8601(updated_at),
         {:ok, [ticket_ref: ticket_ref], _, _, _, _} <- Parser.full_ticket_ref(url) do
      Logger.info("Latency: #{DateTime.diff(DateTime.utc_now(), updated_at, :second)}s")

      ticket["comments"]["nodes"]
      |> Enum.reject(fn comment ->
        comment["author"]["login"] == Github.bot_handle() or
          DateTime.before?(updated_at, state.cursor.timestamp)
      end)
      |> Enum.flat_map(fn comment ->
        dbg(comment)

        case Command.parse(comment["body"]) do
          {:ok, [command | _]} -> [{comment, command}]
          _ -> []
        end
      end)
      |> Enum.reduce_while(:ok, fn {comment, command}, _acc ->
        res =
          %{
            comment: comment,
            command: Util.term_to_base64(command),
            ticket_ref: Util.term_to_base64(ticket_ref)
          }
          |> Github.Poller.SearchConsumer.new()
          |> Oban.insert()

        case res do
          {:ok, _job} -> {:cont, :ok}
          error -> {:halt, error}
        end
      end)
    else
      {:error, reason} ->
        Logger.error("Failed to parse commands from ticket: #{inspect(ticket)}. Reason: #{inspect(reason)}")

        :ok
    end
  end

  def search(q, opts \\ []) do
    per_page = opts[:per_page] || 10
    since = opts[:since]

    search_query =
      if opts[:since] do
        "#{q} in:comment is:issue repo:acme-incorporated/webapp sort:updated-asc updated:>#{opts[:since]}"
      else
        "#{q} in:comment is:issue repo:acme-incorporated/webapp sort:updated-asc"
      end

    dbg(search_query)

    query = """
    query issues($search_query: String!) {
      search(first: #{per_page}, type: ISSUE, query: $search_query) {
        issueCount
        pageInfo {
          hasNextPage
        }
        nodes {
          __typename
          ... on Issue {
            url
            updatedAt
            comments(last: 3, orderBy: {field: UPDATED_AT, direction: DESC}) {
              nodes {
                databaseId
                author {
                  login
                }
                body
              }
            }
          }
        }
      }
    }
    """

    body = %{query: query, variables: %{search_query: search_query}}
    Github.Client.fetch(Admin.token!(), "/graphql", "POST", body)
  end
end
