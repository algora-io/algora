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
  alias Algora.Workspace

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
    with {:ok, tickets} <- fetch_tickets(state),
         if(length(tickets) > 0, do: Logger.debug("Processing #{length(tickets)} tickets")),
         {:ok, updated_cursor} <- process_batch(tickets, state) do
      {:ok, %{state | cursor: updated_cursor}}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch tickets: #{inspect(reason)}")
        {:ok, state}
    end
  end

  defp process_batch([], state), do: {:ok, state.cursor}

  defp process_batch(tickets, state) do
    Repo.transact(fn ->
      with :ok <- process_tickets(tickets, state) do
        timestamps =
          tickets
          |> Enum.flat_map(fn ticket -> ticket["comments"]["nodes"] end)
          |> Enum.flat_map(fn comment ->
            case DateTime.from_iso8601(comment["updatedAt"]) do
              {:ok, updated_at, _} -> [updated_at]
              _ -> []
            end
          end)

        fallback_timestamp = DateTime.truncate(DateTime.utc_now(), :second)

        timestamp =
          case timestamps do
            [] -> fallback_timestamp
            timestamps -> Enum.max(timestamps)
          end

        if DateTime.after?(timestamp, state.cursor.timestamp) do
          update_last_polled(state.cursor, timestamp)
        else
          update_last_polled(state.cursor, fallback_timestamp)
        end
      end
    end)
  end

  defp process_tickets(tickets, state) do
    Enum.reduce_while(tickets, :ok, fn ticket, _acc ->
      case process_ticket(ticket, state) do
        {:ok, _} -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp fetch_tickets(state) do
    case search("bounty", since: DateTime.to_iso8601(state.cursor.timestamp), per_page: @per_page) do
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

  defp update_last_polled(search_cursor, timestamp) do
    case Search.update_search_cursor(search_cursor, %{
           timestamp: timestamp,
           last_polled_at: DateTime.utc_now()
         }) do
      {:ok, cursor} -> {:ok, cursor}
      {:error, reason} -> Logger.error("Failed to update search cursor: #{inspect(reason)}")
    end
  end

  defp process_ticket(%{"updatedAt" => updated_at, "url" => url} = ticket, state) do
    with {:ok, updated_at, _} <- DateTime.from_iso8601(updated_at),
         {:ok, [ticket_ref: ticket_ref], _, _, _, _} <- Parser.full_ticket_ref(url) do
      Logger.info("Latency: #{DateTime.diff(DateTime.utc_now(), updated_at, :second)}s")

      installation_token =
        if installation_id = Workspace.get_installation_id_by_owner(ticket_ref[:owner]) do
          case Github.get_installation_token(installation_id) do
            {:ok, token} -> token
            _error -> nil
          end
        end

      ticket["comments"]["nodes"]
      |> Enum.reject(fn comment ->
        already_processed? =
          case DateTime.from_iso8601(comment["updatedAt"]) do
            {:ok, comment_updated_at, _} ->
              not DateTime.after?(comment_updated_at, state.cursor.timestamp)

            {:error, _} ->
              true
          end

        bot? = comment["author"]["login"] == Github.bot_handle()

        blocked? = comment["author"]["login"] in Algora.Settings.get_blocked_users()

        if blocked? do
          Admin.alert(
            "Skipping slash command from blocked user #{comment["author"]["login"]}. URL: #{comment["url"]}",
            :debug
          )
        end

        not is_nil(installation_token) or bot? or already_processed? or blocked?
      end)
      |> Enum.flat_map(fn comment ->
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

  defp search(q, opts) do
    per_page = opts[:per_page] || @per_page

    search_query =
      if since = opts[:since] do
        "#{q} in:comment is:issue sort:updated-asc updated:>#{since}"
      else
        "#{q} in:comment is:issue sort:updated-asc"
      end

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
            comments(first: 3, orderBy: {field: UPDATED_AT, direction: DESC}) {
              nodes {
                updatedAt
                databaseId
                author {
                  login
                  }
                body
                url
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
