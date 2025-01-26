defmodule Algora.Workspace do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace.CommandResponse
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Jobs
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

    res =
      case Repo.one(repository_query) do
        %Repository{} = repository -> {:ok, repository}
        nil -> create_repository_from_github(token, owner, repo)
      end

    case res do
      {:ok, repository} -> maybe_schedule_og_image_update(repository)
      error -> error
    end

    res
  end

  defp maybe_schedule_og_image_update(%Repository{} = repository) do
    one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)

    needs_update? =
      Repository.has_default_og_image?(repository) ||
        (repository.og_image_updated_at && DateTime.before?(repository.og_image_updated_at, one_day_ago))

    if needs_update? do
      %{repository_id: repository.id}
      |> Jobs.UpdateRepositoryOgImage.new()
      |> Oban.insert()
    end

    :ok
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

  def list_installations_by(fields), do: Repo.all(from(i in Installation, where: ^fields))

  def list_user_installations(user_id) do
    Repo.all(from(i in Installation, where: i.owner_id == ^user_id, preload: [:connected_user]))
  end

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
          command_type: :bounty | :attempt | :claim,
          command_source: :ticket | :comment,
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
          command_type: :bounty | :attempt | :claim,
          ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
          ticket: Ticket.t(),
          body: String.t()
        }) :: {:ok, CommandResponse.t()} | {:error, any()}
  defp refresh_command_response(%{
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
               ticket_ref["owner"],
               ticket_ref["repo"],
               response.provider_response_id,
               body
             ) do
          {:ok, comment} ->
            try_update_command_response(response, comment)

          # TODO: don't rely on string matching
          {:error, "404 Not Found"} ->
            Logger.error("Command response #{response.id} not found")
            {:error, {:comment_not_found, response.id}}

          {:error, reason} ->
            Logger.error("Failed to update command response #{response.id}: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, _reason} ->
        {:error, :command_response_not_found}
    end
  end

  defp post_response(token, ticket_ref, command_id, command_source, ticket, body) do
    with {:ok, comment} <-
           Github.create_issue_comment(token, ticket_ref["owner"], ticket_ref["repo"], ticket_ref["number"], body) do
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
          command_source: :ticket | :comment,
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
end
