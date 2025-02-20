defmodule AlgoraWeb.Plugs.GithubWebhooks do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  alias Plug.Conn

  @impl true
  def init(opts) do
    path_info = String.split(opts[:at], "/", trim: true)

    opts
    |> Map.new()
    |> Map.put_new(:path_info, path_info)
  end

  @impl true
  def call(%Conn{method: "POST", path_info: path_info} = conn, %{path_info: path_info} = _opts) do
    {:ok, webhook, conn} = Algora.Github.Webhook.new(conn)

    case AlgoraWeb.Webhooks.GithubController.handle_webhook(webhook) do
      :ok -> conn |> send_resp(200, "Webhook received.") |> halt()
      {:handle_error, reason} -> conn |> send_resp(400, reason) |> halt()
      _ -> conn |> send_resp(400, "Bad request.") |> halt()
    end
  end

  @impl true
  def call(%Conn{path_info: path_info} = conn, %{path_info: path_info}) do
    conn |> send_resp(400, "Bad request.") |> halt()
  end

  @impl true
  def call(conn, _), do: conn
end
