defmodule AlgoraWeb.RepoController do
  use AlgoraWeb, :controller

  alias Algora.Accounts.User
  alias Algora.Repo

  def index(conn, %{"repo_owner" => repo_owner, "repo_name" => repo_name}) do
    user = Repo.get_by(User, provider: "github", provider_login: repo_owner)

    case user do
      %{handle: handle} when is_binary(handle) ->
        dbg("redirecting to #{~p"/#{handle}"}")
        redirect(conn, to: ~p"/#{handle}")

      _ ->
        dbg("redirecting to #{~p"/go/#{repo_owner}/#{repo_name}"}")
        redirect(conn, to: ~p"/go/#{repo_owner}/#{repo_name}")
    end
  end
end
