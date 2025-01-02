defmodule Algora.Stargazer do
  @moduledoc false
  use GenServer

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

  defp fetch_count do
    with {:ok, %Finch.Response{status: 200, body: body}} <-
           :get
           |> Finch.build(AlgoraWeb.Constants.get(:github_repo_url))
           |> Finch.request(Algora.Finch),
         {:ok, %{"stargazers_count" => count}} <- Jason.decode(body) do
      count
    else
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
