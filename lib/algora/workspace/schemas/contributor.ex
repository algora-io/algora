defmodule Algora.Workspace.Contributor do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Workspace.Repository

  typed_schema "contributors" do
    field :contributions, :integer, default: 0

    belongs_to :repository, Repository
    belongs_to :user, User

    timestamps()
  end

  def github_user_changeset(meta) do
    params = %{
      provider_id: to_string(meta["id"]),
      provider_login: meta["login"],
      type: User.type_from_provider(:github, meta["type"]),
      display_name: meta["login"],
      avatar_url: meta["avatar_url"],
      github_url: meta["html_url"]
    }

    %User{provider: "github", provider_meta: meta}
    |> cast(params, [:provider_id, :provider_login, :type, :display_name, :avatar_url, :github_url])
    |> generate_id()
    |> validate_required([:provider_id, :provider_login, :type])
    |> unique_constraint([:provider, :provider_id])
  end

  def changeset(contributor, params) do
    contributor
    |> cast(params, [:contributions, :repository_id, :user_id])
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
