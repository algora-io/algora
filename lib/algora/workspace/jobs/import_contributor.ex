defmodule Algora.Workspace.Jobs.ImportContributor do
  @moduledoc false
  use Oban.Worker,
    queue: :internal,
    max_attempts: 3

  alias Algora.Github

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"contributors_data" => contributors_data, "repo_id" => repo_id}}) do
    token = Github.TokenPool.get_token()
    provider_logins = Enum.map(contributors_data, & &1["provider_login"])

    with {:ok, users} <- Algora.Workspace.fetch_top_contributions_async(token, provider_logins) do
      contributions_map =
        Map.new(contributors_data, fn contributor -> {contributor["provider_login"], contributor["contributions"]} end)

      for user <- users do
        contributions = Map.get(contributions_map, user.provider_login, 0)
        {:ok, _} = Algora.Workspace.upsert_contributor(user.id, repo_id, contributions)
        {:ok, _} = Algora.Workspace.upsert_user_contribution(user.id, repo_id, contributions)
      end

      :ok
    end
  end
end
