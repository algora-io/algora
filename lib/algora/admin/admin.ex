defmodule Algora.Admin do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Bounties.Claim
  alias Algora.Parser
  alias Algora.Payments
  alias Algora.Repo
  alias Algora.Workspace
  alias Algora.Workspace.Ticket

  require Logger

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

  defp update_claims(url, source_id) do
    Repo.update_all(from(t in Claim, where: t.url == ^url), set: [source_id: source_id])

    :ok
  rescue
    error -> {:error, error}
  end
end
