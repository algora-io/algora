defmodule Algora.Bounties.PrizePool do
  @moduledoc false
  use Algora.Schema

  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Repo
  alias Algora.Workspace.Ticket

  @primary_key false
  typed_schema "bounty_listings" do
    # Denormalized fields from Ticket
    field :title, :string
    field :number, :integer
    field :url, :string

    # Computed/aggregated fields
    field :total_bounty_amount, Algora.Types.Money
    field :bounty_count, :integer

    # Original associations
    belongs_to :ticket, Ticket
    belongs_to :repository, Algora.Workspace.Repository

    has_many :bounties, Bounty, foreign_key: :ticket_id, references: :ticket_id
    has_many :top_bounties, Bounty, foreign_key: :ticket_id, references: :ticket_id
  end

  @type criterion ::
          {:limit, non_neg_integer()}
          | {:owner_id, integer()}
          | {:status, :open | :paid}
          | {:tech_stack, [String.t()]}

  @spec base_query([criterion()]) :: Ecto.Queryable.t()
  def base_query(criteria \\ []) do
    bounty_subquery =
      from(b in Bounty)
      |> where([b], not is_nil(b.amount))
      |> apply_criteria(criteria)
      |> group_by([b], b.ticket_id)
      |> select([b], %{
        ticket_id: b.ticket_id,
        total_bounty_amount: sum(b.amount),
        bounty_count: count(b.id)
      })

    from(t in Ticket)
    |> join(:inner, [t], b in subquery(bounty_subquery), on: b.ticket_id == t.id, as: :b)
    |> join(:left, [t], r in assoc(t, :repository), as: :r)
    |> join(:left, [t, r: repo], ro in assoc(repo, :user), as: :ro)
    |> select([t, b: b, r: r, ro: ro], %__MODULE__{
      ticket_id: t.id,
      title: t.title,
      number: t.number,
      url: t.url,
      repository: %{
        id: r.id,
        name: r.name,
        owner: %{
          login: ro.provider_login
        }
      },
      total_bounty_amount: b.total_bounty_amount,
      bounty_count: b.bounty_count
    })
    |> order_by([t, b: b],
      desc: b.total_bounty_amount,
      desc: b.bounty_count,
      desc: t.inserted_at
    )
  end

  def list(criteria \\ []) do
    tickets = criteria |> base_query() |> Repo.all()
    ticket_ids = Enum.map(tickets, & &1.ticket_id)

    top_bounties = fetch_top_bounties(ticket_ids)

    Enum.map(tickets, fn ticket ->
      Map.put(ticket, :top_bounties, Map.get(top_bounties, ticket.ticket_id, []))
    end)
  end

  defp fetch_top_bounties(ticket_ids) do
    from(b in Bounty)
    |> join(:left, [b], o in assoc(b, :owner))
    |> where([b], b.ticket_id in ^ticket_ids)
    |> select([b, o], %{
      ticket_id: b.ticket_id,
      amount: b.amount,
      owner: %{
        id: o.id,
        handle: o.handle,
        avatar_url: o.avatar_url,
        provider_login: o.provider_login
      }
    })
    |> order_by([b], [b.ticket_id, desc: b.amount])
    |> Repo.all()
    |> Enum.group_by(& &1.ticket_id)
    |> Map.new(fn {ticket_id, bounties} ->
      {ticket_id, Enum.take(bounties, 5)}
    end)
  end

  @spec apply_criteria(Ecto.Queryable.t(), [criterion()]) :: Ecto.Queryable.t()
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:owner_id, owner_id}, query ->
        from([b] in query, where: b.owner_id == ^owner_id)

      {:status, status}, query ->
        from([b] in query, where: b.status == ^status)

      _, query ->
        query
    end)
  end
end
