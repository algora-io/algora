defmodule AlgoraWeb.RootController do
  use AlgoraWeb, :controller
  alias AlgoraWeb.UserAuth

  @dev_country_code "gr"
  @default_country_code "en"

  def index(%{assigns: %{current_user: nil}} = conn, _params) do
    ip_address = get_client_ip(conn)
    country_code = get_country_code(ip_address)
    redirect(conn, to: ~p"/#{String.downcase(country_code)}")
  end

  def index(conn, _params) do
    redirect(conn, to: UserAuth.signed_in_path(conn))
  end

  defp get_client_ip(conn), do: conn.remote_ip |> :inet.ntoa() |> to_string()

  defp get_country_code("127.0.0.1"), do: @dev_country_code

  defp get_country_code(ip) do
    url = "https://ipinfo.io/#{ip}?token=#{System.get_env("IPINFO_TOKEN")}"

    task = Task.async(fn -> Finch.build(:get, url) |> Finch.request(Algora.Finch) end)
    res = Task.yield(task, :timer.seconds(3)) || Task.shutdown(task)

    with {:ok, {:ok, %Finch.Response{status: 200, body: body}}} <- res,
         {:ok, decoded} <- Jason.decode(body),
         country when is_binary(country) <- Map.get(decoded, "country") do
      String.downcase(country)
    else
      _ -> @default_country_code
    end
  end
end
