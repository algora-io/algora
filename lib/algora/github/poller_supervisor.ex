defmodule Algora.Github.PollerSupervisor do
  use DynamicSupervisor
  require Logger
  alias Algora.Events
  alias Algora.Github.Poller

  # Client API
  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_repo(owner, name, opts \\ []) do
    child_spec = %{
      id: "#{owner}/#{name}",
      start: {Poller, :start_link, [[repo_owner: owner, repo_name: name] ++ opts]}
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  # Supervisor callbacks
  @impl true
  def init(:ok) do
    {:ok, pid} = DynamicSupervisor.init(strategy: :one_for_one)
    {:ok, pid, {:continue, :start_active_pollers}}
  end

  @impl true
  def handle_continue(:start_active_pollers, state) do
    Events.list_active_event_pollers()
    |> Enum.each(fn poller -> add_repo(poller.repo_owner, poller.repo_name) end)

    {:noreply, state}
  end
end
