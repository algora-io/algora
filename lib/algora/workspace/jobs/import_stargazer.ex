defmodule Algora.Workspace.Jobs.ImportStargazer do
  @moduledoc false
  use Oban.Worker,
    queue: :fetch_top_contributions,
    max_attempts: 3

  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace.Stargazer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_logins" => provider_logins, "repo_id" => repo_id}}) do
    with {:ok, users} <- Algora.Workspace.fetch_top_contributions_async(Github.TokenPool.get_token(), provider_logins) do
      {_count, _} =
        Repo.insert_all(
          Stargazer,
          Enum.map(users, fn user ->
            %{
              id: Nanoid.generate(),
              inserted_at: DateTime.utc_now(),
              updated_at: DateTime.utc_now(),
              user_id: user.id,
              repository_id: repo_id
            }
          end),
          on_conflict: :nothing
        )

      :ok
    end
  end

  def perform(%Oban.Job{args: %{"provider_login" => provider_login, "repo_id" => repo_id}}) do
    with {:ok, users} <- Algora.Workspace.fetch_top_contributions_async(Github.TokenPool.get_token(), [provider_login]) do
      {_count, _} =
        Repo.insert_all(
          Stargazer,
          Enum.map(users, fn user ->
            %{
              id: Nanoid.generate(),
              inserted_at: DateTime.utc_now(),
              updated_at: DateTime.utc_now(),
              user_id: user.id,
              repository_id: repo_id
            }
          end),
          on_conflict: :nothing
        )

      :ok
    end
  end
end
