defmodule Algora.Workspace.InvalidRepoCache do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Repo

  typed_schema "invalid_repos" do
    field :owner, :string
    field :name, :string

    timestamps()
  end

  def changeset(invalid_repo, attrs) do
    invalid_repo
    |> cast(attrs, [:owner, :name])
    |> validate_required([:owner, :name])
    |> unique_constraint([:owner, :name])
  end

  def cache_invalid_repo(owner, name) do
    %__MODULE__{}
    |> changeset(%{owner: owner, name: name})
    |> generate_id()
    |> Repo.insert()
  end

  def invalid_repo?(owner, name) do
    query =
      from r in __MODULE__,
        where: r.owner == ^owner and r.name == ^name

    Repo.exists?(query)
  end
end
