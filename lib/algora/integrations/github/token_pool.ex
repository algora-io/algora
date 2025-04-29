defmodule Algora.Github.TokenPool do
  @moduledoc false
  use GenServer

  alias Algora.Accounts
  alias Algora.Github

  require Logger

  @pool_size 100

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_token do
    case maybe_get_token() do
      token when is_binary(token) -> token
      _ -> get_token()
    end
  end

  def maybe_get_token do
    GenServer.call(__MODULE__, :maybe_get_token)
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
    tokens = Accounts.get_random_access_tokens(@pool_size)
    {:noreply, %{state | tokens: tokens, current_token_index: 0}}
  end

  @impl true
  def handle_call(:maybe_get_token, _from, %{current_token_index: index, tokens: tokens} = state) do
    token = Enum.at(tokens, index)

    if token == nil do
      {:reply, Github.pat(), state}
    else
      next_index = rem(index + 1, length(tokens))
      if next_index == 0, do: refresh_tokens()

      case Github.get_current_user(token) do
        {:ok, _} ->
          dbg(token)
          dbg("token is valid")
          {:reply, token, %{state | current_token_index: next_index}}

        _ ->
          dbg("token is invalid")
          {:reply, nil, %{state | current_token_index: next_index}}
      end
    end
  end

  @impl true
  def handle_cast(:refresh_tokens, state) do
    {:noreply, %{state | tokens: Accounts.get_random_access_tokens(@pool_size), current_token_index: 0}}
  end
end
