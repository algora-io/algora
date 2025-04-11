defmodule AlgoraWeb.Util do
  @moduledoc false

  use AlgoraWeb, :verified_routes
  use AlgoraWeb, :controller

  alias Phoenix.LiveView.JS

  require Logger

  def build_safe_redirect(url) do
    app_host = AlgoraWeb.Endpoint.host()

    uri = URI.parse(url)
    query = if uri.query, do: "?#{uri.query}", else: ""

    case uri do
      %URI{host: nil, path: nil} ->
        [to: ~p"/#{query}"]

      %URI{host: host, path: path} when is_nil(host) or host == app_host ->
        [to: "#{path}#{query}"]

      %URI{host: host} ->
        case host |> String.split(".") |> Enum.take(-2) |> Enum.join(".") do
          "algora.io" -> [external: url]
          "algora.tv" -> [external: url]
          "stripe.com" -> [external: url]
          "github.com" -> [external: url]
          _ -> [to: ~p"/#{query}"]
        end
    end
  rescue
    _error -> [to: ~p"/"]
  end

  def redirect_safe(conn, url) do
    redirect(conn, AlgoraWeb.Util.build_safe_redirect(url))
  end

  def transition(js \\ %JS{}, attr, eq, opts) do
    js
    |> JS.remove_class(opts[:to], to: "[#{attr}]:not([#{attr}='#{eq}'])")
    |> JS.add_class(opts[:from], to: "[#{attr}]:not([#{attr}='#{eq}'])")
    |> JS.add_class(opts[:to], to: "[#{attr}='#{eq}']")
  end

  def get_ip(socket) do
    Logger.warning(Phoenix.LiveView.get_connect_info(socket, :x_headers))

    socket
    |> Phoenix.LiveView.get_connect_info(:x_headers)
    |> Enum.filter(fn {header, _value} -> header == "x-forwarded-for" end)
    |> then(fn
      [{_header, value}] -> value |> String.split(",") |> Enum.at(-2)
      _other -> nil
    end)
  end
end
