defmodule Algora.Github.Poller.Comments do
  @moduledoc false
  use GenServer

  import Ecto.Query, warn: false

  alias Algora.Comments
  alias Algora.Github
  alias Algora.Github.Command
  alias Algora.Parser
  alias Algora.Repo
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
    repo_owner = Keyword.fetch!(opts, :repo_owner)
    repo_name = Keyword.fetch!(opts, :repo_name)

    {:ok,
     %{
       repo_owner: repo_owner,
       repo_name: repo_name,
       cursor: nil,
       paused: not Algora.config([:auto_start_pollers])
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
  def handle_call(:get_repo_info, _from, state) do
    {:reply, {state.repo_owner, state.repo_name}, state}
  end

  @impl true
  def handle_call(:is_paused, _from, state) do
    {:reply, state.paused, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  def poll(state) do
    with {:ok, token} <- get_token(),
         {:ok, comments} <- fetch_comments(token, state),
         if(length(comments) > 0, do: Logger.debug("Processing #{length(comments)} comments")),
         {:ok, updated_cursor} <- process_batch(comments, state.cursor) do
      {:ok, %{state | cursor: updated_cursor}}
    else
      {:error, :no_token_available} ->
        Logger.warning("No token available, pausing poller")
        {:ok, %{state | paused: true}}

      {:error, reason} ->
        Logger.error("Failed to fetch comments: #{inspect(reason)}")
        {:ok, state}
    end
  end

  defp process_batch([], comment_cursor), do: {:ok, comment_cursor}

  defp process_batch(comments, comment_cursor) do
    Repo.transact(fn ->
      with :ok <- process_comments(comments) do
        update_last_polled(comment_cursor, List.last(comments))
      end
    end)
  end

  defp process_comments(comments) do
    Enum.reduce_while(comments, :ok, fn comment, _acc ->
      case process_comment(comment) do
        {:ok, _} -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp fetch_comments(token, state) do
    # TODO: ignore comments from bots and GITHUB_BOT_HANDLE
    with {:ok, comments} <-
           Github.list_repository_comments(
             token,
             state.repo_owner,
             state.repo_name,
             per_page: @per_page,
             since: DateTime.to_iso8601(state.cursor.timestamp),
             sort: "updated",
             direction: "asc"
           ) do
      {:ok, Enum.drop_while(comments, &(to_string(&1["id"]) == state.cursor.last_comment_id))}
    end
  end

  defp get_or_create_cursor(repo_owner, repo_name) do
    case Comments.get_comment_cursor("github", repo_owner, repo_name) do
      nil ->
        Comments.create_comment_cursor(%{
          provider: "github",
          repo_owner: repo_owner,
          repo_name: repo_name,
          timestamp: DateTime.utc_now()
        })

      comment_cursor ->
        {:ok, comment_cursor}
    end
  end

  defp update_last_polled(comment_cursor, %{"id" => id, "updated_at" => updated_at}) do
    with {:ok, updated_at, _} <- DateTime.from_iso8601(updated_at),
         {:ok, cursor} <-
           Comments.update_comment_cursor(comment_cursor, %{
             timestamp: updated_at,
             last_comment_id: to_string(id),
             last_polled_at: DateTime.utc_now()
           }) do
      {:ok, cursor}
    else
      {:error, reason} -> Logger.error("Failed to update comment cursor: #{inspect(reason)}")
    end
  end

  defp process_comment(%{"updated_at" => updated_at, "body" => body, "html_url" => html_url} = comment) do
    with {:ok, updated_at, _} <- DateTime.from_iso8601(updated_at),
         {:ok, [ticket_ref: ticket_ref], _, _, _, _} <- Parser.full_ticket_ref(html_url),
         {:ok, commands} <- Command.parse(body) do
      Logger.info("Latency: #{DateTime.diff(DateTime.utc_now(), updated_at, :second)}s")

      Enum.reduce_while(commands, :ok, fn command, _acc ->
        res =
          %{
            comment: comment,
            command: Util.term_to_base64(command),
            ticket_ref: Util.term_to_base64(ticket_ref)
          }
          |> Github.Poller.CommentConsumer.new()
          |> Oban.insert()

        case res do
          {:ok, _job} -> {:cont, :ok}
          error -> {:halt, error}
        end
      end)
    else
      {:error, reason} ->
        Logger.error("Failed to parse commands from comment: #{inspect(comment)}. Reason: #{inspect(reason)}")

        :ok
    end
  end

  defp get_token do
    case Github.TokenPool.get_token() do
      nil -> {:error, :no_token_available}
      token -> {:ok, token}
    end
  end
end
