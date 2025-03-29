defmodule AlgoraWeb.API.OGRedirectController do
  use AlgoraWeb, :controller

  def redirect_to_org_path(conn, %{"org_handle" => org_handle, "asset" => asset} = params) do
    target_path =
      case {asset, params["status"]} do
        {"leaderboard.png", _} ->
          "/og/org/#{org_handle}/leaderboard"

        {"bounties.png", status} when not is_nil(status) ->
          "/og/org/#{org_handle}/bounties?status=#{status}"

        {"bounties.png", _} ->
          "/og/org/#{org_handle}/bounties"

        _ ->
          nil
      end

    if is_nil(target_path) do
      conn
      |> put_status(404)
      |> json(%{error: "Unknown asset: #{asset}"})
      |> halt()
    else
      conn
      |> redirect(to: target_path)
      |> halt()
    end
  end
end
