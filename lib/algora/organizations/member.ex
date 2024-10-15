defmodule Algora.Organizations.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "members" do
    field :role, Ecto.Enum, values: [:admin, :mod, :expert]

    belongs_to :org, Algora.Accounts.User
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:role, :org_id, :user_id])
    |> validate_required([:role, :org_id, :user_id])
  end
end
