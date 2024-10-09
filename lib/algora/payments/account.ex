defmodule Algora.Payments.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    belongs_to :user, Algora.Accounts.User
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:provider, :provider_id, :provider_meta])
    |> validate_required([:provider, :provider_id, :provider_meta])
  end
end
