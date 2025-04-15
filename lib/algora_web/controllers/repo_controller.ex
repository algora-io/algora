defmodule AlgoraWeb.RepoController do
  use AlgoraWeb, :controller

  alias Algora.Accounts.User
  alias Algora.Repo
  alias Algora.Workspace
  alias Algora.Workspace.InvalidRepoCache

  def index(conn, %{"repo_owner" => repo_owner, "repo_name" => repo_name}) do
    case Repo.get_by(User, provider: "github", provider_login: repo_owner) do
      %{handle: handle} when is_binary(handle) ->
        redirect(conn, to: ~p"/#{handle}")

      _ ->
        if InvalidRepoCache.invalid_repo?(repo_owner, repo_name) do
          raise AlgoraWeb.NotFoundError
        end

        case Workspace.ensure_repository(Algora.Admin.token(), repo_owner, repo_name) do
          {:ok, _repo} ->
            redirect(conn, to: ~p"/go/#{repo_owner}/#{repo_name}")

          {:error, _reason} ->
            InvalidRepoCache.cache_invalid_repo(repo_owner, repo_name)
            raise AlgoraWeb.NotFoundError
        end
    end
  end
end
