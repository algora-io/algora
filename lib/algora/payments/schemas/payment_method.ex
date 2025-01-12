defmodule Algora.Payments.PaymentMethod do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "payment_methods" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map
    field :provider_customer_id, :string
    field :is_default, :boolean, default: true

    belongs_to :customer, Algora.Payments.Customer

    has_many :activities, {"platform_transaction_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(payment_method, attrs) do
    payment_method
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :provider_customer_id])
    |> validate_required([:provider, :provider_id, :provider_meta, :provider_customer_id])
  end
end
