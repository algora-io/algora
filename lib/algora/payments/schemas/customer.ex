defmodule Algora.Payments.Customer do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "customers" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string

    belongs_to :user, Algora.Accounts.User

    has_one :default_payment_method, Algora.Payments.PaymentMethod,
      foreign_key: :customer_id,
      where: [is_default: true]

    has_many :activities, {"customer_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:user_id, :provider, :provider_id, :provider_meta, :name])
    |> generate_id()
    |> validate_required([:user_id, :provider, :provider_id, :provider_meta, :name])
    |> unique_constraint([:provider, :provider_id])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
