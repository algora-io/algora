defmodule Algora.Github.Poller.Supervisor do
  use DynamicSupervisor
  require Logger
  alias Algora.Comments
  alias Algora.Github.Poller.Comments, as: CommentsPoller

  # Client API
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_children do
    Comments.list_cursors()
    |> Task.async_stream(
      fn cursor -> add_repo(cursor.repo_owner, cursor.repo_name) end,
      max_concurrency: 100,
      ordered: false
    )
    |> Stream.run()

    :ok
  end

  def add_repo(owner, name, opts \\ []) do
    spec = {CommentsPoller, [repo_owner: owner, repo_name: name] ++ opts}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(owner, name) do
    case find_child(owner, name) do
      {_id, pid, _type, _modules} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      nil -> {:error, :not_found}
    end
  end

  def remove_repo(owner, name) do
    with :ok <- terminate_child(owner, name),
         {:ok, _cursor} <- Comments.delete_comment_cursor("github", owner, name) do
      :ok
    end
  end

  def find_child(owner, name) do
    which_children()
    |> Enum.find(fn {_, pid, _, _} -> GenServer.call(pid, :get_repo_info) == {owner, name} end)
  end

  def pause(owner, name) do
    find_child(owner, name)
    |> case do
      {_, pid, _, _} -> CommentsPoller.pause(pid)
      nil -> {:error, :not_found}
    end
  end

  def resume(owner, name) do
    find_child(owner, name)
    |> case do
      {_, pid, _, _} -> CommentsPoller.resume(pid)
      nil -> {:error, :not_found}
    end
  end

  def pause_all do
    which_children() |> Enum.each(fn {_, pid, _, _} -> CommentsPoller.pause(pid) end)
  end

  def resume_all do
    which_children() |> Enum.each(fn {_, pid, _, _} -> CommentsPoller.resume(pid) end)
  end

  def which_children do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
