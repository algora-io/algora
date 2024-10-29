defmodule Algora.Bounties do
  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Repo
  alias Algora.Accounts
  alias Algora.Work
  alias Algora.Accounts.User
  alias Algora.Organizations.Member

  @spec create_bounty(
          creator :: User.t(),
          owner :: User.t(),
          url :: String.t(),
          amount :: Decimal.t()
        ) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(creator = %User{}, owner = %User{}, url, amount) do
    with {:ok, token} <- Accounts.get_access_token(creator),
         {:ok, task} <- Work.fetch_task(:github, %{token: token, url: url}) do
      %Bounty{}
      |> Bounty.changeset(%{
        amount: Decimal.new(amount),
        currency: "USD",
        task_id: task.id,
        owner_id: owner.id,
        creator_id: creator.id
      })
      |> Repo.insert()
    else
      error -> error
    end
  end

  @spec list_bounties(
          params :: %{
            optional(:owner_id) => integer(),
            optional(:limit) => non_neg_integer(),
            optional(:status) => :open | :completed,
            optional(:tech_stack) => [String.t()]
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

    query =
      from b in sq,
        join: t in assoc(b, :task),
        join: o in assoc(b, :owner),
        left_join: r in assoc(t, :repository),
        left_join: u in assoc(r, :user),
        select: %{
          id: b.id,
          inserted_at: b.inserted_at,
          amount: b.amount,
          currency: b.currency,
          tech_stack: o.tech_stack,
          owner: %{
            name: coalesce(o.name, o.handle),
            handle: o.handle,
            avatar_url: o.avatar_url
          },
          task: %{
            title: t.title,
            # HACK: remove these once we have a way to get the owner and repo from the task
            owner: coalesce(u.provider_login, o.handle),
            repo: coalesce(r.name, o.handle),
            number: t.number
          }
        },
        limit: ^limit,
        order_by: [desc: b.inserted_at, desc: b.id]

    query
    |> Bounty.filter_by_org_id(params[:owner_id])
    |> Bounty.filter_by_tech_stack(params[:tech_stack])
    |> Repo.all()
  end

  def fetch_stats(org_id \\ nil) do
    open_bounties_query = Bounty.open() |> Bounty.filter_by_org_id(org_id)
    rewarded_bounties_query = Bounty.completed() |> Bounty.filter_by_org_id(org_id)
    rewarded_claims_query = Claim.rewarded() |> Claim.filter_by_org_id(org_id)
    members_query = Member |> Member.filter_by_org_id(org_id)

    open_bounties = Repo.aggregate(open_bounties_query, :count, :id)
    open_bounties_amount = Repo.aggregate(open_bounties_query, :sum, :amount) || Decimal.new(0)

    total_awarded = Repo.aggregate(rewarded_bounties_query, :sum, :amount) || Decimal.new(0)
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
      currency: "USD",
      open_bounties_amount: open_bounties_amount,
      open_bounties_count: open_bounties,
      total_awarded: total_awarded,
      completed_bounties_count: completed_bounties,
      solvers_count: solvers_count,
      solvers_diff: solvers_diff,
      members_count: members_count
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
