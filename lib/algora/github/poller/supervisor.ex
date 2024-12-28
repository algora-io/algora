defmodule Algora.Github.Poller.Supervisor do
  use DynamicSupervisor
  require Logger
  alias Algora.Comments

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
    spec = %{
      id: "#{owner}/#{name}",
      start:
        {Algora.Github.Poller.Comments, :start_link,
         [[repo_owner: owner, repo_name: name] ++ opts]},
      restart: :permanent
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def pause_all do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} -> Algora.Github.Poller.Comments.pause(pid) end)
  end

  def resume_all do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} -> Algora.Github.Poller.Comments.resume(pid) end)
  end
end
