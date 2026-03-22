defmodule Algora.Bounties.Jobs.SyncBountyStates do
  @moduledoc """
  Syncs GitHub issue state for open bounties belonging to an org.

  Ensures org bounty pages reflect the current state of GitHub issues,
  even when webhooks were not received (e.g. for external orgs).

  Deduplicated to run at most once per hour per org.
  """
  use Oban.Worker,
    queue: :background,
    max_attempts: 2,
    unique: [fields: [:args], period: 3600]

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

    Enum.each(tickets, fn %{number: number, repo_name: repo_name, owner_login: owner_login} ->
      Workspace.update_ticket_from_github(token, owner_login, repo_name, number)
    end)

    :ok
  end
end
