defmodule AlgoraWeb.Util do
  @moduledoc false

  use AlgoraWeb, :verified_routes
  use AlgoraWeb, :controller

  require Logger

  def build_safe_redirect(url) do
    app_host = AlgoraWeb.Endpoint.host()

    case URI.parse(url) do
      %URI{host: nil, path: nil} ->
        [to: ~p"/"]

      %URI{host: host, path: path} when is_nil(host) or host == app_host ->
        [to: path]

      %URI{host: host} ->
        case host |> String.split(".") |> Enum.take(-2) |> Enum.join(".") do
          "algora.io" -> [external: url]
          "algora.tv" -> [external: url]
          "stripe.com" -> [external: url]
          "github.com" -> [external: url]
          _ -> [to: ~p"/"]
        end
    end
  rescue
    _error -> [to: ~p"/"]
  end

  def redirect_safe(conn, url) do
    redirect(conn, AlgoraWeb.Util.build_safe_redirect(url))
  end
end
