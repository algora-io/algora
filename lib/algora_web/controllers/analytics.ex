defmodule AlgoraWeb.Analytics do
  @moduledoc false
  import Plug.Conn

  @default_country_code "US"
  @country_code_key "current_country"
  @ipinfo_key "ipinfo"
  @loopback_geo_ip "127.0.0.1"
  @loopback_geo %{
    "continent" => "Europe",
    "continent_code" => "EU",
    "country" => "Germany",
    "country_code" => "DE"
  }

  def on_mount(:current_country, _params, session, socket) do
    socket =
      socket
      |> Phoenix.Component.assign(:current_country, session[@country_code_key])
      |> Phoenix.Component.assign(:ipinfo, session[@ipinfo_key])

    {:cont, socket}
  end

  def fetch_current_page(conn, _opts) do
    conn
    |> assign(:page_url, Path.join([AlgoraWeb.Endpoint.url(), conn.request_path]))
    |> assign(:page_image, Path.join([AlgoraWeb.Endpoint.url(), "og", conn.request_path]))
  end

  def fetch_current_country(conn, _opts) do
    country_in_session = get_session(conn, @country_code_key)
    ipinfo_in_session = get_session(conn, @ipinfo_key)

    cond do
      country_in_session == nil ->
        ip = get_client_ip(conn)
        ip_debug = debug_ip_headers(conn)

        case fetch_ipinfo(ip) do
          {:ok, data} ->
            country_code =
              data
              |> Map.get("country_code", @default_country_code)
              |> to_string()
              |> String.downcase()

            conn
            |> put_session(@country_code_key, country_code)
            |> put_session(@ipinfo_key, Map.merge(data, %{"_debug" => ip_debug}))
            |> assign(:current_country, country_code)

          {:error, _} ->
            country_code = String.downcase(@default_country_code)

            conn
            |> put_session(@country_code_key, country_code)
            |> put_session(@ipinfo_key, %{
              "ip" => ip,
              "error" => "ipinfo_request_failed",
              "current_country" => country_code,
              "_debug" => ip_debug
            })
            |> assign(:current_country, country_code)
        end

      # Returning sessions often have current_country from before we stored ipinfo;
      # backfill once so LiveView's on_mount gets a map instead of nil.
      ipinfo_in_session == nil ->
        ip = get_client_ip(conn)
        ip_debug = debug_ip_headers(conn)

        case fetch_ipinfo(ip) do
          {:ok, data} ->
            country_code =
              data
              |> Map.get("country_code", @default_country_code)
              |> to_string()
              |> String.downcase()

            conn
            |> put_session(@country_code_key, country_code)
            |> put_session(@ipinfo_key, Map.merge(data, %{"_debug" => ip_debug}))
            |> assign(:current_country, country_code)

          {:error, _} ->
            conn
            |> put_session(@ipinfo_key, %{
              "ip" => ip,
              "error" => "ipinfo_request_failed",
              "current_country" => country_in_session,
              "_debug" => ip_debug
            })
            |> assign(:current_country, country_in_session)
        end

      true ->
        assign(conn, :current_country, country_in_session)
    end
  end

  def get_current_country(conn) do
    case get_session(conn, @country_code_key) do
      nil -> String.downcase(@default_country_code)
      country_code -> country_code
    end
  end

  defp get_client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] ->
        forwarded
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  def debug_ip_headers(conn) do
    %{
      "x-forwarded-for" => get_req_header(conn, "x-forwarded-for"),
      "x-real-ip" => get_req_header(conn, "x-real-ip"),
      "remote_ip" => conn.remote_ip |> :inet.ntoa() |> to_string(),
      "resolved_client_ip" => get_client_ip(conn)
    }
  end

  def get_country_code(ip, default \\ nil) do
    case fetch_ipinfo(ip) do
      {:ok, %{"country_code" => cc}} when is_binary(cc) -> cc
      _ -> default
    end
  end

  defp fetch_ipinfo(ip) when is_binary(ip) do
    if loopback_ip_string?(ip) do
      {:ok, Map.put(@loopback_geo, "ip", ip)}
    else
      do_fetch_ipinfo(ip)
    end
  end

  defp fetch_ipinfo(_), do: {:error, :invalid_ip}

  defp do_fetch_ipinfo(ip) when is_binary(ip) do
    ip = normalize_loopback_for_geo_ip(ip)
    url = "https://api.ipinfo.io/lite/#{ip}?token=#{System.get_env("IPINFO_TOKEN")}"

    task = Task.async(fn -> :get |> Finch.build(url) |> Finch.request(Algora.Finch) end)
    res = Task.yield(task, to_timeout(second: 3)) || Task.shutdown(task)

    with {:ok, {:ok, %Finch.Response{status: 200, body: body}}} <- res,
         {:ok, decoded} <- Jason.decode(body),
         true <- is_map(decoded) do
      {:ok, decoded}
    else
      _ -> {:error, :ipinfo}
    end
  end

  defp loopback_ip_string?(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, addr} -> loopback_addr?(addr)
      {:error, _} -> false
    end
  end

  defp normalize_loopback_for_geo_ip(ip) when is_binary(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, addr} -> if(loopback_addr?(addr), do: @loopback_geo_ip, else: ip)
      {:error, _} -> ip
    end
  end

  defp loopback_addr?({127, _, _, _}), do: true
  defp loopback_addr?({0, 0, 0, 0, 0, 0, 0, 1}), do: true

  defp loopback_addr?({0, 0, 0, 0, 0, 65_535, high, low}) do
    <<a, _b, _c, _d>> = <<high::16, low::16>>
    a == 127
  end

  defp loopback_addr?(_), do: false
end
