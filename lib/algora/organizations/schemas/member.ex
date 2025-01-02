defmodule Algora.Organizations.Member do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  @type t() :: %__MODULE__{}

  schema "members" do
    field :role, Ecto.Enum, values: [:admin, :mod, :expert]

    belongs_to :org, User
    belongs_to :user, User

    timestamps()
  end

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
