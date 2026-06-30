defmodule Algora.DeploymentHealth do
  @moduledoc """
  Tracks whether this node should receive new traffic during deployments.
  """

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, true, name: __MODULE__)
  end

  def healthy? do
    GenServer.call(__MODULE__, :healthy?)
  end

  def down do
    GenServer.cast(__MODULE__, :down)
  end

  def up do
    GenServer.cast(__MODULE__, :up)
  end

  @impl true
  def init(healthy?) do
    {:ok, healthy?}
  end

  @impl true
  def handle_call(:healthy?, _from, healthy?) do
    {:reply, healthy?, healthy?}
  end

  @impl true
  def handle_cast(:down, _healthy?) do
    {:noreply, false}
  end

  @impl true
  def handle_cast(:up, _healthy?) do
    {:noreply, true}
  end
end
