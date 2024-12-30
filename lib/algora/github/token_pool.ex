defmodule Algora.Github.TokenPool do
  use GenServer
  require Logger
  alias Algora.Users

  @pool_size 100

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_token do
    GenServer.call(__MODULE__, :get_token)
  end

  def refresh_tokens do
    GenServer.cast(__MODULE__, :refresh_tokens)
  end

  # Server callbacks
  @impl true
  def init(:ok) do
    {:ok, %{tokens: nil, current_token_index: nil}, {:continue, :setup}}
  end

  @impl true
  def handle_continue(:setup, state) do
    tokens = Users.get_random_access_tokens(@pool_size)
    {:noreply, %{state | tokens: tokens, current_token_index: 0}}
  end

  @impl true
  def handle_call(:get_token, _from, %{current_token_index: index, tokens: tokens} = state) do
    token = Enum.at(tokens, index)

    if token == nil do
      {:reply, nil, state}
    else
      next_index = rem(index + 1, length(tokens))
      if next_index == 0, do: refresh_tokens()

      {:reply, token, %{state | current_token_index: next_index}}
    end
  end

  @impl true
  def handle_cast(:refresh_tokens, state) do
    {
      :noreply,
      if length(state.tokens) < @pool_size do
        state
      else
        %{state | tokens: Users.get_random_access_tokens(@pool_size), current_token_index: 0}
      end
    }
  end
end
