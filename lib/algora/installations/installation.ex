defmodule Algora.Installations.Installation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "installations" do
    field :provider, :string
    field :provider_id, :string
    field :provider_login, :string
    field :provider_meta, :map

    field :avatar_url, :string
    field :repository_selection, :string

    belongs_to :owner, Algora.Accounts.User
    belongs_to :connected_user, Algora.Accounts.User

    timestamps()
  end

  def changeset(installation, attrs) do
    installation
    |> cast(attrs, [])
    |> validate_required([])
  end
end
