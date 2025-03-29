defmodule Algora.Github.Poller.SearchSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Algora.Github.Poller.Search, as: SearchPoller
  alias Algora.Search

  require Logger

  # Client API
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_children do
    Search.list_cursors()
    |> Task.async_stream(
      fn cursor -> add_provider(cursor.provider) end,
      max_concurrency: 100,
      ordered: false
    )
    |> Stream.run()

    :ok
  end

  def add_provider(provider \\ "github", opts \\ []) do
    DynamicSupervisor.start_child(__MODULE__, {SearchPoller, [provider: provider] ++ opts})
  end

  def terminate_child(provider) do
    case find_child(provider) do
      {_id, pid, _type, _modules} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      nil -> {:error, :not_found}
    end
  end

  def remove_provider(provider \\ "github") do
    with :ok <- terminate_child(provider),
         {:ok, _cursor} <- Search.delete_search_cursor(provider) do
      :ok
    end
  end

  def find_child(provider) do
    Enum.find(which_children(), fn {_, pid, _, _} ->
      GenServer.call(pid, :get_provider) == provider
    end)
  end

  def pause(provider) do
    provider
    |> find_child()
    |> case do
      {_, pid, _, _} -> SearchPoller.pause(pid)
      nil -> {:error, :not_found}
    end
  end

  def resume(provider) do
    provider
    |> find_child()
    |> case do
      {_, pid, _, _} -> SearchPoller.resume(pid)
      nil -> {:error, :not_found}
    end
  end

  def pause_all do
    Enum.each(which_children(), fn {_, pid, _, _} -> SearchPoller.pause(pid) end)
  end

  def resume_all do
    Enum.each(which_children(), fn {_, pid, _, _} -> SearchPoller.resume(pid) end)
  end

  def which_children do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
