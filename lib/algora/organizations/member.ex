defmodule Algora.Organizations.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :roles, {:array, :string}, default: []

    belongs_to :org, Algora.Accounts.User
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:org_id, :user_id])
    |> validate_required([:org_id, :user_id])
  end
end
