defmodule Algora.Github.Poller.Comments do
  use GenServer
  import Ecto.Query, warn: false
  require Logger
  alias Algora.Comments
  alias Algora.Github
  alias Algora.Github.Command
  alias Algora.Repo

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

    {:ok,
     %{
       repo_owner: repo_owner,
       repo_name: repo_name,
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

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  def poll(state) do
    with {:ok, comments} <- fetch_comments(state),
         if(length(comments) > 0, do: Logger.debug("Processing #{length(comments)} comments")),
         {:ok, updated_cursor} <- process_batch(comments, state.cursor) do
      {:ok, %{state | cursor: updated_cursor}}
    end
  end

  defp process_batch([], comment_cursor), do: {:ok, comment_cursor}

  defp process_batch(comments, comment_cursor) do
    Repo.transact(fn ->
      with :ok <- process_comments(comments),
           {:ok, updated_cursor} <- update_last_polled(comment_cursor, List.last(comments)) do
        {:ok, updated_cursor}
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

  defp fetch_comments(state) do
    with token = Github.TokenPool.get_token(),
         {:ok, comments} <-
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

  def process_comment(%{"updated_at" => updated_at, "body" => body} = comment) do
    {:ok, updated_at, _} = DateTime.from_iso8601(updated_at)
    latency = DateTime.utc_now() |> DateTime.diff(updated_at, :second)
    Logger.info("Latency: #{latency}s")

    # TODO: ensure each command succeeds
    case Command.parse(body) do
      {:ok, commands} ->
        commands
        |> Enum.each(fn command ->
          encoded_command =
            command
            |> :erlang.term_to_binary()
            |> Base.encode64()

          dbg(command)

          # TODO: implement
          # %{comment: comment, command: encoded_command}
          # |> Github.Poller.CommentConsumer.new()
          # |> Oban.insert()
        end)

      {:error, _} ->
        Logger.error("Failed to parse commands from comment: #{inspect(comment)}")
        {:ok, nil}
    end
  end
end
