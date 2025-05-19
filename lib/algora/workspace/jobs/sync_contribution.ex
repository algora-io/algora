defmodule Algora.Workspace.Jobs.SyncContribution do
  @moduledoc false
  use Oban.Worker,
    queue: :sync_contribution,
    max_attempts: 3

  alias Algora.Github
  alias Algora.Workspace

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"user_id" => user_id, "repo_full_name" => repo_full_name, "contribution_count" => contribution_count}
      }) do
    token = Github.TokenPool.get_token()

    with [repo_owner, repo_name] <- String.split(repo_full_name, "/"),
         {:ok, repo} <- Workspace.ensure_repository(token, repo_owner, repo_name),
         {:ok, _tech_stack} <- Workspace.ensure_repo_tech_stack(token, repo),
         {:ok, _contribution} <- Workspace.upsert_user_contribution(user_id, repo.id, contribution_count) do
      :ok
    end
  end
end
