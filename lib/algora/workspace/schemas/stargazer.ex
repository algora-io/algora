defmodule Algora.Workspace.Stargazer do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Workspace.Repository

  typed_schema "stargazers" do
    belongs_to :repository, Repository
    belongs_to :user, User

    timestamps()
  end

  def changeset(stargazer, params) do
    stargazer
    |> cast(params, [:repository_id, :user_id])
    |> validate_required([:repository_id, :user_id])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:repository_id, :user_id])
    |> generate_id()
  end

  def filter_by_repository_id(query, nil), do: query

  def filter_by_repository_id(query, repository_id) do
    from c in query,
      join: r in assoc(c, :repository),
      where: r.id == ^repository_id
  end
end
