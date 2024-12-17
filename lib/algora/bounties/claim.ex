defmodule Algora.Bounties.Claim do
  use Algora.Schema
  alias Algora.Bounties.Claim

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "claims" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :type, Ecto.Enum, values: [:code, :video, :design, :article]

    field :status, Ecto.Enum, values: [:pending, :merged, :approved, :rejected, :charged, :paid]

    field :merged_at, :utc_datetime_usec
    field :approved_at, :utc_datetime_usec
    field :rejected_at, :utc_datetime_usec
    field :charged_at, :utc_datetime_usec
    field :paid_at, :utc_datetime_usec

    field :title, :string
    field :description, :string
    field :url, :string
    field :group_id, :string

    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Users.User
    # has_one :transaction, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end

  def rewarded(query \\ Claim) do
    from c in query,
      where: c.status == :approved and not is_nil(c.charged_at)
  end

  def filter_by_org_id(query, nil), do: query

  def filter_by_org_id(query, org_id) do
    from c in query,
      join: b in assoc(c, :bounty),
      join: u in assoc(b, :owner),
      where: u.id == ^org_id
  end
end
