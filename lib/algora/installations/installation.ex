defmodule Algora.Installations.Installation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "installations" do
    field :provider, :string
    field :provider_id, :string
    field :provider_login, :string
    field :provider_meta, :map

    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(installation, attrs) do
    installation
    |> cast(attrs, [:provider, :provider_id, :provider_login, :provider_meta])
    |> validate_required([:provider, :provider_id, :provider_login, :provider_meta])
  end
end
