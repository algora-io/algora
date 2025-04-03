defmodule AlgoraWeb.LocalStore do
  @moduledoc false
  use AlgoraWeb, :live_view

  require Logger

  defstruct [:key, :salt, :max_age, :ok?, :data]

  def init(opts) do
    struct!(__MODULE__, Keyword.put(opts, :data, %{}))
  end

  def init(socket, opts) do
    store = struct!(__MODULE__, Keyword.put(opts, :data, %{}))
    assign(socket, :_store, store)
  end

  def subscribe(socket) do
    if connected?(socket) do
      push_event(socket, "restore", %{key: socket.assigns._store.key, event: "restore_settings"})
    else
      socket
    end
  end

  def restore(socket, token) when is_binary(token) do
    store = socket.assigns._store

    case restore_from_token(store, token) do
      {:ok, nil} ->
        socket

      {:ok, data} ->
        if store.ok?.(data) do
          store = put_in(store.data, data)

          socket
          |> assign(:_store, store)
          |> then(fn socket ->
            Enum.reduce(data, socket, fn {key, value}, acc -> assign(acc, key, value) end)
          end)
        else
          Logger.error("Failed to restore previous state. State: #{inspect(data)}.")
          clear_browser_storage(socket)
        end

      {:error, reason} ->
        Logger.error("Failed to restore previous state. Reason: #{inspect(reason)}.")
        clear_browser_storage(socket)
    end
  end

  def restore(socket, _token), do: socket

  def assign_cached(socket, key, data) do
    store = socket.assigns._store

    socket
    |> assign(:_store, put_in(store.data[key], data))
    |> assign(key, data)
    |> save()
  end

  defp save(socket) do
    store = socket.assigns._store
    push_event(socket, "store", %{key: store.key, data: serialize_to_token(store)})
  end

  defp restore_from_token(_store, nil), do: {:ok, nil}

  defp restore_from_token(%__MODULE__{} = store, token) do
    case Phoenix.Token.decrypt(AlgoraWeb.Endpoint, store.salt, token, max_age: store.max_age) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, "Failed to restore previous state. Reason: #{inspect(reason)}."}
    end
  end

  defp serialize_to_token(%__MODULE__{} = store) do
    Phoenix.Token.encrypt(AlgoraWeb.Endpoint, store.salt, store.data)
  end

  defp clear_browser_storage(socket) do
    push_event(socket, "clear", %{key: socket.assigns._store.key})
  end
end
