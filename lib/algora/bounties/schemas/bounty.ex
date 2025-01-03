defmodule Algora.Bounties.Bounty do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty
  alias Algora.Payments.Transaction

  @type t() :: %__MODULE__{}

  schema "bounties" do
    field :amount, Algora.Types.Money
    field :status, Ecto.Enum, values: [:open, :cancelled, :paid]

    belongs_to :ticket, Algora.Workspace.Ticket
    belongs_to :owner, User
    belongs_to :creator, User
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:amount, :ticket_id, :owner_id, :creator_id])
    |> validate_required([:amount, :ticket_id, :owner_id, :creator_id])
    |> generate_id()
    |> foreign_key_constraint(:ticket)
    |> foreign_key_constraint(:owner)
    |> foreign_key_constraint(:creator)
    |> unique_constraint([:ticket_id, :owner_id])
    |> Algora.Validations.validate_money_positive(:amount)
  end

  def url(%{repository: %{name: name, owner: %{login: login}}, ticket: %{provider: "github", number: number}}) do
    "https://github.com/#{login}/#{name}/issues/#{number}"
  end

  def url(%{ticket: %{url: url}}) do
    url
  end

  def path(%{repository: %{name: name}, ticket: %{number: number}}) do
    "#{name}##{number}"
  end

  def path(%{ticket: %{provider: "github", url: url}}) do
    url
    |> URI.parse()
    |> then(& &1.path)
    |> String.replace(~r/^\/[^\/]+\//, "")
    |> String.replace(~r/\/(issues|pull|discussions)\//, "#")
  end

  def full_path(%{repository: %{name: name, owner: %{login: login}}, ticket: %{number: number}}) do
    "#{login}/#{name}##{number}"
  end

  def full_path(%{ticket: %{provider: "github", url: url}}) do
    url
    |> URI.parse()
    |> then(& &1.path)
    |> String.replace(~r/\/(issues|pull|discussions)\//, "#")
  end

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
    |> cast(attrs, [:amount])
    |> cast_assoc(:ticket)
    |> validate_required([:amount])
    |> validate_number(:amount, greater_than: 0)
  end
end
