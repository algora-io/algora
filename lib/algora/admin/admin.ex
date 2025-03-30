defmodule Algora.Admin do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Activities.SendDiscord
  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.LLM
  alias Algora.Parser
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Comment
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Ticket

  require Logger

  @llm_batch_size 2500

  def rewarded_pulls do
    Repo.all(
      from t in Ticket,
        join: c in Claim,
        on: c.source_id == t.id,
        join: tx in Transaction,
        on: tx.claim_id == c.id,
        where: tx.status == :succeeded,
        where: fragment("NOT EXISTS (SELECT 1 FROM comments WHERE comments.ticket_id = ?)", t.id),
        select: t.provider_meta["url"],
        order_by: [desc: :inserted_at]
    )
  end

  def magic(:email, email, return_to),
    do: AlgoraWeb.Endpoint.url() <> AlgoraWeb.UserAuth.generate_login_path(email, return_to)

  def magic(:handle, handle, return_to) do
    case Algora.Accounts.fetch_user_by(handle: handle) do
      {:ok, user} -> magic(:email, user.email, return_to)
      error -> {:error, error}
    end
  end

  def magic(identifier, return_to \\ nil) do
    if String.match?(identifier, ~r/@/) do
      magic(:email, identifier, return_to)
    else
      magic(:handle, identifier, return_to)
    end
  end

  def screenshot(path), do: AlgoraWeb.OGImageController.take_and_upload_screenshot([path])

  def alert(message, severity \\ :error)

  def alert(message, :error) do
    Logger.error(message)

    email_job =
      Algora.Activities.SendEmail.changeset(%{
        title: "Error: #{message}",
        body: message,
        name: "Algora Alert",
        email: "info@algora.io"
      })

    discord_job =
      SendDiscord.changeset(%{
        payload: %{embeds: [%{color: 0xEF4444, title: "Error", description: message, timestamp: DateTime.utc_now()}]}
      })

    Oban.insert_all([email_job, discord_job])
  end

  def alert(message, severity) do
    %{
      payload: %{
        embeds: [
          %{
            color: 0xF59E0B,
            title: severity |> to_string() |> String.capitalize(),
            description: message,
            timestamp: DateTime.utc_now()
          }
        ]
      }
    }
    |> SendDiscord.changeset()
    |> Oban.insert()
  end

  def token!, do: System.fetch_env!("ADMIN_GITHUB_TOKEN")
  def token, do: System.get_env("ADMIN_GITHUB_TOKEN")

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

  def admins_last_active do
    Algora.Repo.one(
      from u in User,
        where: u.is_admin == true,
        order_by: [desc: u.last_active_at],
        select: u.last_active_at,
        limit: 1
    )
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

  def backfill_comments! do
    {success, failure} =
      rewarded_pulls()
      |> Task.async_stream(&backfill_comments/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Comments backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_comments(url) do
    with {:ok, ticket} <- get_ticket_by_url(url),
         {:ok, comments} <- Github.Client.fetch(token!(), ticket.provider_meta["comments_url"]),
         {:ok, _} <- insert_comments(comments, ticket) do
      {:ok, comments}
    else
      {:error, "404 Not Found"} = error ->
        error

      error ->
        Logger.error("Failed to backfill comments for #{url}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp get_ticket_by_url(url) do
    case Repo.one(from t in Ticket, where: fragment("?->>'url' = ?", t.provider_meta, ^url)) do
      nil -> {:error, :not_found}
      ticket -> {:ok, ticket}
    end
  end

  defp insert_comments(comments, ticket) do
    comments
    |> Enum.reject(&is_bot_comment?/1)
    |> Enum.map(fn comment ->
      user = get_user(comment["user"])
      Comment.github_changeset(comment, ticket, user)
    end)
    |> Enum.reduce(Ecto.Multi.new(), fn changeset, multi ->
      Ecto.Multi.insert(multi, {:comment, changeset.changes.provider_id}, changeset,
        on_conflict: :nothing,
        conflict_target: [:provider, :provider_id]
      )
    end)
    |> Repo.transaction()
  end

  defp is_bot_comment?(comment) do
    user = comment["user"]
    user["type"] == "Bot" || String.ends_with?(user["login"], "[bot]")
  end

  defp get_user(user_data) do
    Repo.get_by(User, provider: "github", provider_id: to_string(user_data["id"]))
  end

  def analyze_comments do
    with {:ok, comments} <- get_unanalyzed_comments(limit: @llm_batch_size),
         comments = prepare_comments(comments),
         {:ok, results} <- analyze_comment_batches(comments) do
      # Mark all comments as analyzed, updating those with positive feedback
      Enum.each(comments, fn comment ->
        result = Enum.find(results, fn r -> r["comment_id"] == comment.id end)

        comment.comment
        |> Comment.mark_analyzed(result && result["analysis"])
        |> Repo.update!()
      end)

      {:ok, results}
    else
      {:error, :not_found} = error ->
        error

      error ->
        Logger.error("Failed to analyze comments: #{inspect(error)}")
        {:error, error}
    end
  end

  def get_unanalyzed_comments(opts \\ []) do
    comments =
      Repo.all(
        from c in Comment,
          where: is_nil(c.llm_analyzed_at),
          order_by: [asc: c.inserted_at],
          limit: ^opts[:limit]
      )

    {:ok, comments}
  end

  defp prepare_comments(comments) do
    comments
    |> Enum.reject(&is_long_code_comment?/1)
    |> Enum.map(fn comment ->
      %{
        id: comment.provider_id,
        body: clean_comment_body(comment.body),
        author: get_in(comment.provider_meta, ["user", "login"]),
        # Keep reference to original comment
        comment: comment
      }
    end)
  end

  defp is_long_code_comment?(comment) do
    body = comment.body || ""
    # Skip if more than 50% is code blocks or comment is too long
    code_blocks = Regex.scan(~r/```[\s\S]*?```/, body)
    total_length = String.length(body)
    code_length = code_blocks |> Enum.join() |> String.length()

    total_length > 2000 || (code_length > 0 && code_length / total_length > 0.5)
  end

  defp clean_comment_body(body) when is_binary(body) do
    body
    |> String.replace(~r/```[\s\S]*?```/, "[code block removed]")
    |> String.replace(~r/`[^`]*`/, "[inline code removed]")
    |> String.trim()
  end

  defp clean_comment_body(_), do: ""

  defp analyze_comment_batches(comments) do
    comments
    |> Enum.chunk_every(@llm_batch_size)
    |> Task.async_stream(&analyze_comment_batch/1, max_concurrency: 1, timeout: :infinity)
    |> Enum.reduce(
      {:ok, []},
      fn
        {:ok, {:ok, results}}, {:ok, acc} -> {:ok, acc ++ results}
        _, _error -> {:error, "Analysis failed"}
      end
    )
  end

  defp analyze_comment_batch(comments) do
    prompt = """
    Analyze these GitHub comments and identify ONLY the ones containing HIGHLY enthusiastic feedback or substantial appreciation for the PR author.
    We're looking for comments that go beyond simple approval - find comments that show genuine excitement, detailed appreciation, or meaningful recognition.

    Include ONLY comments that have elements like:
    - Strong enthusiasm ("This is amazing!", "Incredible work!", etc.)
    - Detailed appreciation of specific aspects of the work
    - Personal impact statements ("This will help so many people", "Can't wait to use this")
    - Recognition of exceptional effort or quality
    - Meaningful encouragement with specific details

    EXCLUDE simple approvals like:
    - "LGTM"
    - Basic thumbs up 👍
    - "Looks good"
    - "Approved"
    - Simple "Thanks"
    - Basic merge approvals

    Comments to analyze:
    #{Enum.map_join(comments, "\n\n", fn c -> "Comment #{c.id}:\n#{c.body}" end)}

    Return a JSON object with a single key "positive_comments" containing an array of objects.
    Each object should have:
    - comment_id: The comment ID
    - analysis: Brief explanation of why this comment shows exceptional enthusiasm or appreciation

    Only include comments showing genuine excitement or substantial appreciation.
    If no comments meet this high bar, return {"positive_comments": []}.
    """

    case LLM.chat(prompt) do
      {:ok, response} ->
        case Jason.decode(response) do
          {:ok, %{"positive_comments" => results}} -> {:ok, results}
          {:ok, _} -> {:ok, []}
          error -> error
        end

      error ->
        error
    end
  end
end
