defmodule Algora.Admin do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.Parser
  alias Algora.Payments
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Ticket

  require Logger

  def alert(message) do
    email_job =
      Algora.Activities.SendEmail.changeset(%{
        title: "Alert: #{message}",
        body: message,
        name: "Algora Alert",
        email: "info@algora.io"
      })

    discord_job =
      Algora.Activities.SendDiscord.changeset(%{
        payload: %{embeds: [%{color: 0xEF4444, title: "Alert", description: message, timestamp: DateTime.utc_now()}]}
      })

    Oban.insert_all([email_job, discord_job])
  end

  def token!, do: System.fetch_env!("ADMIN_GITHUB_TOKEN")

  def run(worker) do
    worker.perform(%Oban.Job{args: read!("dev/job.json")})
  end

  def read!(path) do
    {:ok, data} = read(path)
    data
  end

  def read(path) do
    with {:ok, content} <- File.read(Path.join(:code.priv_dir(:algora), path)),
         {:ok, data} <- Jason.decode(content) do
      {:ok, data}
    else
      error ->
        Logger.error("Failed to read #{path}: #{inspect(error)}")
        error
    end
  end

  def backfill_repos! do
    query =
      from(t in Ticket,
        where: fragment("?->>'repository_url' IS NOT NULL", t.provider_meta),
        distinct: fragment("?->>'repository_url'", t.provider_meta),
        select: fragment("?->>'repository_url'", t.provider_meta)
      )

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_repo/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_repo_tech_stack! do
    query = from(r in Repository, join: u in assoc(r, :user), select: %{r | user: u})

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_repo_tech_stack/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository tech stack backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_repo_contributors! do
    query =
      from(r in Repository,
        where: fragment("?->>'contributors_url' IS NOT NULL", r.provider_meta),
        join: u in assoc(r, :user),
        join: t in assoc(r, :tickets),
        join: b in assoc(t, :bounties),
        distinct: fragment("?->>'contributors_url'", r.provider_meta),
        select: %{r | user: u}
      )

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_repo_contributors/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository contributors backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_claims! do
    query =
      from(t in Claim,
        where: fragment("? ilike ?", t.url, "%//github.com/%"),
        distinct: t.url,
        select: t.url
      )

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_claim/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Claim backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_tickets! do
    query =
      from(t in Ticket,
        join: b in assoc(t, :bounties),
        where: b.status == :open,
        where: fragment("?->>'url' IS NOT NULL", t.provider_meta),
        select: t
      )

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_ticket/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Ticket backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_users! do
    query =
      from(u in User,
        where: is_nil(u.provider_id) and not is_nil(u.provider_login),
        distinct: u.provider_login,
        select: u.provider_login
      )

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_user/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_installations! do
    query =
      from(i in Installation,
        where: is_nil(i.provider_user_id),
        distinct: i.provider_id,
        select: i.provider_id
      )

    {success, failure} =
      query
      |> Repo.all()
      |> Task.async_stream(&backfill_installation/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_repo(url) do
    with %URI{host: "api.github.com", path: "/repos/" <> path} <- URI.parse(url),
         [owner, repo] <- String.split(path, "/", trim: true),
         {:ok, repo} <- Workspace.ensure_repository(token!(), owner, repo),
         :ok <- update_tickets(url, repo.id) do
      {:ok, repo}
    else
      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill repo #{url}: #{inspect(error)}")
        {:error, error}
    end
  end

  def backfill_repo_tech_stack(repo) do
    case Workspace.ensure_repo_tech_stack(token!(), repo) do
      {:ok, languages} ->
        {:ok, languages}

      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill repo tech stack #{repo.provider_meta["languages_url"]}: #{inspect(error)}")
        {:error, error}
    end
  end

  def backfill_repo_contributors(repo) do
    case Workspace.ensure_contributors(token!(), repo) do
      {:ok, contributors} ->
        {:ok, contributors}

      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill repo contributors #{repo.provider_meta["contributors_url"]}: #{inspect(error)}")
        {:error, error}
    end
  end

  def backfill_claim(url) do
    with {:ok, [ticket_ref: [owner: owner, repo: repo, type: _type, number: number]], _, _, _, _} <-
           Parser.full_ticket_ref(url),
         {:ok, ticket} <- Workspace.ensure_ticket(token!(), owner, repo, number),
         :ok <- update_claims(url, ticket.id) do
      {:ok, ticket}
    else
      {:error, "404 Not Found"} = error ->
        error

      {:error, %Postgrex.Error{postgres: %{constraint: "claims_user_id_source_id_target_id_index"}}} = error ->
        error

      error ->
        Logger.error("Failed to backfill claim #{url}: #{inspect(error)}")
        {:error, error}
    end
  end

  def backfill_ticket(ticket) do
    case Github.Client.fetch(token!(), ticket.provider_meta["url"]) do
      {:ok, issue} ->
        ticket
        |> Ecto.Changeset.change(
          provider_meta: Util.normalize_struct(issue),
          state: String.to_existing_atom(issue["state"])
        )
        |> Repo.update()

      {:error, "410 This issue was deleted"} ->
        ticket
        |> Ecto.Changeset.change(state: :closed)
        |> Repo.update()

      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill ticket #{ticket.id}: #{inspect(error)}")
        {:error, error}
    end
  end

  def backfill_user(provider_login) do
    with {:ok, user} <- Github.get_user_by_username(token!(), provider_login),
         :ok <- update_user(user) do
      {:ok, user}
    else
      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill user #{provider_login}: #{inspect(error)}")
        {:error, error}
    end
  end

  def backfill_installation(installation_id) do
    with {:ok, installation} <- Github.get_installation(installation_id),
         :ok <- update_installation(installation) do
      {:ok, installation}
    else
      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill installation #{installation_id}: #{inspect(error)}")
        {:error, error}
    end
  end

  def make_admin!(user_handle, is_admin) when is_boolean(is_admin) do
    user_handle
    |> Algora.Accounts.get_user_by_handle()
    |> Algora.Accounts.User.is_admin_changeset(is_admin)
    |> Algora.Repo.update()
  end

  def setup_test_account(user_handle) do
    with account_id when is_binary(account_id) <- Algora.config([:stripe, :test_account_id]),
         {:ok, user} <- Repo.fetch_by(User, handle: user_handle),
         {:ok, acct} <- Payments.create_account(user, "US"),
         {:ok, stripe_acct} <- Algora.PSP.Account.retrieve(account_id) do
      Payments.update_account(acct, stripe_acct)
    end
  end

  defp update_tickets(url, repo_id) do
    Repo.update_all(from(t in Ticket, where: fragment("?->>'repository_url' = ?", t.provider_meta, ^url)),
      set: [repository_id: repo_id]
    )

    :ok
  rescue
    error -> {:error, error}
  end

  defp update_repo_tech_stack(languages, repo_id) do
    top_languages =
      languages
      |> Enum.sort_by(fn {_lang, count} -> count end, :desc)
      |> Enum.take(3)
      |> Enum.map(fn {lang, _count} -> lang end)

    Repo.update_all(from(r in Repository, where: r.id == ^repo_id), set: [tech_stack: top_languages])

    :ok
  rescue
    error -> {:error, error}
  end

  defp update_claims(url, source_id) do
    Repo.update_all(from(t in Claim, where: t.url == ^url), set: [source_id: source_id])

    :ok
  rescue
    error -> {:error, error}
  end

  defp update_user(user) do
    Repo.update_all(from(u in User, where: u.provider == "github", where: u.provider_login == ^user["login"]),
      set: [provider_meta: Util.normalize_struct(user), provider_id: to_string(user["id"])]
    )

    :ok
  rescue
    error -> {:error, error}
  end

  defp update_installation(installation) do
    target_user =
      Repo.get_by(User,
        provider: "github",
        provider_id: to_string(installation["target_id"])
      )

    Repo.update_all(
      from(t in Installation,
        where: t.provider == "github",
        where: t.provider_id == ^to_string(installation["id"])
      ),
      set:
        [
          provider_meta: Util.normalize_struct(installation),
          repository_selection: installation["repository_selection"]
        ] ++
          if(target_user, do: [provider_user_id: target_user.id], else: [])
    )

    :ok
  rescue
    error -> {:error, error}
  end
end
