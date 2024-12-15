defmodule Algora.Bounties do
  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Organizations.Member
  alias Algora.Repo
  alias Algora.Payments.Transaction
  alias Algora.Users.User

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

  def base_query, do: Bounty

  @type criteria :: %{
          optional(:limit) => non_neg_integer(),
          optional(:owner_id) => integer(),
          optional(:status) => :open | :paid,
          optional(:tech_stack) => [String.t()]
        }
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:owner_id, owner_id}, query ->
        from([b] in query, where: b.owner_id == ^owner_id)

      {:status, status}, query ->
        from([b] in query, where: b.status == ^status)

      {:tech_stack, tech_stack}, query ->
        from([b] in query,
          where:
            fragment(
              "EXISTS (SELECT 1 FROM UNNEST(?::citext[]) t1 WHERE t1 = ANY(?::citext[]))",
              b.tech_stack,
              ^tech_stack
            )
        )

      _, query ->
        query
    end)
  end

  @spec list_bounties_with(base_query :: Ecto.Query.t(), criteria :: criteria()) :: [map()]
  def list_bounties_with(base_query, criteria \\ []) do
    criteria = Keyword.merge([order: :date, limit: 10], criteria)

    base_bounties = base_query |> select([b], b.id)

    from(b in Bounty)
    |> join(:inner, [b], bb in subquery(base_bounties), on: b.id == bb.id)
    |> join(:inner, [b], t in assoc(b, :ticket), as: :t)
    |> join(:inner, [b], o in assoc(b, :owner), as: :o)
    |> join(:left, [t: t], r in assoc(t, :repository), as: :r)
    |> join(:left, [r: r], ro in assoc(r, :user), as: :ro)
    |> apply_criteria(criteria)
    |> order_by([b], desc: b.amount, desc: b.inserted_at, desc: b.id)
    |> select([b, o: o, t: t, ro: ro, r: r], %{
      id: b.id,
      inserted_at: b.inserted_at,
      amount: b.amount,
      owner: %{
        id: o.id,
        display_name: o.display_name,
        handle: o.handle,
        avatar_url: o.avatar_url,
        tech_stack: o.tech_stack
      },
      ticket: %{
        id: t.id,
        title: t.title,
        number: t.number,
        url: t.url
      },
      repository: %{
        id: r.id,
        name: r.name,
        owner: %{
          id: ro.id,
          login: ro.provider_login
        }
      }
    })
    |> Repo.all()
  end

  def awarded_to_user(user_id) do
    from b in Bounty,
      join: t in Transaction,
      on: t.bounty_id == b.id,
      where: t.user_id == ^user_id and t.type == :credit and t.status == :succeeded
  end

  def list_bounties_awarded_to_user(user_id, criteria \\ []) do
    awarded_to_user(user_id)
    |> list_bounties_with(criteria)
  end

  def list_bounties(criteria \\ []) do
    base_query()
    |> list_bounties_with(criteria)
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
end
