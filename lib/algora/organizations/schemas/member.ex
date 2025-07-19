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
    |> cast(params, [:role, :org_id, :user_id])
    |> validate_required([:role, :org_id, :user_id])
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:org_id, :user_id])
    |> generate_id()
  end

  def filter_by_org_id(query, nil), do: query

  def filter_by_org_id(query, org_id) do
    from m in query,
      join: o in assoc(m, :org),
      where: o.id == ^org_id
  end

  def can_create_bounty?(role), do: role in [:admin, :mod]

  def can_create_contract?(role), do: role in [:admin, :mod]

  def can_view_matches?(org, role), do: org.contract_signed && role in [:admin, :mod]
end
