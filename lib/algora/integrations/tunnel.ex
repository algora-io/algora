defmodule Algora.Tunnel do
  @moduledoc false
  use GenServer

  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(name) do
    {:ok, %{name: name}, {:continue, :start_tunnel}}
  end

  @impl true
  def handle_continue(:start_tunnel, %{name: name} = state) do
    start_tunnel(name)
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:data, {:eol, line}}}, %{port: port} = state) do
    Logger.debug("CLOUDFLARE #{line}")
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("Tunnel process exited with status #{status}")
    {:stop, :tunnel_failed, state}
  end

  defp start_tunnel(name) do
    http_config = Application.get_env(:algora, AlgoraWeb.Endpoint)[:http]
    host = "#{:inet.ntoa(http_config[:ip])}:#{http_config[:port]}"
    port = open_port("cloudflared", ["tunnel", "run", "--url", "http://#{host}", name])
    Logger.info("Running Cloudflare tunnel at #{host} (#{name})")
    GenServer.cast(self(), {:store_port, port})
  end

  defp open_port(cmd, args) do
    Port.open({:spawn_executable, System.find_executable(cmd)}, [
      :binary,
      :exit_status,
      {:line, 1024},
      :use_stdio,
      :stderr_to_stdout,
      args: args
    ])
  end

  @impl true
  def handle_cast({:store_port, port}, state) do
    {:noreply, Map.put(state, :port, port)}
  end
end
