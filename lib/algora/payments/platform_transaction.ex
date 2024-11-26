defmodule Algora.Payments.PlatformTransaction do
  use Algora.Model

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "platform_transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :succeeded_at, :utc_datetime
    field :amount, :decimal
    field :currency, :string
    field :type, :string
    field :reporting_category, :string

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :amount, :currency])
    |> validate_required([:provider, :provider_id, :provider_meta, :amount, :currency])
  end
end
