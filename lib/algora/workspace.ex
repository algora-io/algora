defmodule Algora.Workspace do
  require Logger
  import Ecto.Query

  alias Algora.Github
  alias Algora.Repo
  alias Algora.Users.User
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Ticket

  @upsert_options [
    on_conflict: {:replace_all_except, [:id, :inserted_at]},
    conflict_target: [:provider, :provider_id]
  ]

  @type ticket_type :: :issue | :pull_request

  @spec upsert_ticket(
          :github,
          %{
            token: Github.token(),
            owner: String.t(),
            repo: String.t(),
            number: integer(),
            meta: map()
          }
        ) ::
          {:ok, Ticket.t()} | {:error, atom()}
  def upsert_ticket(:github, %{
        token: token,
        owner: owner,
        repo: repo,
        meta: meta
      }) do
    with {:ok, repo} <- fetch_repository(:github, %{token: token, owner: owner, repo: repo}) do
      Ticket.github_changeset(repo, meta)
      |> Repo.insert(@upsert_options)
    end
  end

  @spec upsert_repository(:github, %{token: Github.token(), owner: String.t(), meta: map()}) ::
          {:ok, Repository.t()} | {:error, atom()}
  def upsert_repository(:github, %{token: token, owner: owner, meta: meta}) do
    with {:ok, user} <- fetch_user(:github, %{token: token, id: meta["owner"]["id"]}),
         {:ok, repo} <- Repository.github_changeset(user, meta) |> Repo.insert(@upsert_options) do
      {:ok, repo}
    else
      {:error, error} ->
        Logger.error("Failed to upsert repository #{owner}/#{meta["name"]}: #{inspect(error)}")
        {:error, error}
    end
  end

  @spec upsert_user(:github, %{meta: map()}) :: {:ok, User.t()} | {:error, atom()}
  def upsert_user(:github, %{meta: meta}) do
    with {:ok, user} <- User.github_changeset(meta) |> Repo.insert(@upsert_options) do
      {:ok, user}
    else
      error ->
        Logger.error("Failed to upsert user #{meta["login"]}: #{inspect(error)}")
        {:error, error}
    end
  end

  @spec fetch_ticket(:github, %{
          token: Github.token(),
          url: String.t()
        }) :: {:ok, Ticket.t()} | {:error, atom()}
  def fetch_ticket(:github, %{token: token, url: url}) do
    case parse_url(url) do
      {:ok, %{owner: owner, repo: repo, number: number}} ->
        fetch_ticket(:github, %{token: token, owner: owner, repo: repo, number: number})

      {:error, error} ->
        {:error, error}
    end
  end

  @spec fetch_ticket(:github, %{
          token: Github.token(),
          owner: String.t(),
          repo: String.t(),
          number: integer()
        }) :: {:ok, Ticket.t()} | {:error, atom()}
  def fetch_ticket(:github, %{token: token, owner: owner, repo: repo, number: number}) do
    query =
      from t in Ticket,
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        where:
          t.provider == "github" and
            u.provider_login == ^owner and
            r.name == ^repo and
            t.number == ^number

    case Repo.one(query) do
      nil ->
        case Github.get_issue(token, owner, repo, number) do
          {:ok, meta} ->
            upsert_ticket(:github, %{
              token: token,
              owner: owner,
              repo: repo,
              number: number,
              meta: meta
            })

          {:error, error} ->
            {:error, error}
        end

      ticket ->
        {:ok, ticket}
    end
  end

  @spec fetch_user(:github, %{token: Github.token(), id: String.t()}) ::
          {:ok, User.t()} | {:error, atom()}
  def fetch_user(:github, %{token: token, id: id}) do
    query =
      from u in User,
        where: u.provider == "github" and u.provider_id == ^to_string(id),
        # TODO: handle multiple users with the same provider_id
        limit: 1

    case Repo.one(query) do
      nil ->
        case Github.get_user(token, id) do
          {:ok, meta} -> upsert_user(:github, %{meta: meta})
          {:error, error} -> {:error, error}
        end

      user ->
        {:ok, user}
    end
  end

  @spec fetch_user(:github, %{token: Github.token(), login: String.t()}) ::
          {:ok, User.t()} | {:error, atom()}
  def fetch_user(:github, %{token: token, login: login}) do
    query =
      from u in User,
        where: u.provider == "github" and u.provider_login == ^login,
        # TODO: handle multiple users with the same provider_login
        limit: 1

    case Repo.one(query) do
      nil ->
        case Github.get_user_by_username(token, login) do
          {:ok, meta} -> upsert_user(:github, %{meta: meta})
          {:error, error} -> {:error, error}
        end

      user ->
        {:ok, user}
    end
  end

  @spec fetch_repository(:github, %{token: Github.token(), owner: String.t(), repo: String.t()}) ::
          {:ok, Repository.t()} | {:error, atom()}
  def fetch_repository(:github, %{token: token, owner: owner, repo: repo}) do
    query =
      from r in Repository,
        join: u in assoc(r, :user),
        where: r.provider == "github" and r.name == ^repo and u.provider_login == ^owner

    case Repo.one(query) do
      nil ->
        case Github.get_repository(token, owner, repo) do
          {:ok, meta} -> upsert_repository(:github, %{token: token, owner: owner, meta: meta})
          {:error, error} -> {:error, error}
        end

      repo ->
        {:ok, repo}
    end
  end

  @spec fetch_repository(:github, %{token: Github.token(), id: String.t()}) ::
          {:ok, Repository.t()} | {:error, atom()}
  def fetch_repository(:github, %{token: token, id: id}) do
    query =
      from r in Repository,
        join: u in assoc(r, :user),
        where: r.provider == "github" and r.provider_id == ^to_string(id)

    case Repo.one(query) do
      nil ->
        case Github.get_repository(token, id) do
          {:ok, meta} ->
            upsert_repository(:github, %{token: token, owner: meta["owner"]["login"], meta: meta})

          {:error, error} ->
            {:error, error}
        end

      repo ->
        {:ok, repo}
    end
  end

  defp parse_url(url) do
    cond do
      issue_params = parse_url(:github, :issue, url) ->
        {:ok, issue_params |> Map.put(:type, :issue)}

      pr_params = parse_url(:github, :pull_request, url) ->
        {:ok, pr_params |> Map.put(:type, :pull_request)}

      true ->
        :error
    end
  end

  defp parse_url(:github, :issue, url) do
    regex =
      ~r|https?://(?:www\.)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/issues/(?<number>\d+)|

    parse_with_regex(regex, url)
  end

  defp parse_url(:github, :pull_request, url) do
    regex =
      ~r|https?://(?:www\.)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<number>\d+)|

    parse_with_regex(regex, url)
  end

  defp parse_with_regex(regex, url) do
    case Regex.named_captures(regex, url) do
      %{"owner" => owner, "repo" => repo, "number" => number} ->
        %{owner: owner, repo: repo, number: String.to_integer(number)}

      nil ->
        nil
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
