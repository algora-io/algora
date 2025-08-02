defmodule Algora.Workspace.Jobs.ProcessContributors do
  @moduledoc false
  use Oban.Worker,
    queue: :internal_par,
    max_attempts: 3

  alias Algora.Workspace.Jobs.ImportContributor

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"contributors_data" => contributors_data, "repo_id" => repo_id}}) do
    jobs =
      contributors_data
      |> Enum.reduce([], fn contributor_data, acc ->
        id = contributor_data["id"]
        contributions = contributor_data["contributions"]

        case Algora.Repo.fetch(Algora.Accounts.User, id) do
          {:ok, user} ->
            [%{provider_login: user.provider_login, contributions: contributions} | acc]

          {:error, reason} ->
            Logger.error("Failed to fetch user #{id}: #{reason}")
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
