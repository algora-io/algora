defmodule Algora.Stargazer do
  @moduledoc false
  use GenServer

  alias Algora.Github
  alias AlgoraWeb.Constants

  require Logger

  @poll_interval :timer.minutes(10)

  def start_link(cmd) do
    GenServer.start_link(__MODULE__, cmd, name: __MODULE__)
  end

  @impl true
  def init(cmd) do
    {:ok, schedule_fetch(%{count: nil}, cmd, 0)}
  end

  @impl true
  def handle_info(cmd, state) do
    count = fetch_count() || state.count
    {:noreply, schedule_fetch(%{state | count: count}, cmd)}
  end

  defp schedule_fetch(state, cmd, after_ms \\ @poll_interval) do
    Process.send_after(self(), cmd, after_ms)
    state
  end

  def fetch_count do
    case Github.Client.fetch(nil, Constants.get(:github_repo_api_url)) do
      {:ok, %{"stargazers_count" => count}} -> count
      _ -> nil
    end
  end

  def count do
    GenServer.call(__MODULE__, :get_count)
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state.count, state}
  end
end
