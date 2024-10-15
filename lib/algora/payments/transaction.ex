defmodule Algora.Payments.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :succeeded_at, :utc_datetime
    field :amount, :decimal
    field :currency, :string
    field :type, Ecto.Enum, values: [:charge, :transfer]

    belongs_to :account, Algora.Payments.Account
    belongs_to :customer, Algora.Payments.Customer
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :claim, Algora.Bounties.Claim
    belongs_to :project, Algora.Projects.Project

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :amount, :currency])
    |> validate_required([:provider, :provider_id, :provider_meta, :amount, :currency])
  end
end
