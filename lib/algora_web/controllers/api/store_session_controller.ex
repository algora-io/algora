defmodule AlgoraWeb.API.StoreSessionController do
  use AlgoraWeb, :controller

  require Logger

  def create(conn, %{"encrypted" => encrypted}) do
    updated_conn =
      case decrypt(encrypted) do
        {:ok, data} ->
          Enum.reduce(data, conn, fn {key, value}, acc_conn -> put_session(acc_conn, key, value) end)

        error ->
          Logger.error("Failed to decrypt session: #{inspect(error)}")
          conn
      end

    send_resp(updated_conn, 200, "")
  end

  def store_session(socket, data) do
    Phoenix.LiveView.push_event(socket, "store-session", %{encrypted: encrypt(data)})
  end

  defp default_ttl, do: Algora.config([:local_store, :ttl])
  defp salt, do: "store_session_controller" <> Algora.config([:local_store, :salt])

  defp encrypt(data) do
    Phoenix.Token.encrypt(AlgoraWeb.Endpoint, salt(), :erlang.term_to_binary(data), max_age: default_ttl())
  end

  defp decrypt(data) do
    case Phoenix.Token.decrypt(AlgoraWeb.Endpoint, salt(), data, max_age: default_ttl()) do
      {:ok, data} -> {:ok, :erlang.binary_to_term(data, [:safe])}
      error -> error
    end
  end
end
