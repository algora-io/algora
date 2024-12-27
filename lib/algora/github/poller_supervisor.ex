defmodule Algora.Github.PollerSupervisor do
  use GenServer
  require Logger
  alias Algora.Events
  alias Algora.Github.Poller
  alias Algora.Users

  @total_tokens 100

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_token(supervisor) do
    GenServer.call(supervisor, :get_token)
  end

  def add_repo(owner, name, opts \\ []) do
    GenServer.call(__MODULE__, {:add_repo, owner, name, opts})
  end

  # Server callbacks
  @impl true
  def init(:ok) do
    repos = Events.list_active_pollers()
    tokens = Users.get_random_access_tokens(@total_tokens)

    {:ok, supervisor_pid} = Supervisor.start_link([], strategy: :one_for_one)

    Enum.each(repos, fn {owner, name} -> add_child(supervisor_pid, owner, name, self(), []) end)

    {:ok, %{tokens: tokens, current_token_index: 0, supervisor_pid: supervisor_pid}}
  end

  @impl true
  def handle_call(:get_token, _from, %{current_token_index: index, tokens: tokens} = state) do
    token = Enum.at(tokens, index)
    next_index = rem(index + 1, length(tokens))

    if next_index == 0, do: Process.send(self(), :refresh_tokens, [])

    {:reply, token, %{state | current_token_index: next_index}}
  end

  @impl true
  def handle_call(
        {:add_repo, owner, name, opts},
        _from,
        %{supervisor_pid: supervisor_pid} = state
      ) do
    case add_child(supervisor_pid, owner, name, self(), opts) do
      {:ok, _pid} -> {:reply, :ok, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(:refresh_tokens, state) do
    {:noreply,
     %{state | tokens: Users.get_random_access_tokens(@total_tokens), current_token_index: 0}}
  end

  defp add_child(supervisor_pid, owner, name, poller_supervisor, opts) do
    child_spec = %{
      id: "#{owner}/#{name}",
      start:
        {Poller, :start_link,
         [[repo_owner: owner, repo_name: name, supervisor: poller_supervisor] ++ opts]}
    }

    Supervisor.start_child(supervisor_pid, child_spec)
  end
end
