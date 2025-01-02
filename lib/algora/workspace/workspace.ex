defmodule Algora.Workspace do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Ticket

  require Logger

  @type ticket_type :: :issue | :pull_request

  def ensure_ticket(token, owner, repo, number) do
    ticket_query =
      from(t in Ticket,
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        where: t.provider == "github",
        where: t.number == ^number,
        where: r.name == ^repo,
        where: u.provider_login == ^owner,
        preload: [repository: {r, user: u}]
      )

    case Repo.one(ticket_query) do
      %Ticket{} = ticket -> {:ok, ticket}
      nil -> create_ticket_from_github(token, owner, repo, number)
    end
  end

  def create_ticket_from_github(token, owner, repo, number) do
    with {:ok, issue} <- Github.get_issue(token, owner, repo, number),
         {:ok, repository} <- ensure_repository(token, owner, repo) do
      issue
      |> Ticket.github_changeset(repository)
      |> Repo.insert()
    end
  end

  def ensure_repository(token, owner, repo) do
    repository_query =
      from(r in Repository,
        join: u in assoc(r, :user),
        where: r.provider == "github",
        where: r.name == ^repo,
        where: u.provider_login == ^owner
      )

    case Repo.one(repository_query) do
      %Repository{} = repository -> {:ok, repository}
      nil -> create_repository_from_github(token, owner, repo)
    end
  end

  def create_repository_from_github(token, owner, repo) do
    with {:ok, repository} <- Github.get_repository(token, owner, repo),
         {:ok, user} <- ensure_user(token, owner) do
      repository
      |> Repository.github_changeset(user)
      |> Repo.insert()
    end
  end

  def ensure_user(token, owner) do
    case Repo.get_by(User, provider: "github", provider_login: owner) do
      %User{} = user -> {:ok, user}
      nil -> create_user_from_github(token, owner)
    end
  end

  def create_user_from_github(token, owner) do
    with {:ok, user_data} <- Github.get_user_by_username(token, owner) do
      user_data
      |> User.github_changeset()
      |> Repo.insert()
    end
  end

  def create_installation(:github, user, org, data) do
    %Installation{}
    |> Installation.changeset(:github, user, org, data)
    |> Repo.insert()
  end

  def update_installation(:github, user, org, installation, data) do
    installation
    |> Installation.changeset(:github, user, org, data)
    |> Repo.update()
  end

  def get_installation_by(fields), do: Repo.get_by(Installation, fields)
  def get_installation_by!(fields), do: Repo.get_by!(Installation, fields)

  @type provider_id :: String.t() | integer()

  @spec get_installation_by_provider_id(String.t(), provider_id()) :: Installation.t() | nil
  def get_installation_by_provider_id(provider, provider_id),
    do: get_installation_by(provider: provider, provider_id: to_string(provider_id))

  @spec get_installation_by_provider_id!(String.t(), provider_id()) :: Installation.t()
  def get_installation_by_provider_id!(provider, provider_id),
    do: get_installation_by!(provider: provider, provider_id: to_string(provider_id))

  def get_installation(id), do: Repo.get(Installation, id)
  def get_installation!(id), do: Repo.get!(Installation, id)

  def list_user_installations(user_id) do
    Repo.all(from(i in Installation, where: i.owner_id == ^user_id, preload: [:connected_user]))
  end
end
