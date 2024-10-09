defmodule Algora.Payments.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map
    field :amount, :decimal
    field :currency, :string

    belongs_to :account, Algora.Payments.Account
    belongs_to :customer, Algora.Payments.Customer

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :amount, :currency])
    |> validate_required([:provider, :provider_id, :provider_meta, :amount, :currency])
  end
end
