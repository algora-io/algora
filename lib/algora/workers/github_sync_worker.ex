defmodule Algora.Workers.GithubSyncWorker do
  use Oban.Worker, queue: :github_sync, max_attempts: 3

  import Ecto.Query
  alias Algora.Repo
  alias Algora.Bounties.Bounty
  alias Algora.Claims.Claim
  alias Algora.Github

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"bounty_id" => bounty_id}}) do
    bounty = Repo.get!(Bounty, bounty_id)
    sync_bounty(bounty)
  end

  def perform(%Oban.Job{args: %{"org_id" => org_id}}) do
    bounties = 
      from(b in Bounty,
        where: b.org_id == ^org_id and b.status == "open",
        preload: [:claims]
      )
      |> Repo.all()

    Enum.each(bounties, &sync_bounty/1)
  end

  def perform(%Oban.Job{args: %{}}) do
    # Sync all open bounties
    bounties =
      from(b in Bounty,
        where: b.status == "open",
        preload: [:claims]
      )
      |> Repo.all()

    Enum.each(bounties, &sync_bounty/1)
  end

  defp sync_bounty(bounty) do
    case Github.get_issue_or_pr(bounty.github_url) do
      {:ok, %{state: github_state, merged: merged}} ->
        new_status = determine_bounty_status(github_state, merged)
        
        if bounty.status != new_status do
          update_bounty_status(bounty, new_status)
        end

        update_claims_count(bounty)

      {:error, _reason} ->
        # GitHub API error, skip this bounty
        :ok
    end
  end

  defp determine_bounty_status("closed", true), do: "completed"
  defp determine_bounty_status("closed", false), do: "closed" 
  defp determine_bounty_status("open", _), do: "open"

  defp update_bounty_status(bounty, new_status) do
    bounty
    |> Bounty.changeset(%{status: new_status})
    |> Repo.update()
  end

  defp update_claims_count(bounty) do
    claims_count = 
      from(c in Claim,
        where: c.bounty_id == ^bounty.id,
        select: count(c.id)
      )
      |> Repo.one()

    if bounty.claims_count != claims_count do
      bounty
      |> Bounty.changeset(%{claims_count: claims_count})
      |> Repo.update()
    end
  end

  def schedule_org_sync(org_id) do
    %{org_id: org_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def schedule_bounty_sync(bounty_id) do
    %{bounty_id: bounty_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def schedule_full_sync do
    %{}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end