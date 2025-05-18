defmodule Algora.Workspace.Jobs.ImportStargazer do
  @moduledoc false
  use Oban.Worker,
    queue: :fetch_top_contributions,
    max_attempts: 3,
    # 30 days
    unique: [period: 30 * 24 * 60 * 60, fields: [:args]]

  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace.Stargazer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_login" => provider_login, "repo_id" => repo_id}}) do
    with {:ok, user} <- Algora.Workspace.fetch_top_contributions_async(Github.TokenPool.get_token(), provider_login) do
      %Stargazer{}
      |> Stargazer.changeset(%{user_id: user.id, repository_id: repo_id})
      |> Repo.insert()
    end
  end

  def timeout(_), do: :timer.seconds(30)
end
