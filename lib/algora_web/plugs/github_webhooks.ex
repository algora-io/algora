defmodule AlgoraWeb.Plugs.GithubWebhooks do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  alias Algora.Github.Webhook
  alias AlgoraWeb.Webhooks.GithubController
  alias Plug.Conn

  require Logger

  @impl true
  def init(opts) do
    path_info = String.split(opts[:at], "/", trim: true)

    opts
    |> Map.new()
    |> Map.put_new(:path_info, path_info)
  end

  @impl true
  def call(%Conn{method: "POST", path_info: path_info} = conn, %{path_info: path_info} = _opts) do
    with {:ok, webhook, conn} <- Webhook.new(conn),
         :ok <- GithubController.process_delivery(webhook) do
      conn |> send_resp(200, "Webhook received.") |> halt()
    else
      {:error, :bot_event} ->
        conn |> send_resp(200, "Webhook received.") |> halt()

      {:error, :missing_header} ->
        Logger.error("Missing header")
        conn |> send_resp(400, "Bad request.") |> halt()

      {:error, :signature_mismatch} ->
        Logger.error("Signature mismatch")
        conn |> send_resp(400, "Bad request.") |> halt()

      error ->
        Logger.error("Bad request: #{inspect(error)}")
        conn |> send_resp(400, "Bad request.") |> halt()
    end
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))
      conn |> send_resp(400, "Bad request.") |> halt()
  end

  @impl true
  def call(%Conn{path_info: path_info} = conn, %{path_info: path_info}) do
    conn |> send_resp(400, "Bad request.") |> halt()
  end

  @impl true
  def call(conn, _), do: conn
end
