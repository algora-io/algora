defmodule Algora.Bounties.Bounty do
  use Algora.Model
  alias Algora.Bounties.Bounty
  alias Algora.Payments.Transaction
  @type t() :: %__MODULE__{}

  schema "bounties" do
    field :amount, Money.Ecto.Composite.Type
    field :payment_type, Ecto.Enum, values: [:fixed, :hourly]

    belongs_to :ticket, Algora.Workspace.Ticket
    belongs_to :owner, Algora.Users.User
    belongs_to :creator, Algora.Users.User
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:amount, :ticket_id, :owner_id, :creator_id])
    |> generate_id()
    |> validate_required([:amount, :ticket_id, :owner_id, :creator_id])
    |> validate_number(:amount, greater_than: 0)
  end

  def url(bounty),
    do:
      "https://github.com/#{bounty.ticket.owner}/#{bounty.ticket.repo}/issues/#{bounty.ticket.number}"

  def path(bounty),
    do: "#{bounty.ticket.repo}##{bounty.ticket.number}"

  def full_path(bounty),
    do: "#{bounty.ticket.owner}/#{bounty.ticket.repo}##{bounty.ticket.number}"

  def open(query \\ Bounty) do
    from b in query,
      as: :bounties,
      where:
        not exists(
          from(
            t in Transaction,
            where:
              parent_as(:bounties).id == t.bounty_id and
                not is_nil(t.succeeded_at) and
                t.type == :transfer
          )
        )
  end

  def completed(query \\ Bounty) do
    from b in query,
      as: :bounties,
      where:
        exists(
          from(
            t in Transaction,
            where:
              parent_as(:bounties).id == t.bounty_id and
                not is_nil(t.succeeded_at) and
                t.type == :transfer
          )
        )
  end

  def rewarded(query \\ Bounty) do
    from b in query,
      as: :bounties,
      where:
        exists(
          from(
            t in Transaction,
            where:
              parent_as(:bounties).id == t.bounty_id and
                not is_nil(t.succeeded_at) and
                t.type == :transfer
          )
        )
  end

  def order_by_most_recent(query \\ Bounty) do
    from(b in query, order_by: [desc: b.inserted_at])
  end

  def limit(query \\ Bounty, limit) do
    from(b in query, limit: ^limit)
  end

  def filter_by_org_id(query, nil), do: query

  def filter_by_org_id(query, org_id) do
    from b in query,
      join: u in assoc(b, :owner),
      where: u.id == ^org_id
  end

  def filter_by_tech_stack(query, []), do: query
  def filter_by_tech_stack(query, nil), do: query

  def filter_by_tech_stack(query, tech_stack) do
    lowercase_tech_stack = Enum.map(tech_stack, &String.downcase/1)

    from b in query,
      join: o in assoc(b, :owner),
      where: fragment("ARRAY(SELECT LOWER(unnest(?))) && ?", o.tech_stack, ^lowercase_tech_stack)
  end

  def create_changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:amount, :payment_type])
    |> cast_assoc(:ticket)
    |> validate_required([:amount])
    |> validate_number(:amount, greater_than: 0)
  end
end
