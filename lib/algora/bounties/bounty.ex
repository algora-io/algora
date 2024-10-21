defmodule Algora.Bounties.Bounty do
  use Algora.Model
  alias Algora.Bounties.Bounty

  @type t() :: %__MODULE__{}

  schema "bounties" do
    field :amount, :decimal
    field :currency, :string

    belongs_to :task, Algora.Work.Task
    belongs_to :owner, Algora.Accounts.User
    belongs_to :creator, Algora.Accounts.User
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:amount, :currency, :task_id, :owner_id, :creator_id])
    |> generate_id()
    |> validate_required([:amount, :currency, :task_id, :owner_id, :creator_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:currency, ["USD"])
  end

  def open(query \\ Bounty) do
    from b in query,
      left_join: c in assoc(b, :claims),
      where: is_nil(c.id) or c.status != :approved
  end

  def completed(query \\ Bounty) do
    from b in query,
      join: c in assoc(b, :claims),
      where: c.status == :approved
  end

  def rewarded(query \\ Bounty) do
    from b in query,
      join: c in assoc(b, :claims),
      where: not is_nil(c.charged_at)
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
end
