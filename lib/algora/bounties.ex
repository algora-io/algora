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

  @type criteria :: %{
          optional(:owner_id) => integer(),
          optional(:limit) => non_neg_integer(),
          optional(:status) => :open | :paid,
          optional(:tech_stack) => [String.t()],
          optional(:solver_country) => String.t(),
          optional(:sort_by) => :amount | :date
        }

  @spec list_bounties(criteria :: criteria()) :: [map()]
  def list_bounties(criteria \\ []) do
    criteria = Keyword.merge([order: :date, limit: 10], criteria)

    base_bounties =
      Bounty
      |> apply_criteria(criteria)
      |> select([b], b.id)

    from(b in Bounty)
    |> join(:inner, [b], bb in subquery(base_bounties), on: b.id == bb.id)
    |> join(:inner, [b], t in assoc(b, :ticket), as: :ticket)
    |> join(:inner, [b], o in assoc(b, :owner), as: :owner)
    |> join(:left, [ticket: t], r in assoc(t, :repository), as: :repo)
    |> join(:left, [repo: r], u in assoc(r, :user), as: :user)
    |> join(:left, [b], tr in Transaction,
      on: tr.bounty_id == b.id and not is_nil(tr.succeeded_at),
      as: :transaction
    )
    |> join(:left, [transaction: tr], solver in User,
      on: solver.id == tr.user_id,
      as: :solver
    )
    |> select([b, owner: o, ticket: t, user: u, repo: r, solver: solver], %{
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
        owner: coalesce(u.provider_login, o.handle),
        repo: coalesce(r.name, o.handle),
        number: t.number
      }
    })
    |> Repo.all()
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:status, status}, query ->
        from([b] in query, where: b.status == ^status)

      {:owner_id, owner_id}, query ->
        from([b] in query, where: b.owner_id == ^owner_id)

      {:solver_country, country}, query ->
        from([b, solver: solver] in query, where: solver.country == ^country)

      {:order, :amount}, query ->
        from([b] in query, order_by: [desc: b.amount, desc: b.inserted_at, desc: b.id])

      {:order, :date}, query ->
        from([b] in query, order_by: [desc: b.inserted_at, desc: b.id])

      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      _, query ->
        query
    end)
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
