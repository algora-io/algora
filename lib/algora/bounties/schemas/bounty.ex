defmodule Algora.Bounties.Bounty do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty

  @type visibility :: :community | :exclusive | :public

  typed_schema "bounties" do
    field :amount, Algora.Types.Money
    field :status, Ecto.Enum, values: [:open, :cancelled, :paid]
    field :number, :integer, default: 0
    field :autopay_disabled, :boolean, default: false
    field :visibility, Ecto.Enum, values: [:community, :exclusive, :public], null: false, default: :community
    field :shared_with, {:array, :string}, null: false, default: []
    field :deadline, :utc_datetime_usec

    belongs_to :ticket, Algora.Workspace.Ticket
    belongs_to :owner, User
    belongs_to :creator, User
    has_many :transactions, Algora.Payments.Transaction
    has_many :activities, {"bounty_activities", Algora.Activities.Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def preload(id) do
    from a in __MODULE__,
      preload: [:ticket, :owner, :creator],
      where: a.id == ^id
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:amount, :ticket_id, :owner_id, :creator_id, :visibility, :shared_with])
    |> validate_required([:amount, :ticket_id, :owner_id, :creator_id])
    |> generate_id()
    |> foreign_key_constraint(:ticket)
    |> foreign_key_constraint(:owner)
    |> foreign_key_constraint(:creator)
    |> unique_constraint([:ticket_id, :owner_id, :number])
    |> Algora.Validations.validate_money_positive(:amount)
  end

  def settings_changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:visibility, :shared_with, :deadline])
    |> Algora.Validations.validate_date_in_future(:deadline)
    |> validate_required([:visibility, :shared_with])
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

  # DEPRECATED
  def path(%{ticket: %{provider: "github", url: url}}) do
    Algora.Util.path_from_url(url)
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

  def order_by_most_recent(query \\ Bounty) do
    from(b in query, order_by: [desc: b.inserted_at])
  end

  def limit(query \\ Bounty, limit) do
    from(b in query, limit: ^limit)
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
