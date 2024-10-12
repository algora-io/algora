defmodule Algora.Payments.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string
    field :region, Ecto.Enum, values: [:US, :EU]

    belongs_to :user, Algora.Accounts.User
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:user_id, :provider, :provider_id, :provider_meta, :name, :region])
    |> validate_required([:user_id, :provider, :provider_id, :provider_meta, :name, :region])
  end
end
