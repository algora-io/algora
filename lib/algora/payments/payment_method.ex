defmodule Algora.Payments.PaymentMethod do
  use Algora.Model

  schema "payment_methods" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map
    field :provider_customer_id, :string
    field :is_default, :boolean, default: true

    belongs_to :customer, Algora.Payments.Customer

    timestamps()
  end

  def changeset(payment_method, attrs) do
    payment_method
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :provider_customer_id])
    |> validate_required([:provider, :provider_id, :provider_meta, :provider_customer_id])
  end
end
