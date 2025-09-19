defmodule AlgoraWeb.Analytics do
  @moduledoc false
  import Plug.Conn

  @dev_country_code "US"
  @default_country_code "US"
  @country_code_key "current_country"

  def on_mount(:current_country, _params, session, socket) do
    {:cont, Phoenix.Component.assign(socket, :current_country, session[@country_code_key])}
  end

  def fetch_current_page(conn, _opts) do
    conn
    |> assign(:page_url, Path.join([AlgoraWeb.Endpoint.url(), conn.request_path]))
    |> assign(:page_image, Path.join([AlgoraWeb.Endpoint.url(), "og", conn.request_path]))
  end

  def fetch_current_country(conn, _opts) do
    country_code = get_current_country(conn)

    conn
    |> put_session(@country_code_key, country_code)
    |> assign(:current_country, country_code)
  end

  def get_current_country(conn) do
    case get_session(conn, @country_code_key) do
      nil ->
        conn
        |> get_client_ip()
        |> get_country_code(@default_country_code)
        |> String.downcase()

      country_code ->
        country_code
    end
  end

  defp get_client_ip(conn), do: conn.remote_ip |> :inet.ntoa() |> to_string()

  def get_country_code("127.0.0.1"), do: @dev_country_code

  def get_country_code(ip, default \\ nil) do
    url = "https://api.ipinfo.io/lite/#{ip}?token=#{System.get_env("IPINFO_TOKEN")}"

    task = Task.async(fn -> :get |> Finch.build(url) |> Finch.request(Algora.Finch) end)
    res = Task.yield(task, to_timeout(second: 3)) || Task.shutdown(task)

    with {:ok, {:ok, %Finch.Response{status: 200, body: body}}} <- res,
         {:ok, decoded} <- Jason.decode(body),
         country when is_binary(country) <- Map.get(decoded, "country_code") do
      country
    else
      _ -> default
    end
  end
end
