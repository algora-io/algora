defmodule Algora.Payments.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    belongs_to :user, Algora.Accounts.User
    has_many :transactions, Algora.Payments.Transaction
    has_many :subscriptions, Algora.Payments.Subscription

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:user_id, :provider, :provider_id, :provider_meta])
    |> validate_required([:user_id, :provider, :provider_id, :provider_meta])
  end
end
