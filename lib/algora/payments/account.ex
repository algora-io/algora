defmodule Algora.Payments.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string
    field :details_submitted, :boolean, default: false
    field :charges_enabled, :boolean, default: false
    field :service_agreement, :string
    field :country, :string
    field :type, Ecto.Enum, values: [:standard, :express]
    field :region, Ecto.Enum, values: [:US, :EU]
    field :stale, :boolean, default: false

    belongs_to :user, Algora.Accounts.User
    has_many :transactions, Algora.Payments.Transaction

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
      :service_agreement,
      :country,
      :type,
      :region,
      :stale
    ])
    |> validate_required([:provider, :provider_id, :provider_meta])
  end
end
