defmodule Algora.Workspace.Jobs.ProcessStargazers do
  @moduledoc false
  use Oban.Worker,
    queue: :sync_contribution,
    max_attempts: 3

  import Ecto.Query

  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace
  alias Algora.Workspace.Jobs.ImportStargazer
  alias Algora.Workspace.Stargazer

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_logins" => provider_logins, "repo_id" => repo_id}}) do
    token = Github.TokenPool.get_token()

    jobs =
      provider_logins
      |> Enum.reduce([], fn provider_login, acc ->
        case Workspace.ensure_user(token, provider_login) do
          {:ok, user} ->
            if user.provider_meta["followers"] < 10 do
              Logger.warning("User #{provider_login} has less than 10 followers")
              acc
            else
              if Repo.exists?(from s in Stargazer, where: s.user_id == ^user.id and s.repository_id == ^repo_id) do
                acc
              else
                [user.provider_login | acc]
              end
            end

          {:error, reason} ->
            Logger.error("Failed to fetch user #{provider_login}: #{reason}")
            acc
        end
      end)
      |> Enum.chunk_every(10)
      |> Enum.map(fn logins -> ImportStargazer.new(%{provider_logins: logins, repo_id: repo_id}) end)
      |> Oban.insert_all()

    case jobs do
      [] ->
        Logger.warning("No stargazers to process for #{repo_id}")

      _ ->
        :ok
    end
  end
end
