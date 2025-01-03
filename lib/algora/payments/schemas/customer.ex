defmodule Algora.Payments.Customer do
  @moduledoc false
  use Algora.Schema

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "customers" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string
    field :region, Ecto.Enum, values: [:US, :EU]

    belongs_to :user, Algora.Accounts.User

    has_one :default_payment_method, Algora.Payments.PaymentMethod,
      foreign_key: :customer_id,
      where: [is_default: true]

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:user_id, :provider, :provider_id, :provider_meta, :name, :region])
    |> validate_required([:user_id, :provider, :provider_id, :provider_meta, :name, :region])
    |> unique_constraint(:user_id)
  end
end
