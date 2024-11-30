defmodule Algora.Bounties do
  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Payments.Transaction
  alias Algora.Bounties.Claim
  alias Algora.Repo
  alias Algora.Users.User
  alias Algora.Organizations.Member

  @spec create_bounty(
          creator :: User.t(),
          owner :: User.t(),
          params :: map()
        ) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(creator, owner, params) do
    %Bounty{
      creator_id: creator.id,
      owner_id: owner.id
    }
    |> Bounty.create_changeset(params)
    |> Repo.insert()
  end

  @spec list_bounties(
          params :: %{
            optional(:owner_id) => integer(),
            optional(:limit) => non_neg_integer(),
            optional(:status) => :open | :completed,
            optional(:tech_stack) => [String.t()],
            optional(:solver_country) => String.t(),
            optional(:sort_by) => :amount | :date
          }
        ) :: [map()]
  def list_bounties(params) do
    limit = params[:limit] || 10

    sq =
      case params[:status] do
        :open -> Bounty.open()
        :completed -> Bounty.completed()
        _ -> Bounty.open()
      end

    order_by =
      case params[:sort_by] do
        :amount -> [desc: :amount, desc: :inserted_at, desc: :id]
        :date -> [desc: :inserted_at, desc: :id]
        _ -> [desc: :inserted_at, desc: :id]
      end

    query =
      from b in sq,
        join: t in assoc(b, :ticket),
        join: o in assoc(b, :owner),
        left_join: r in assoc(t, :repository),
        left_join: u in assoc(r, :user),
        left_join: tr in Transaction,
        on: tr.bounty_id == b.id and not is_nil(tr.succeeded_at),
        left_join: solver in User,
        on: solver.id == tr.recipient_id,
        select: %{
          id: b.id,
          inserted_at: b.inserted_at,
          amount: b.amount,
          tech_stack: o.tech_stack,
          owner: %{
            name: coalesce(o.name, o.handle),
            handle: o.handle,
            avatar_url: o.avatar_url
          },
          solver: %{
            id: solver.id,
            name: coalesce(solver.name, solver.handle),
            handle: solver.handle,
            avatar_url: solver.avatar_url,
            country: solver.country
          },
          ticket: %{
            title: t.title,
            # HACK: remove these once we have a way to get the owner and repo from the ticket
            owner: coalesce(u.provider_login, o.handle),
            repo: coalesce(r.name, o.handle),
            number: t.number
          }
        },
        limit: ^limit,
        order_by: ^order_by

    query
    |> Bounty.filter_by_org_id(params[:owner_id])
    |> Bounty.filter_by_tech_stack(params[:tech_stack])
    |> filter_by_solver_country(params[:solver_country])
    |> Repo.all()
  end

  defp filter_by_solver_country(query, nil), do: query

  defp filter_by_solver_country(query, country) do
    from [b, t, o, r, u, tr, solver] in query,
      where: solver.country == ^country
  end

  def fetch_stats(org_id \\ nil) do
    open_bounties_query = Bounty.open() |> Bounty.filter_by_org_id(org_id)
    rewarded_bounties_query = Bounty.completed() |> Bounty.filter_by_org_id(org_id)
    rewarded_claims_query = Claim.rewarded() |> Claim.filter_by_org_id(org_id)
    members_query = Member |> Member.filter_by_org_id(org_id)

    open_bounties = Repo.aggregate(open_bounties_query, :count, :id)
    open_bounties_amount = Repo.aggregate(open_bounties_query, :sum, :amount) || Money.zero(:USD)

    total_awarded = Repo.aggregate(rewarded_bounties_query, :sum, :amount) || Money.zero(:USD)
    completed_bounties = Repo.aggregate(rewarded_bounties_query, :count, :id)

    solvers_count_last_month =
      Repo.aggregate(
        rewarded_claims_query
        |> where([c], c.inserted_at >= fragment("NOW() - INTERVAL '1 month'")),
        :count,
        :user_id,
        distinct: true
      )

    solvers_count = Repo.aggregate(rewarded_claims_query, :count, :user_id, distinct: true)
    solvers_diff = solvers_count - solvers_count_last_month

    members_count = Repo.aggregate(members_query, :count, :id)

    %{
      open_bounties_amount: open_bounties_amount,
      open_bounties_count: open_bounties,
      total_awarded: total_awarded,
      completed_bounties_count: completed_bounties,
      solvers_count: solvers_count,
      solvers_diff: solvers_diff,
      members_count: members_count,
      # TODO
      reviews_count: 4
    }
  end

  def fetch_recent_bounties(org_id \\ nil) do
    Bounty.open()
    |> Bounty.filter_by_org_id(org_id)
    |> Bounty.order_by_most_recent()
    |> Bounty.limit(4)
    |> Repo.all()
    |> Enum.map(fn bounty ->
      %{
        title: bounty.title,
        amount: bounty.amount,
        issue_number: bounty.issue_number,
        inserted_at: bounty.inserted_at
      }
    end)
  end
end
