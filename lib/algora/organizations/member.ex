defmodule Algora.Organizations.Member do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "members" do
    field :role, Ecto.Enum, values: [:admin, :mod, :expert]

    belongs_to :org, Algora.Users.User
    belongs_to :user, Algora.Users.User

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:role, :org_id, :user_id])
    |> validate_required([:role, :org_id, :user_id])
    |> generate_id()
  end

  def filter_by_org_id(query, nil), do: query

  def filter_by_org_id(query, org_id) do
    from m in query,
      join: o in assoc(m, :org),
      where: o.id == ^org_id
  end
end
