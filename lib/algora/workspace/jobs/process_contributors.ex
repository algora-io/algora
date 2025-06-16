defmodule Algora.Workspace.Jobs.ProcessContributors do
  @moduledoc false
  use Oban.Worker,
    queue: :sync_contribution,
    max_attempts: 3

  alias Algora.Github
  alias Algora.Workspace
  alias Algora.Workspace.Jobs.ImportContributor

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"contributors_data" => contributors_data, "repo_id" => repo_id}}) do
    token = Github.TokenPool.get_token()

    jobs =
      contributors_data
      |> Enum.reduce([], fn contributor_data, acc ->
        provider_login = contributor_data["login"]
        contributions = contributor_data["contributions"]

        case Workspace.ensure_user(token, provider_login) do
          {:ok, user} ->
            [%{provider_login: user.provider_login, contributions: contributions} | acc]

          {:error, reason} ->
            Logger.error("Failed to fetch user #{provider_login}: #{reason}")
            acc
        end
      end)
      |> Enum.chunk_every(10)
      |> Enum.map(fn contributors -> ImportContributor.new(%{contributors_data: contributors, repo_id: repo_id}) end)
      |> Oban.insert_all()

    case jobs do
      [] ->
        Logger.warning("No contributors to process for #{repo_id}")

      _ ->
        :ok
    end
  end
end
