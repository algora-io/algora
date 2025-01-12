defmodule Algora.Payments.Account do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity
  alias Algora.Stripe

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "accounts" do
    field :provider, :string, null: false
    field :provider_id, :string, null: false
    field :provider_meta, :map, null: false

    field :name, :string
    field :details_submitted, :boolean, default: false, null: false
    field :charges_enabled, :boolean, default: false, null: false
    field :payouts_enabled, :boolean, default: false, null: false
    field :payout_interval, :string
    field :payout_speed, :integer
    field :default_currency, :string
    field :service_agreement, :string
    field :country, :string, null: false
    field :type, Ecto.Enum, values: [:standard, :express], null: false
    field :stale, :boolean, default: false, null: false

    belongs_to :user, Algora.Accounts.User, null: false

    has_many :activities, {"account_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore
    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :provider,
      :provider_id,
      :provider_meta,
      :details_submitted,
      :charges_enabled,
      :payouts_enabled,
      :payout_interval,
      :payout_speed,
      :default_currency,
      :service_agreement,
      :country,
      :type,
      :stale,
      :user_id
    ])
    |> validate_required([
      :provider,
      :provider_id,
      :provider_meta,
      :details_submitted,
      :charges_enabled,
      :payouts_enabled,
      :country,
      :type,
      :stale,
      :user_id
    ])
    |> validate_inclusion(:type, [:standard, :express])
    |> validate_inclusion(:country, Stripe.ConnectCountries.list_codes())
    |> foreign_key_constraint(:user_id)
    |> generate_id()
  end
end
