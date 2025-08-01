defmodule Algora.Workspace do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Organizations.Member
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace.CommandResponse
  alias Algora.Workspace.Contributor
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Jobs
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Stargazer
  alias Algora.Workspace.Ticket
  alias Algora.Workspace.UserContribution

  require Logger

  @type ticket_type :: :issue | :pull_request
  @type command_type :: :bounty | :attempt | :claim
  @type command_source :: :ticket | :comment

  @doc """
  Resolves a GitHub installation token for interacting with repositories.

  This function attempts to obtain a valid GitHub access token through three methods in order:
  1. If an installation_id is provided directly, it gets an installation token via the GitHub Apps API
  2. If no installation_id is provided, it attempts to look up an installation_id by the repo owner
  3. If no installation is found, it falls back to using the personal access token of the fallback user

  ## Parameters
    * `installation_id` - Optional GitHub App installation ID
    * `repo_owner` - The GitHub username/org that owns the repository
    * `fallback_user` - The user whose personal access token will be used if no installation token is available

  ## Returns
    * `{:ok, %{installation_id: integer() | nil, token: String.t()}}` - Successfully obtained token
    * `{:error, atom()}` - Failed to obtain token

  ## Examples
      # Using provided installation ID
      iex> resolve_installation_and_token(12345, "octocat", user)
      {:ok, %{installation_id: 12345, token: "ghs_xxx..."}}

      # Looking up installation ID by owner
      iex> resolve_installation_and_token(nil, "octocat", user)
      {:ok, %{installation_id: 67890, token: "ghs_xxx..."}}

      # Falling back to user's personal access token
      iex> resolve_installation_and_token(nil, "octocat", user)
      {:ok, %{installation_id: nil, token: "ghp_xxx..."}}
  """
  @spec resolve_installation_and_token(integer() | nil, String.t(), User.t()) ::
          {:ok, %{installation_id: integer() | nil, token: String.t()}} | {:error, atom()}
  def resolve_installation_and_token(installation_id, repo_owner, fallback_user) do
    with id when not is_nil(id) <- installation_id || get_installation_id_by_owner(repo_owner),
         {:ok, token} <- Github.get_installation_token(id) do
      {:ok, %{installation_id: id, token: token}}
    else
      _ ->
        case Accounts.get_access_token(fallback_user) do
          {:ok, token} -> {:ok, %{installation_id: nil, token: token}}
          error -> error
        end
    end
  end

  @spec get_installation_id_by_owner(String.t()) :: integer() | nil
  def get_installation_id_by_owner(repo_owner) do
    installation =
      Repo.one(
        from i in Installation,
          join: u in User,
          on: u.id == i.provider_user_id and u.provider == i.provider,
          where: u.provider == "github" and u.provider_login == ^repo_owner
      )

    if installation, do: installation.provider_id
  end

  def ensure_ticket(token, owner, repo, number) do
    case get_ticket(owner, repo, number) do
      %Ticket{} = ticket -> {:ok, ticket}
      nil -> create_ticket_from_github(token, owner, repo, number)
    end
  end

  def get_ticket(owner, repo, number) do
    Repo.one(
      from(t in Ticket,
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        where: t.provider == "github",
        where: t.number == ^number,
        where: r.name == ^repo,
        where: u.provider_login == ^owner,
        preload: [repository: {r, user: u}],
        limit: 1
      )
    )
  end

  def create_ticket_from_github(token, owner, repo, number) do
    with {:ok, issue} <- Github.get_issue(token, owner, repo, number),
         {:ok, repository} <- ensure_repository(token, owner, repo) do
      issue
      |> Ticket.github_changeset(repository)
      |> Repo.insert()
    end
  end

  def update_ticket_from_github(token, owner, repo, number) do
    with ticket when not is_nil(ticket) <- get_ticket(owner, repo, number),
         {:ok, issue} <- Github.get_issue(token, owner, repo, number),
         {:ok, repository} <- ensure_repository(token, owner, repo) do
      ticket
      |> Ticket.github_changeset(issue, repository)
      |> Repo.update()
    end
  end

  def ensure_repository(token, owner, repo) do
    repository_query =
      from(r in Repository,
        join: u in assoc(r, :user),
        where: r.provider == "github",
        where: r.name == ^repo,
        where: u.provider_login == ^owner,
        preload: [user: u]
      )

    case Repo.one(repository_query) do
      %Repository{} = repository -> {:ok, repository}
      nil -> create_repository_from_github(token, owner, repo)
    end
  end

  def maybe_schedule_og_image_update(%Repository{} = repository) do
    one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)

    needs_update? =
      Repository.has_default_og_image?(repository) ||
        (repository.og_image_updated_at &&
           DateTime.before?(repository.og_image_updated_at, one_day_ago))

    if needs_update? do
      %{repository_id: repository.id}
      |> Jobs.UpdateRepositoryOgImage.new()
      |> Oban.insert()
    end

    :ok
  end

  def create_repository_from_github(token, owner, repo) do
    with {:ok, repository} <- Github.get_repository(token, owner, repo),
         {:ok, user} <- ensure_user_by_repo(token, repository, owner),
         {:ok, user} <- sync_user(user, repository, owner, repo),
         {:ok, repo} <- repository |> Repository.github_changeset(user) |> Repo.insert() do
      {:ok, %{repo | user: user}}
    else
      {:error,
       %Ecto.Changeset{
         errors: [
           provider: {_, [constraint: :unique, constraint_name: "repositories_provider_provider_id_index"]}
         ]
       } = changeset} ->
        Repo.fetch_one(
          from r in Repository,
            where: r.provider == "github",
            where: r.provider_id == ^changeset.changes.provider_id,
            join: u in assoc(r, :user),
            preload: [user: u]
        )

      {:error, _reason} = error ->
        error
    end
  end

  def ensure_user_by_repo(token, repository, owner) do
    case Repo.get_by(User, provider: "github", provider_id: to_string(repository["owner"]["id"])) do
      %User{} = user ->
        {:ok, user}

      nil ->
        if repository["owner"]["login"] != owner do
          Logger.warning("might need to rename #{owner} -> #{repository["owner"]["login"]}")
        end

        ensure_user(token, repository["owner"]["login"])
    end
  end

  def ensure_user(token, owner) do
    case Repo.get_by(User, provider: "github", provider_login: owner) do
      %User{} = user -> {:ok, user}
      nil -> create_user_from_github(token, owner)
    end
  end

  def ensure_user_by_provider_id(token, provider_id) do
    case Repo.get_by(User, provider: "github", provider_id: to_string(provider_id)) do
      %User{} = user -> {:ok, user}
      nil -> create_user_from_github(token, provider_id)
    end
  end

  def sync_user(user, repository, owner, repo) do
    github_user = repository["owner"]

    if github_user["login"] == user.provider_login and not is_nil(user.provider_id) do
      {:ok, user}
    else
      if github_user["login"] != user.provider_login do
        Logger.warning(
          "renaming #{user.provider_login} -> #{github_user["login"]} (reason: #{owner}/#{repo} moved to #{repository["full_name"]})"
        )
      end

      res =
        user
        |> change(%{
          provider_id: to_string(github_user["id"]),
          provider_login: github_user["login"],
          provider_meta: Util.normalize_struct(github_user)
        })
        |> unique_constraint([:provider, :provider_id])
        |> Repo.update()

      case res do
        {:ok, user} ->
          {:ok, user}

        error ->
          Logger.error("#{owner}/#{repo} | failed to remap #{user.provider_login} -> #{github_user["login"]}")

          error
      end
    end
  end

  def create_user_from_github(token, owner) do
    with {:ok, user_data} <- Github.get_user_by_username(token, owner) do
      user_data
      |> User.github_changeset()
      |> Repo.insert()
    end
  end

  def list_installation_repos_by(clauses) do
    with {:ok, user} <- Repo.fetch_by(User, clauses),
         {:ok, installation} <- Repo.fetch_by(Installation, connected_user_id: user.id),
         {:ok, token} <- Github.get_installation_token(installation.provider_id),
         {:ok, repos} <- Github.list_installation_repos(token) do
      Enum.map(repos, & &1["full_name"])
    end
  end

  def create_installation(user, provider_user, org, data) do
    %Installation{}
    |> Installation.github_changeset(user, provider_user, org, data)
    |> Repo.insert()
  end

  def update_installation(installation, user, provider_user, org, data) do
    installation
    |> Installation.github_changeset(user, provider_user, org, data)
    |> Repo.update()
  end

  def upsert_installation(installation, user, org, provider_user) do
    case get_installation_by_provider_id("github", installation["id"]) do
      nil ->
        create_installation(user, provider_user, org, installation)

      existing_installation ->
        update_installation(existing_installation, user, provider_user, org, installation)
    end
  end

  @spec fetch_installation_by(clauses :: Keyword.t() | map()) ::
          {:ok, Installation.t()} | {:error, :not_found}
  def fetch_installation_by(clauses) do
    Repo.fetch_by(Installation, clauses)
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

  def list_installations_by(fields),
    do:
      Repo.all(
        from(i in Installation,
          where: ^fields,
          join: connected_user in assoc(i, :connected_user),
          join: provider_user in assoc(i, :provider_user),
          select_merge: %{connected_user: connected_user, provider_user: provider_user}
        )
      )

  def fetch_command_response(ticket_id, command_type) do
    Repo.fetch_one(
      from cr in CommandResponse,
        where: cr.ticket_id == ^ticket_id,
        where: cr.command_type == ^command_type
    )
  end

  def delete_command_response(id), do: Repo.delete(Repo.get(CommandResponse, id))

  @spec ensure_command_response(%{
          token: String.t(),
          ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
          command_id: integer(),
          command_type: command_type(),
          command_source: command_source(),
          ticket: Ticket.t(),
          body: String.t()
        }) :: {:ok, CommandResponse.t()} | {:error, any()}
  def ensure_command_response(%{
        token: token,
        ticket_ref: ticket_ref,
        command_id: command_id,
        command_type: command_type,
        command_source: command_source,
        ticket: ticket,
        body: body
      }) do
    case refresh_command_response(%{
           token: token,
           ticket_ref: ticket_ref,
           ticket: ticket,
           body: body,
           command_type: command_type
         }) do
      {:ok, response} ->
        {:ok, response}

      {:error, :command_response_not_found} ->
        post_response(token, ticket_ref, command_id, command_source, ticket, body)

      {:error, {:comment_not_found, response_id}} ->
        with {:ok, _} <- delete_command_response(response_id) do
          post_response(token, ticket_ref, command_id, command_source, ticket, body)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec refresh_command_response(%{
          token: String.t(),
          command_type: command_type(),
          ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
          ticket: Ticket.t(),
          body: String.t()
        }) :: {:ok, CommandResponse.t()} | {:error, any()}
  def refresh_command_response(%{
        token: token,
        command_type: command_type,
        ticket_ref: ticket_ref,
        ticket: ticket,
        body: body
      }) do
    case fetch_command_response(ticket.id, command_type) do
      {:ok, response} ->
        case Github.update_issue_comment(
               token,
               ticket_ref[:owner],
               ticket_ref[:repo],
               response.provider_response_id,
               body
             ) do
          {:ok, comment} ->
            try_update_command_response(response, comment)

          # TODO: don't rely on string matching
          {:error, "404 Not Found"} ->
            Logger.error("Github comment for command response #{response.id} not found")
            {:error, {:comment_not_found, response.id}}

          {:error, reason} ->
            Logger.error("Failed to update command response #{response.id}: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning("Failed to refresh command response #{ticket.id}: #{inspect(reason)}")
        {:error, :command_response_not_found}
    end
  end

  defp post_response(token, ticket_ref, command_id, command_source, ticket, body) do
    with {:ok, comment} <-
           Github.create_issue_comment(
             token,
             ticket_ref[:owner],
             ticket_ref[:repo],
             ticket_ref[:number],
             body
           ) do
      create_command_response(%{
        comment: comment,
        command_source: command_source,
        command_id: command_id,
        ticket_id: ticket.id
      })
    end
  end

  @spec create_command_response(%{
          comment: map(),
          command_source: command_source(),
          command_id: integer(),
          ticket_id: integer()
        }) :: {:ok, CommandResponse.t()} | {:error, any()}
  def create_command_response(%{
        comment: comment,
        command_source: command_source,
        command_id: command_id,
        ticket_id: ticket_id
      }) do
    %CommandResponse{}
    |> CommandResponse.changeset(%{
      provider: "github",
      provider_meta: Util.normalize_struct(comment),
      provider_command_id: to_string(command_id),
      provider_response_id: to_string(comment["id"]),
      command_source: command_source,
      command_type: :bounty,
      ticket_id: ticket_id
    })
    |> Repo.insert()
  end

  defp try_update_command_response(command_response, body) do
    case command_response
         |> CommandResponse.changeset(%{provider_meta: Util.normalize_struct(body)})
         |> Repo.update() do
      {:ok, command_response} ->
        {:ok, command_response}

      {:error, reason} ->
        Logger.error("Failed to update command response #{command_response.id}: #{inspect(reason)}")

        {:ok, command_response}
    end
  end

  def ensure_repo_tech_stack(_token, %{tech_stack: tech_stack}) when tech_stack != [] do
    {:ok, tech_stack}
  end

  def ensure_repo_tech_stack(token, repository) do
    with {:ok, languages} <- Github.list_repository_languages(token, repository.user.provider_login, repository.name) do
      top_languages =
        languages
        |> Enum.sort_by(fn {_lang, count} -> count end, :desc)
        |> Enum.take(3)
        |> Enum.map(fn {lang, _count} -> lang end)

      Repo.update_all(from(r in Repository, where: r.id == ^repository.id), set: [tech_stack: top_languages])

      {:ok, top_languages}
    end
  rescue
    error -> {:error, error}
  end

  def ensure_contributors(token, repository) do
    case list_repository_contributors(repository.user.provider_login, repository.name) do
      [] ->
        with {:ok, contributors} <-
               Github.list_repository_contributors(token, repository.user.provider_login, repository.name) do
          Repo.transact(fn ->
            Enum.reduce_while(contributors, {:ok, []}, fn contributor, {:ok, acc} ->
              case create_contributor_from_github(repository, contributor) do
                {:ok, created} -> {:cont, {:ok, [created | acc]}}
                error -> {:halt, error}
              end
            end)
          end)
        end

      contributors ->
        {:ok, contributors}
    end
  end

  defp ensure_user_by_contributor(contributor) do
    case Repo.get_by(User, provider: "github", provider_id: to_string(contributor["id"])) do
      %User{} = user ->
        {:ok, user}

      nil ->
        contributor
        |> Contributor.github_user_changeset()
        |> Repo.insert()
    end
  end

  def create_contributor_from_github(repository, contributor) do
    with {:ok, user} <- ensure_user_by_contributor(contributor) do
      %Contributor{}
      |> Contributor.changeset(%{
        contributions: contributor["contributions"],
        repository_id: repository.id,
        user_id: user.id
      })
      |> Repo.insert()
    end
  end

  def list_repository_contributors(repo_owner, repo_name) do
    Repo.all(
      from(c in Contributor,
        join: r in assoc(c, :repository),
        where: r.provider == "github",
        where: r.name == ^repo_name,
        join: ro in assoc(r, :user),
        where: ro.provider_login == ^repo_owner,
        join: u in assoc(c, :user),
        where: u.type != :bot,
        where: not ilike(u.provider_login, "%bot"),
        left_join: m in Member,
        on: m.user_id == u.id and m.org_id == r.user_id,
        where: is_nil(m.id),
        select_merge: %{user: u},
        order_by: [desc: c.contributions, asc: c.inserted_at, asc: c.id]
      )
    )
  end

  def list_contributors(repo_owner) do
    Repo.all(
      from(c in Contributor,
        join: r in assoc(c, :repository),
        where: r.provider == "github",
        join: ro in assoc(r, :user),
        where: ro.provider_login == ^repo_owner,
        join: u in assoc(c, :user),
        where: u.type != :bot,
        where: not ilike(u.provider_login, "%bot"),
        left_join: m in Member,
        on: m.user_id == u.id and m.org_id == r.user_id,
        where: is_nil(m.id),
        distinct: [c.user_id],
        select_merge: %{user: u},
        order_by: [desc: c.contributions, asc: c.inserted_at, asc: c.id],
        limit: 50
      )
    )
  end

  def stargazers_query(id) do
    from(s in Stargazer,
      join: r in assoc(s, :repository),
      where: r.provider == "github",
      join: ro in assoc(r, :user),
      where: ro.id == ^id,
      join: u in assoc(s, :user),
      where: u.type != :bot,
      where: not ilike(u.provider_login, "%bot"),
      left_join: m in Member,
      on: m.user_id == u.id and m.org_id == r.user_id,
      where: is_nil(m.id),
      distinct: [s.user_id]
    )
  end

  def list_stargazers(id) do
    id
    |> stargazers_query()
    |> select_merge([s, r, ro, u], %{user: u})
    |> limit(100)
    |> order_by([s], desc: s.inserted_at, asc: s.id)
    |> Repo.all()
  end

  def count_stargazers(id) do
    id |> stargazers_query() |> Repo.aggregate(:count)
  end

  def fetch_contributor(repository_id, user_id) do
    Repo.fetch_by(Contributor, repository_id: repository_id, user_id: user_id)
  end

  def get_or_create_label(token, owner, repo, name, color) do
    case Github.get_label(token, owner, repo, name) do
      {:ok, _} -> {:ok, name}
      {:error, _reason} -> Github.create_label(token, owner, repo, %{"name" => name, "color" => color})
    end
  end

  def add_amount_label(token, owner, repo, number, amount) do
    label = "$#{amount |> Money.to_decimal() |> Util.format_number_compact()}"

    with {:ok, _} <- get_or_create_label(token, owner, repo, label, "34d399"),
         {:ok, _} <- Github.add_labels(token, owner, repo, number, [label]) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to add label #{label} to #{owner}/#{repo}##{number}: #{inspect(reason)}")

        :error
    end
  end

  def remove_amount_label(token, owner, repo, number, amount) do
    label = "$#{amount |> Money.to_decimal() |> Util.format_number_compact()}"

    case Github.Client.fetch(token, "/repos/#{owner}/#{repo}/issues/#{number}/labels/#{label}", "DELETE") do
      # TODO: properly parse DELETE responses in Github.Client
      {:error, %Jason.DecodeError{data: ""}} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to remove label #{label} from #{owner}/#{repo}##{number}: #{inspect(reason)}")

        :error
    end
  end

  @spec list_user_contributions(list(String.t()), Keyword.t()) :: {:ok, list(map())} | {:error, term()}
  def list_user_contributions(ids, opts \\ []) do
    tech_stack = opts[:tech_stack] || []

    strict_tech_stack = opts[:strict_tech_stack]

    query =
      from uc in UserContribution,
        where: uc.user_id in ^ids,
        join: u in assoc(uc, :user),
        join: r in assoc(uc, :repository),
        where: r.tech_stack != [],
        join: repo_owner in assoc(r, :user),
        # where: fragment("? && ?::citext[]", r.tech_stack, ^(opts[:tech_stack] || [])),
        where:
          not (ilike(r.name, "%awesome%") or
                 ilike(r.name, "%algorithms%") or
                 ilike(r.name, "%exercises%") or
                 ilike(r.name, "%tutorials%") or
                 r.name == "DefinitelyTyped" or
                 r.name == "developer-roadmap" or
                 r.name == "freeCodeCamp" or
                 r.name == "hiring-without-whiteboards" or
                 r.name == "papers-we-love"),
        where:
          not (ilike(repo_owner.provider_login, "%algorithms%") or
                 ilike(repo_owner.provider_login, "%firstcontributions%") or
                 repo_owner.provider_login == "up-for-grabs"),
        order_by: [
          desc: fragment("CASE WHEN ? && ?::citext[] THEN 1 ELSE 0 END", r.tech_stack, ^tech_stack),
          desc: r.stargazers_count
        ],
        select: %UserContribution{
          contribution_count: uc.contribution_count,
          user: map(u, [:id, :provider_login]),
          repository: %{
            id: r.id,
            name: r.name,
            stargazers_count: r.stargazers_count,
            tech_stack: r.tech_stack,
            user: map(repo_owner, [:id, :provider_login, :type, :name, :avatar_url, :stargazers_count])
          }
        }

    query =
      if opts[:display_all] do
        query
      else
        where(query, [uc, u, r, repo_owner], repo_owner.type == :organization or r.stargazers_count > 200)
      end

    query =
      if opts[:exclude_personal] do
        where(query, [uc, u, r, repo_owner], repo_owner.type == :organization)
      else
        query
      end

    query =
      if strict_tech_stack do
        where(query, [uc, u, r, repo_owner], fragment("? && ?::citext[]", r.tech_stack, ^tech_stack))
      else
        query
      end

    query =
      case opts[:limit] do
        nil -> query
        limit -> limit(query, ^limit)
      end

    Repo.all(query)
  end

  @spec count_user_contributions(list(String.t()), Keyword.t()) :: {:ok, list(map())} | {:error, term()}
  def count_user_contributions(ids, opts \\ []) do
    query =
      from uc in UserContribution,
        join: u in assoc(uc, :user),
        join: r in assoc(uc, :repository),
        join: repo_owner in assoc(r, :user),
        where: u.id in ^ids,
        where: not ilike(r.name, "%awesome%"),
        where: not ilike(r.name, "%algorithms%"),
        where: not ilike(repo_owner.provider_login, "%algorithms%"),
        where: repo_owner.type == :organization or r.stargazers_count > 200,
        # where: fragment("? && ?::citext[]", r.tech_stack, ^(opts[:tech_stack] || [])),
        order_by: [
          desc: fragment("CASE WHEN ? && ?::citext[] THEN 1 ELSE 0 END", r.tech_stack, ^(opts[:tech_stack] || [])),
          desc: r.stargazers_count
        ],
        select_merge: %{user: u, repository: %{r | user: repo_owner}}

    Repo.aggregate(query, :sum, :contribution_count) || 0
  end

  @spec upsert_contributor(String.t(), String.t(), integer()) ::
          {:ok, Contributor.t()} | {:error, Ecto.Changeset.t()}
  def upsert_contributor(user_id, repository_id, contribution_count) do
    attrs = %{
      user_id: user_id,
      repository_id: repository_id,
      contribution_count: contribution_count,
      last_fetched_at: DateTime.utc_now()
    }

    case Repo.get_by(Contributor, user_id: user_id, repository_id: repository_id) do
      nil ->
        %Contributor{} |> Contributor.changeset(attrs) |> Repo.insert()

      contributor ->
        if contributor.contributions < contribution_count do
          contributor
          |> Contributor.changeset(attrs)
          |> Repo.update()
        else
          {:ok, contributor}
        end
    end
  end

  @spec upsert_user_contribution(String.t(), String.t(), integer()) ::
          {:ok, UserContribution.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user_contribution(user_id, repository_id, contribution_count) do
    attrs = %{
      user_id: user_id,
      repository_id: repository_id,
      contribution_count: contribution_count,
      last_fetched_at: DateTime.utc_now()
    }

    case Repo.get_by(UserContribution, user_id: user_id, repository_id: repository_id) do
      nil ->
        %UserContribution{} |> UserContribution.changeset(attrs) |> Repo.insert()

      contribution ->
        if contribution.contribution_count < contribution_count do
          contribution
          |> UserContribution.changeset(attrs)
          |> Repo.update()
        else
          {:ok, contribution}
        end
    end
  end

  def fetch_top_contributions(token, provider_logins) when is_list(provider_logins) do
    users_with_contributions = get_users_with_contributions(provider_logins)
    users_with_contributions_logins = Enum.map(users_with_contributions, & &1.provider_login)

    users_without_contributions = provider_logins -- users_with_contributions_logins

    cloud_result =
      if Enum.empty?(users_without_contributions) do
        {:ok, []}
      else
        Algora.Cloud.top_contributions(users_without_contributions)
      end

    with {:ok, cloud_contributions} <- cloud_result,
         {:ok, users} <- ensure_users(token, provider_logins),
         :ok <- add_contributions(token, users, cloud_contributions) do
      # Always mark users as synced after fetching from Cloud API
      mark_users_as_synced(users_without_contributions, users)

      existing_contributions = get_existing_contributions(users_with_contributions_logins)
      all_contributions = existing_contributions ++ cloud_contributions
      {:ok, all_contributions}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch contributions for #{inspect(provider_logins)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def fetch_top_contributions_async(token, provider_logins) when is_list(provider_logins) do
    users_with_contributions = get_users_with_contributions(provider_logins)
    users_with_contributions_logins = Enum.map(users_with_contributions, & &1.provider_login)

    users_without_contributions = provider_logins -- users_with_contributions_logins

    cloud_result =
      if Enum.empty?(users_without_contributions) do
        {:ok, []}
      else
        Algora.Cloud.top_contributions(users_without_contributions)
      end

    with {:ok, cloud_contributions} <- cloud_result,
         {:ok, users} <- ensure_users(token, provider_logins),
         :ok <- add_contributions_async(token, users, cloud_contributions) do
      # Always mark users as synced after fetching from Cloud API
      mark_users_as_synced(users_without_contributions, users)
      {:ok, users}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch contributions for #{inspect(provider_logins)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp add_contributions_async(_token, users, contributions) do
    users_map = Enum.group_by(users, & &1.provider_login)

    results =
      Enum.map(contributions, fn contribution ->
        case users_map[contribution.provider_login] do
          [user] ->
            %{
              "user_id" => user.id,
              "repo_full_name" => contribution.repo_name,
              "contribution_count" => contribution.contribution_count
            }
            |> Jobs.SyncContribution.new()
            |> Oban.insert()

          _ ->
            Logger.error("User not found for #{contribution.provider_login}")
            {:error, :user_not_found}
        end
      end)

    if results == [] or Enum.any?(results, &match?({:ok, _}, &1)) do
      :ok
    else
      Logger.error("Failed to add contributions: #{inspect(results)}")
      {:error, :failed}
    end
  end

  defp add_contributions(token, users, contributions) do
    users_map = Enum.group_by(users, & &1.provider_login)

    results =
      Enum.map(contributions, fn contribution ->
        case users_map[contribution.provider_login] do
          [user] ->
            add_contribution(%{
              token: token,
              user_id: user.id,
              repo_full_name: contribution.repo_name,
              contribution_count: contribution.contribution_count
            })

          _ ->
            {:error, :user_not_found}
        end
      end)

    if results == [] or Enum.any?(results, fn result -> result == :ok end), do: :ok, else: {:error, :failed}
  end

  defp add_contribution(%{
         token: token,
         user_id: user_id,
         repo_full_name: repo_full_name,
         contribution_count: contribution_count
       }) do
    with [repo_owner, repo_name] <- String.split(repo_full_name, "/"),
         {:ok, repo} <- ensure_repository(token, repo_owner, repo_name),
         {:ok, _tech_stack} <- ensure_repo_tech_stack(token, repo),
         {:ok, _contribution} <- upsert_user_contribution(user_id, repo.id, contribution_count) do
      :ok
    end
  end

  def ensure_users(token, provider_logins) do
    Repo.transact(fn ->
      provider_logins
      |> Enum.map(&ensure_user(token, &1))
      |> Enum.reduce_while({:ok, []}, fn
        {:ok, user}, {:ok, users} -> {:cont, {:ok, [user | users]}}
        {:error, reason}, _ -> {:halt, {:error, reason}}
      end)
    end)
  end

  @spec get_users_with_contributions(list(String.t())) :: list(User.t())
  defp get_users_with_contributions(provider_logins) do
    # Get users who either have contributions OR have been marked as synced
    users_with_contributions =
      Repo.all(
        from u in User,
          join: uc in UserContribution,
          on: uc.user_id == u.id,
          where: u.provider == "github",
          where: u.provider_login in ^provider_logins,
          distinct: u.id,
          select: u
      )

    users_marked_synced =
      Repo.all(
        from u in User,
          where: u.provider == "github",
          where: u.provider_login in ^provider_logins,
          where: u.repo_contributions_synced == true,
          select: u
      )

    # Combine and deduplicate by id
    Enum.uniq_by(users_with_contributions ++ users_marked_synced, & &1.id)
  end

  @spec get_existing_contributions(list(String.t())) :: list(map())
  defp get_existing_contributions(provider_logins) do
    Repo.all(
      from uc in UserContribution,
        join: u in assoc(uc, :user),
        join: r in assoc(uc, :repository),
        join: repo_owner in assoc(r, :user),
        where: u.provider == "github",
        where: u.provider_login in ^provider_logins,
        select: %{
          provider_login: u.provider_login,
          repo_name: fragment("? || '/' || ?", repo_owner.provider_login, r.name),
          contribution_count: uc.contribution_count
        }
    )
  end

  @spec mark_users_as_synced(list(String.t()), list(User.t())) :: :ok
  defp mark_users_as_synced(users_without_contributions, users) do
    if not Enum.empty?(users_without_contributions) do
      Logger.info("Marking users as repo_contributions_synced: #{inspect(users_without_contributions)}")

      # Update all users that were queried from Cloud API to mark them as synced
      users_map = Enum.group_by(users, & &1.provider_login)

      Enum.each(users_without_contributions, fn provider_login ->
        case users_map[provider_login] do
          [user] ->
            user
            |> Ecto.Changeset.change(%{repo_contributions_synced: true})
            |> Repo.update()

          _ ->
            Logger.warning("User not found for marking as synced: #{provider_login}")
        end
      end)
    end

    :ok
  end

  def remove_existing_amount_labels(token, owner, repo, number) do
    case Github.list_labels(token, owner, repo, number) do
      {:ok, labels} ->
        amount_labels =
          labels
          |> Enum.filter(fn label -> String.starts_with?(label["name"], "$") end)
          |> Enum.map(fn label -> label["name"] end)

        case amount_labels do
          [] ->
            :ok

          _ ->
            Enum.each(amount_labels, fn label_name ->
              Github.remove_label_from_issue(token, owner, repo, number, label_name)
            end)

            :ok
        end

      {:error, reason} ->
        Logger.warning("Failed to list labels for #{owner}/#{repo}##{number}: #{inspect(reason)}")
        :ok
    end
  end
end
