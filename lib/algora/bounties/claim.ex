defmodule Algora.Bounties.Claim do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "claims" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :type, Ecto.Enum, values: [:code, :video, :design, :article]

    field :status, Ecto.Enum,
      values: [:pending, :merged, :approved, :rejected, :charged, :transferred]

    field :merged_at, :utc_datetime
    field :approved_at, :utc_datetime
    field :rejected_at, :utc_datetime
    field :charged_at, :utc_datetime
    field :transferred_at, :utc_datetime

    field :title, :string
    field :description, :string
    field :url, :string
    field :group_id, :string

    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Accounts.User
    has_one :transaction, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end
end
