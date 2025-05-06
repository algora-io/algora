defmodule Algora.Admin do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Activities.SendDiscord
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.Jobs.JobPosting
  alias Algora.Parser
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Ticket

  require Logger

  def seed_job(opts \\ %{}) do
    with {:ok, user} <- Repo.fetch_by(User, handle: opts.org.handle),
         {:ok, user} <- user |> change(opts.org) |> Repo.update(),
         {:ok, job} <-
           Repo.insert(%JobPosting{
             id: Nanoid.generate(),
             user_id: user.id,
             company_name: user.name,
             company_url: user.website_url,
             title: opts.title,
             description: opts.description,
             tech_stack: opts.tech_stack || Enum.take(user.tech_stack, 1),
             status: opts[:status] || :initialized,
             location: opts[:location],
             compensation: opts[:compensation],
             seniority: opts[:seniority]
           }) do
      dbg("#{AlgoraWeb.Endpoint.url()}/#{user.handle}/jobs/#{job.id}")
      {:ok, job}
    end
  end

  def sync_contributions(opts \\ []) do
    query =
      User
      |> where([u], not is_nil(u.handle))
      |> where([u], not is_nil(u.provider_login))
      |> where([u], u.type == :individual)
      |> where([u], fragment("not exists (select 1 from user_contributions where user_contributions.user_id = ?)", u.id))

    query =
      if handles = opts[:handles] do
        where(query, [u], u.handle in ^handles)
      else
        query
      end

    query =
      if limit = opts[:limit] do
        limit(query, ^limit)
      else
        query
      end

    Repo.transaction(
      fn ->
        if opts[:dry_run] do
          query
          |> Repo.stream()
          |> Enum.to_list()
          |> length()
          |> IO.puts()
        else
          query
          |> Repo.stream()
          |> Enum.each(fn user ->
            %{provider_login: user.provider_login}
            |> Workspace.Jobs.FetchTopContributions.new()
            |> Oban.insert()
            |> case do
              {:ok, _job} -> IO.puts("Enqueued job for #{user.provider_login}")
              {:error, error} -> IO.puts("Failed to enqueue job for #{user.provider_login}: #{inspect(error)}")
            end
          end)
        end
      end,
      timeout: :infinity
    )
  end

  def release_payment(tx_id) do
    Repo.transact(fn ->
      {_, [tx]} =
        Repo.update_all(from(t in Transaction, where: t.id == ^tx_id, select: t),
          set: [status: :succeeded, succeeded_at: DateTime.utc_now()]
        )

      Repo.update_all(from(b in Bounty, where: b.id == ^tx.bounty_id), set: [status: :paid])

      activities_result = Repo.insert_activity(tx, %{type: :transaction_succeeded, notify_users: [tx.user_id]})

      jobs_result =
        case Payments.fetch_active_account(tx.user_id) do
          {:ok, _account} ->
            %{credit_id: tx.id}
            |> Payments.Jobs.ExecutePendingTransfer.new()
            |> Oban.insert()

          {:error, :no_active_account} ->
            Logger.warning("No active account for user #{tx.user_id}")

            %{credit_id: tx.id}
            |> Bounties.Jobs.PromptPayoutConnect.new()
            |> Oban.insert()
        end

      with {:ok, _} <- activities_result,
           {:ok, _} <- jobs_result do
        Payments.broadcast()
        {:ok, nil}
      else
        {:error, reason} ->
          Logger.error("Failed to update transactions: #{inspect(reason)}")
          {:error, :failed_to_update_transactions}

        error ->
          Logger.error("Failed to update transactions: #{inspect(error)}")
          {:error, :failed_to_update_transactions}
      end
    end)
  end

  def refresh_bounty(url) do
    with %{owner: owner, repo: repo, number: number} <- parse_ticket_url(url),
         {:ok, ticket} <- Workspace.ensure_ticket(token_for(owner), owner, repo, number) do
      Bounties.try_refresh_bounty_response(token_for(owner), %{owner: owner, repo: repo, number: number}, ticket)
    end
  end

  def create_tip_intent(recipient, amount, ticket_ref) do
    with installation_id when not is_nil(installation_id) <- Workspace.get_installation_id_by_owner(ticket_ref.owner) do
      Bounties.build_tip_intent(
        %{
          recipient: recipient,
          amount: amount,
          ticket_ref: ticket_ref
        },
        installation_id: installation_id
      )
    end
  end

  def remove_label(url, amount) do
    %{owner: owner, repo: repo, number: number} = parse_ticket_url(url)

    with installation_id when not is_nil(installation_id) <- Workspace.get_installation_id_by_owner(owner),
         {:ok, token} <- Github.get_installation_token(installation_id) do
      Workspace.remove_amount_label(token, owner, repo, number, Money.parse(amount))
    end
  end

  def add_label(url, amount) do
    %{owner: owner, repo: repo, number: number} = parse_ticket_url(url)

    with installation_id when not is_nil(installation_id) <- Workspace.get_installation_id_by_owner(owner),
         {:ok, token} <- Github.get_installation_token(installation_id) do
      Workspace.add_amount_label(token, owner, repo, number, Money.parse(amount))
    end
  end

  def remove_comment(url, id) do
    %{owner: owner, repo: repo, number: _number} = parse_ticket_url(url)

    with installation_id when not is_nil(installation_id) <- Workspace.get_installation_id_by_owner(owner),
         {:ok, token} <- Github.get_installation_token(installation_id),
         # TODO: properly parse DELETE responses in Github.Client
         {:error, %Jason.DecodeError{data: ""}} <-
           Github.Client.fetch(token, "/repos/#{owner}/#{repo}/issues/comments/#{id}", "DELETE") do
      :ok
    end
  end

  def backfill_labels(org_handle, opts \\ []) do
    with org when not is_nil(org) <- Repo.get_by(User, handle: org_handle),
         installation_id when not is_nil(installation_id) <- Workspace.get_installation_id_by_owner(org.provider_login),
         {:ok, token} <- Github.get_installation_token(installation_id) do
      bounties =
        Bounties.list_bounties(
          owner_id: org.id,
          limit: :infinity,
          status: :open
        )

      Enum.each(bounties, fn bounty ->
        if opts[:dry_run] do
          Logger.info("#{org.provider_login} - #{bounty.repository.name} - #{bounty.ticket.number} - #{bounty.amount}")
        else
          Workspace.add_amount_label(
            token,
            org.provider_login,
            bounty.repository.name,
            bounty.ticket.number,
            bounty.amount
          )
        end
      end)
    end
  end

  def init_contributors(repo_owner, repo_name) do
    with {:ok, repo} <- Workspace.ensure_repository(token(), repo_owner, repo_name) do
      Workspace.ensure_contributors(token(), repo)
    end
  end

  def migrate_user!(old_user_id, new_user_id) do
    old_user = Accounts.get_user!(old_user_id)

    Repo.transact(fn ->
      Accounts.migrate_user(old_user_id, new_user_id)

      Repo.update_all(
        from(i in Identity, where: i.user_id == ^old_user_id),
        set: [user_id: new_user_id]
      )

      Repo.update_all(from(u in User, where: u.id == ^old_user_id),
        set: [
          provider: nil,
          provider_id: nil,
          provider_meta: nil,
          provider_login: nil
        ]
      )

      Repo.update_all(from(u in User, where: u.id == ^new_user_id),
        set: [
          provider: old_user.provider,
          provider_id: old_user.provider_id,
          provider_meta: old_user.provider_meta,
          provider_login: old_user.provider_login
        ]
      )

      :ok
    end)
  end

  def find_claims(url) do
    %{owner: owner, repo: repo, number: number} = parse_ticket_url(url)

    Repo.all(
      from c in Claim,
        join: s in assoc(c, :source),
        join: r in assoc(s, :repository),
        join: ro in assoc(r, :user),
        join: u in assoc(c, :user),
        where: ro.provider == "github",
        where: ro.provider_login == ^owner,
        where: r.name == ^repo,
        where: s.number == ^number,
        select_merge: %{user: u}
    )
  end

  def claim_bounty(source_url, target_url, opts \\ []) do
    source_ticket_ref = parse_ticket_url(source_url)
    target_ticket_ref = parse_ticket_url(target_url)

    with installation_id when not is_nil(installation_id) <-
           Workspace.get_installation_id_by_owner(target_ticket_ref.owner),
         {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, source_ticket} <-
           Workspace.ensure_ticket(token, source_ticket_ref.owner, source_ticket_ref.repo, source_ticket_ref.number),
         {:ok, user} <- Workspace.ensure_user(token, source_ticket.provider_meta["user"]["login"]),
         {:ok, target_ticket} <-
           Workspace.ensure_ticket(token, target_ticket_ref.owner, target_ticket_ref.repo, target_ticket_ref.number),
         {:ok, claims} <-
           Bounties.claim_bounty(
             %{
               user: user,
               coauthor_provider_logins: opts[:splits] || [],
               target_ticket_ref: target_ticket_ref,
               source_ticket_ref: source_ticket_ref,
               status: if(source_ticket.provider_meta["pull_request"]["merged_at"], do: :approved, else: :pending),
               type: :pull_request
             },
             installation_id: installation_id
           ) do
      Bounties.try_refresh_bounty_response(token, target_ticket_ref, target_ticket)
      {:ok, claims}
    end
  end

  def prompt_payment(url, id, solver, sponsor) do
    %{owner: owner, repo: repo, number: number} = parse_ticket_url(url)

    Github.create_issue_comment(token_for(owner), owner, repo, number, """
    🎉 The pull request of @#{solver} has been merged. The bounty can be rewarded [here](#{AlgoraWeb.Endpoint.url()}/claims/#{id})

    cc @#{sponsor}
    """)
  end

  def autopay_pr(url) do
    %{owner: owner, repo: repo, number: number} = parse_ticket_url(url)

    with installation_id when not is_nil(installation_id) <- Workspace.get_installation_id_by_owner(owner),
         {:ok, installation} <-
           Workspace.fetch_installation_by(
             provider: "github",
             provider_id: to_string(installation_id)
           ),
         {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, source} <- Workspace.ensure_ticket(token, owner, repo, number) do
      claims =
        case Repo.one(
               from c in Claim,
                 join: s in assoc(c, :source),
                 join: u in assoc(c, :user),
                 where: c.status != :cancelled,
                 where: s.id == ^source.id,
                 where:
                   fragment(
                     "NOT EXISTS (SELECT 1 FROM transactions t WHERE t.claim_id = ? AND t.status = ANY(?))",
                     c.id,
                     ^["initialized", "processing", "succeeded"]
                   ),
                 order_by: [asc: c.inserted_at],
                 limit: 1
             ) do
          nil ->
            []

          %Claim{group_id: group_id} ->
            Repo.update_all(
              from(c in Claim, where: c.group_id == ^group_id, where: c.status != :cancelled),
              set: [status: :approved]
            )

            Repo.all(
              from c in Claim,
                join: t in assoc(c, :target),
                join: tr in assoc(t, :repository),
                join: tru in assoc(tr, :user),
                join: u in assoc(c, :user),
                where: c.group_id == ^group_id,
                where: c.status != :cancelled,
                order_by: [desc: c.group_share, asc: c.inserted_at],
                select_merge: %{
                  target: %{t | repository: %{tr | user: tru}},
                  user: u
                }
            )
        end

      if claims == [] do
        :noop
      else
        primary_claim = List.first(claims)

        bounties =
          Repo.all(
            from(b in Bounty,
              join: t in assoc(b, :ticket),
              join: o in assoc(b, :owner),
              left_join: u in assoc(b, :creator),
              left_join: c in assoc(o, :customer),
              left_join: p in assoc(c, :default_payment_method),
              where: t.id == ^primary_claim.target_id,
              select_merge: %{owner: %{o | customer: %{default_payment_method: p}}, creator: u}
            )
          )

        autopayable_bounty =
          Enum.find(
            bounties,
            &(not &1.autopay_disabled and
                &1.owner.id == installation.connected_user_id and
                not is_nil(&1.owner.customer) and
                not is_nil(&1.owner.customer.default_payment_method))
          )

        if autopayable_bounty do
          with {:ok, invoice} <-
                 Bounties.create_invoice(
                   %{
                     owner: autopayable_bounty.owner,
                     amount: autopayable_bounty.amount,
                     idempotency_key: "bounty-#{autopayable_bounty.id}"
                   },
                   ticket_ref: %{owner: owner, repo: repo, number: number},
                   bounty: autopayable_bounty,
                   claims: claims
                 ),
               {:ok, _invoice} <-
                 Algora.PSP.Invoice.pay(
                   invoice,
                   %{
                     payment_method: autopayable_bounty.owner.customer.default_payment_method.provider_id,
                     off_session: true
                   }
                 ) do
            Algora.Admin.alert(
              "Autopay successful (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}).",
              :info
            )

            :ok
          else
            {:error, reason} ->
              Algora.Admin.alert(
                "Autopay failed (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}): #{inspect(reason)}",
                :error
              )

              :error
          end
        end
      end
    end
  end

  def comment(url, body) do
    %{owner: owner, repo: repo, number: number} = parse_ticket_url(url)
    Github.create_issue_comment(token_for(owner), owner, repo, number, body)
  end

  defp parse_ticket_url(url) do
    case Parser.full_ticket_ref(url) do
      {:ok, [ticket_ref: [owner: owner, repo: repo, type: _type, number: number]], _, _, _, _} ->
        %{owner: owner, repo: repo, number: number}

      error ->
        raise error
    end
  end

  defp token_for(user) do
    with installation_id when not is_nil(installation_id) <-
           Workspace.get_installation_id_by_owner(user),
         {:ok, token} <- Github.get_installation_token(installation_id) do
      token
    else
      _ -> raise "No installation found for #{user}"
    end
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
    magic(if(String.match?(identifier, ~r/@/), do: :email, else: :handle), identifier, return_to)
  end

  def screenshot(path), do: AlgoraWeb.OGImageController.take_and_upload_screenshot([path])

  def alert(message, severity \\ :error)

  def alert(message, :error = severity) do
    Logger.error(message)

    %{
      url: Algora.config([:discord, :webhook_url]),
      payload: %{
        embeds: [
          %{
            color: color(severity),
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

  def alert(message, :critical = severity) do
    Logger.error(message)

    email_job =
      Algora.Activities.SendEmail.changeset(%{
        title: "#{message}",
        body: message,
        name: "Action required",
        email: "info@algora.io"
      })

    discord_job =
      SendDiscord.changeset(%{
        url: Algora.Settings.get("discord_webhook_url")["critical"] || Algora.config([:discord, :webhook_url]),
        payload: %{
          embeds: [
            %{color: color(severity), title: "Action required", description: message, timestamp: DateTime.utc_now()}
          ]
        }
      })

    Oban.insert_all([email_job, discord_job])
  end

  def alert(message, severity) do
    Logger.info(message)

    %{
      url: Algora.config([:discord, :webhook_url]),
      payload: %{
        embeds: [
          %{
            color: color(severity),
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

  def color(:critical), do: 0xEF4444
  def color(:error), do: 0xEF4444
  def color(:debug), do: 0x64748B
  def color(:info), do: 0xF59E0B
  def color(_), do: 0xF59E0B

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

  def seed_installation(installation_id, user_id) do
    with {:ok, installation} <- Github.get_installation(installation_id),
         {:ok, user} <- Repo.fetch_by(User, id: user_id),
         {:ok, org} <- Repo.fetch_by(User, provider: "github", provider_id: to_string(installation["target_id"])) do
      Workspace.upsert_installation(installation, user, org, user)
    end
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
