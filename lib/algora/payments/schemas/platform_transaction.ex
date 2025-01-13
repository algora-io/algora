defmodule Algora.Payments.PlatformTransaction do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "platform_transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :succeeded_at, :utc_datetime_usec
    field :amount, Algora.Types.Money
    field :type, :string
    field :reporting_category, :string

    has_many :activities, {"platform_transaction_activities", Activity}, foreign_key: :assoc_id
    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :amount])
    |> validate_required([:provider, :provider_id, :provider_meta, :amount])
  end
end
