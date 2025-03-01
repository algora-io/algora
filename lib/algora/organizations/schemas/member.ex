defmodule Algora.Organizations.Member do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  @roles [:admin, :mod, :expert]

  typed_schema "members" do
    field :role, Ecto.Enum, values: @roles

    belongs_to :org, User
    belongs_to :user, User

    timestamps()
  end

  def roles, do: @roles

  def changeset(member, params) do
    member
    |> cast(params, [:role])
    |> put_assoc(:org, params.org)
    |> put_assoc(:user, params.user)
    |> validate_required([:role, :org, :user])
    |> generate_id()
  end

  def filter_by_org_id(query, nil), do: query

  def filter_by_org_id(query, org_id) do
    from m in query,
      join: o in assoc(m, :org),
      where: o.id == ^org_id
  end
end
