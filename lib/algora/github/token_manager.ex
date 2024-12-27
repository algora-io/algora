defmodule Algora.Github.TokenPool do
  use GenServer
  require Logger
  alias Algora.Users

  @total_tokens 100

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_token do
    GenServer.call(__MODULE__, :get_token)
  end

  # Server callbacks
  @impl true
  def init(:ok) do
    tokens = Users.get_random_access_tokens(@total_tokens)
    {:ok, %{tokens: tokens, current_token_index: 0}}
  end

  @impl true
  def handle_call(:get_token, _from, %{current_token_index: index, tokens: tokens} = state) do
    token = Enum.at(tokens, index)
    next_index = rem(index + 1, length(tokens))

    if next_index == 0 do
      Process.send(self(), :refresh_tokens, [])
    end

    {:reply, token, %{state | current_token_index: next_index}}
  end

  @impl true
  def handle_info(:refresh_tokens, state) do
    {:noreply,
     %{state | tokens: Users.get_random_access_tokens(@total_tokens), current_token_index: 0}}
  end
end
