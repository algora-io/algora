defmodule Algora.Bounties.Jobs.SyncBountyTickets do
  @moduledoc """
  Syncs GitHub issue state for open bounties belonging to an org.

  When an org bounty page is visited, this job is enqueued to refresh
  the ticket state from GitHub. This handles cases where webhooks were
  missed or never configured for the repo, ensuring org bounty pages
  accurately reflect whether linked GitHub issues are still open.

  Deduplicated via Oban unique constraints: runs at most once per hour
  per org to avoid excessive GitHub API calls.
  """
  use Oban.Worker,
    queue: :background,
    max_attempts: 2,
    unique: [fields: [:args], keys: [:owner_id], period: :timer.hours(1)]

  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"owner_id" => owner_id}}) do
    token = Github.TokenPool.get_token()

    tickets =
      Repo.all(
        from b in Bounty,
          join: t in assoc(b, :ticket),
          join: r in assoc(t, :repository),
          join: u in assoc(r, :user),
          where: b.owner_id == ^owner_id,
          where: b.status == :open,
          where: not is_nil(b.amount),
          select: %{
            number: t.number,
            repo_name: r.name,
            owner_login: u.provider_login
          },
          distinct: true,
          limit: 100
      )

    for ticket <- tickets do
      Workspace.update_ticket_from_github(
        token,
        ticket.owner_login,
        ticket.repo_name,
        ticket.number
      )
    end

    :ok
  end
end
