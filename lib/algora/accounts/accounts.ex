defmodule Algora.Accounts do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Accounts.UserMedia
  alias Algora.Bounties.Bounty
  alias Algora.Contracts.Contract
  alias Algora.Github
  alias Algora.Organizations
  alias Algora.Organizations.Member
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace.Contributor
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Repository
  alias Algora.Workspace.Ticket
  alias Swoosh.Email

  require Algora.SQL
  require Logger

  def base_query, do: User

  @type criterion ::
          {:id, binary()}
          | {:ids, [binary()]}
          | {:org_id, binary()}
          | {:limit, non_neg_integer()}
          | {:handle, String.t()}
          | {:handles, [String.t()]}
          | {:earnings_gt, Money.t()}
          | {:sort_by_country, String.t()}
          | {:sort_by_tech_stack, [String.t()]}

  @spec apply_criteria(Ecto.Queryable.t(), [criterion()]) :: Ecto.Queryable.t()
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:id, id}, query ->
        from([b] in query, where: b.id == ^id)

      {:ids, ids}, query ->
        from([b] in query, where: b.id in ^ids)

      {:limit, :infinity}, query ->
        query

      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:handle, handle}, query ->
        from([b] in query, where: b.handle == ^handle)

      {:handles, handles}, query ->
        from([b] in query, where: b.handle in ^handles)

      {:earnings_gt, min_amount}, query ->
        from([b, earnings: e] in query,
          where:
            fragment(
              "?::money_with_currency >= (?, ?)::money_with_currency",
              e.total_earned,
              ^to_string(min_amount.currency),
              ^min_amount.amount
            )
        )

      {:sort_by_country, country}, query ->
        from([b] in query,
          order_by: [fragment("CASE WHEN ? = ? THEN 0 ELSE 1 END", b.country, ^country)]
        )

      {:sort_by_tech_stack, tech_stack}, query ->
        from([b] in query,
          order_by: [
            fragment(
              "array_length(ARRAY(SELECT UNNEST(?::citext[]) INTERSECT SELECT UNNEST(?::citext[])), 1) DESC NULLS LAST",
              b.tech_stack,
              ^tech_stack
            )
          ]
        )

      _, query ->
        query
    end)
  end

  def list_developers_with(base_query, criteria \\ []) do
    criteria = Keyword.merge([limit: 10], criteria)

    base_users =
      base_query
      |> where([u], u.type == :individual)
      |> select([b], b.id)

    filter_org_id =
      if org_id = criteria[:org_id],
        do: dynamic([linked_transaction: ltx, repository: r], ltx.user_id == ^org_id or r.user_id == ^org_id),
        else: true

    earnings_query =
      from tx in Transaction,
        where: tx.type == :credit and tx.status == :succeeded,
        left_join: ltx in assoc(tx, :linked_transaction),
        as: :linked_transaction,
        left_join: b in assoc(tx, :bounty),
        left_join: t in assoc(b, :ticket),
        left_join: r in assoc(t, :repository),
        as: :repository,
        where: ^filter_org_id,
        group_by: tx.user_id,
        select: %{
          user_id: tx.user_id,
          total_earned: sum(tx.net_amount)
        }

    transactions_query =
      from t in Transaction,
        where: t.type == :credit and t.status == :succeeded,
        group_by: t.user_id,
        select: %{
          user_id: t.user_id,
          transactions_count: count(t.id)
        }

    projects_query =
      from tx in Transaction,
        where: tx.type == :credit and tx.status == :succeeded,
        left_join: bounty in assoc(tx, :bounty),
        left_join: tip in assoc(tx, :tip),
        join: t in Ticket,
        on: t.id == bounty.ticket_id or t.id == tip.ticket_id,
        left_join: r in assoc(t, :repository),
        group_by: tx.user_id,
        select: %{
          user_id: tx.user_id,
          projects_count: count(fragment("DISTINCT ?", r.user_id))
        }

    User
    |> join(:inner, [u], b in subquery(base_users), as: :base, on: u.id == b.id)
    |> join(:left, [u], e in subquery(earnings_query), as: :earnings, on: e.user_id == u.id)
    |> join(:left, [u], t in subquery(transactions_query), as: :transactions, on: t.user_id == u.id)
    |> join(:left, [u], p in subquery(projects_query), as: :projects, on: p.user_id == u.id)
    |> apply_criteria(criteria)
    |> order_by([earnings: e], desc_nulls_last: e.total_earned)
    |> order_by([u], desc: u.id)
    |> select([u, earnings: e, transactions: t, projects: p], %{
      type: u.type,
      id: u.id,
      handle: u.handle,
      name: u.name,
      provider_login: u.provider_login,
      provider_meta: u.provider_meta,
      linkedin_url: u.linkedin_url,
      linkedin_meta: u.linkedin_meta,
      avatar_url: u.avatar_url,
      bio: u.bio,
      system_bio: u.system_bio,
      location: u.location,
      country: u.country,
      tech_stack: u.tech_stack,
      total_earned: Algora.SQL.money_or_zero(e.total_earned),
      transactions_count: coalesce(t.transactions_count, 0),
      contributed_projects_count: coalesce(p.projects_count, 0),
      hourly_rate_min: u.hourly_rate_min,
      hourly_rate_max: u.hourly_rate_max,
      hours_per_week: u.hours_per_week
    })
    |> Repo.all()
    |> Enum.map(&User.after_load/1)
  end

  def list_developers(criteria \\ []) do
    list_developers_with(base_query(), criteria)
  end

  def list_contributed_projects(user, opts \\ []) do
    # order_by =
    #   if tech_stack = opts[:tech_stack] do
    #     dynamic([tx, r: r], fragment("? && ?::citext[]", r.tech_stack, ^tech_stack))
    #   else
    #     true
    #   end

    Repo.all(
      from tx in Transaction,
        where: tx.type == :credit,
        where: tx.status == :succeeded,
        where: tx.user_id == ^user.id,
        join: ltx in assoc(tx, :linked_transaction),
        left_join: bounty in assoc(tx, :bounty),
        left_join: tip in assoc(tx, :tip),
        join: t in Ticket,
        on: t.id == bounty.ticket_id or t.id == tip.ticket_id,
        left_join: r in assoc(t, :repository),
        as: :r,
        left_join: ro in User,
        on: fragment("? = (case when ? is null then ? else ? end)", ro.id, r.user_id, ltx.user_id, r.user_id),
        # order_by: ^[desc: order_by],
        order_by: [desc: sum(tx.net_amount)],
        group_by: [ro.id],
        select: {ro, sum(tx.net_amount)},
        limit: ^opts[:limit]
    )
  end

  @spec fetch_developer(binary()) :: {:ok, User.t()} | {:error, :not_found}
  def fetch_developer(id) do
    case list_developers(id: id, limit: 1) do
      [developer] -> {:ok, developer}
      _ -> {:error, :not_found}
    end
  end

  @spec fetch_developer_by([criterion()]) :: {:ok, User.t()} | {:error, :not_found}
  def fetch_developer_by(criteria) do
    criteria = Keyword.put(criteria, :limit, 1)

    case list_developers(criteria) do
      [developer] -> {:ok, developer}
      _ -> {:error, :not_found}
    end
  end

  def list_featured_developers(_country \\ nil) do
    case Algora.Settings.get_featured_developers() do
      handles when is_list(handles) and handles != [] ->
        list_developers(handles: handles)

      _ ->
        list_developers(limit: 5)
    end
  end

  def get_users_map(user_ids) when is_list(user_ids) do
    Repo.all(from u in User, where: u.id in ^user_ids, select: {u.id, u})
  end

  def update_settings(%User{} = user, attrs) do
    user |> User.settings_changeset(attrs) |> Repo.update()
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by(fields), do: Repo.get_by(User, fields)

  def get_user_by!(fields), do: Repo.get_by!(User, fields)

  @spec fetch_user_by(clauses :: Keyword.t() | map()) ::
          {:ok, User.t()} | {:error, :not_found}
  def fetch_user_by(clauses) do
    Repo.fetch_by(User, clauses)
  end

  ## User registration

  @doc """
  Registers a user from their GitHub information.
  """
  def register_github_user(current_user, primary_email, info, emails, token) do
    matching_users =
      Repo.all(
        from u in User,
          where: u.email == ^primary_email or (u.provider == "github" and u.provider_id == ^to_string(info["id"]))
      )

    primary_user =
      case {current_user, matching_users} do
        {current_user, _} when not is_nil(current_user) -> current_user
        {_, [user]} -> user
        {_, users} -> Enum.find(users, &(&1.provider == "github" and &1.provider_id == to_string(info["id"])))
      end

    case primary_user do
      nil -> create_user(info, primary_email, emails, token)
      user -> update_user(user, info, primary_email, emails, token)
    end
  end

  def create_user(info, primary_email, emails, token) do
    nil
    |> User.github_registration_changeset(info, primary_email, emails, token)
    |> Repo.insert(returning: true)
  end

  def update_user(user, info, primary_email, emails, token) do
    github_user = Repo.get_by(User, provider: "github", provider_id: to_string(info["id"]))
    email_user = Repo.get_by(User, email: primary_email)

    Repo.transact(fn ->
      Repo.delete_all(from(i in Identity, where: i.provider == "github" and i.provider_id == ^to_string(info["id"])))

      with true <- github_user && github_user.id != user.id,
           {:ok, github_user} <-
             github_user |> change(provider: nil, provider_id: nil, provider_login: nil) |> Repo.update(),
           {:ok, _} <-
             Repo.insert_activity(github_user, %{
               type: :user_migrated,
               meta: %{provider: "github", provider_id: to_string(info["id"])},
               changes: %{from: %{provider: "github", provider_id: to_string(info["id"])}, to: %{}},
               notify_users: []
             }) do
        migrate_user(github_user.id, user.id)
      else
        {:error, reason} ->
          Logger.error("Failed to migrate user: #{inspect(reason)}")

        _ ->
          :ok
      end

      with true <- email_user && email_user.id != user.id,
           {:ok, email_user} <- email_user |> change(email: nil) |> Repo.update(),
           {:ok, _} <-
             Repo.insert_activity(email_user, %{
               type: :user_migrated,
               meta: %{email: primary_email},
               changes: %{from: %{email: primary_email}, to: %{}},
               notify_users: []
             }) do
        migrate_user(email_user.id, user.id)
      else
        {:error, reason} ->
          Logger.error("Failed to migrate user: #{inspect(reason)}")

        _ ->
          :ok
      end

      identity_changeset = Identity.github_registration_changeset(user, info, primary_email, emails, token)
      user_changeset = User.github_registration_changeset(user, info, primary_email, emails, token)

      with {:ok, _} <- Repo.insert(identity_changeset),
           {:ok, user} <- Repo.update(user_changeset) do
        {:ok, user}
      else
        {:error, reason} ->
          Logger.error("Failed to update user: #{inspect(reason)}")
          {:error, reason}
      end
    end)
  end

  def migrate_user(old_user_id, new_user_id) do
    # TODO: enqueue job
    Repo.update_all(
      from(r in Repository, where: r.user_id == ^old_user_id),
      set: [user_id: new_user_id]
    )

    Repo.update_all(
      from(m in Member, where: m.user_id == ^old_user_id),
      set: [user_id: new_user_id]
    )

    Repo.update_all(
      from(c in Contributor, where: c.user_id == ^old_user_id),
      set: [user_id: new_user_id]
    )

    Repo.update_all(
      from(c in Contract, where: c.contractor_id == ^old_user_id),
      set: [contractor_id: new_user_id]
    )

    Repo.update_all(
      from(i in Installation, where: i.owner_id == ^old_user_id),
      set: [owner_id: new_user_id]
    )

    Repo.update_all(
      from(i in Installation, where: i.provider_user_id == ^old_user_id),
      set: [provider_user_id: new_user_id]
    )

    Repo.update_all(
      from(i in Installation, where: i.connected_user_id == ^old_user_id),
      set: [connected_user_id: new_user_id]
    )

    :ok
  end

  def register_org(params) do
    params |> User.org_registration_changeset() |> Repo.insert(returning: true)
  end

  def auto_join_orgs(user) do
    domain = user.email |> String.split("@") |> List.last()

    orgs =
      Repo.all(
        from o in User,
          left_join: m in Member,
          on: m.org_id == o.id and m.user_id == ^user.id,
          where: o.domain == ^domain and is_nil(m.id)
      )

    Enum.each(orgs, fn org ->
      case Organizations.create_member(org, user, :mod) do
        {:ok, _member} ->
          Algora.Activities.alert("#{user.email} joined #{org.name}", :info)

        {:error, _reason} ->
          Algora.Activities.alert("#{user.email} failed to join #{org.name}", :error)
      end
    end)

    if org = List.first(orgs) do
      update_settings(user, %{last_context: org.handle})
    end

    orgs
  end

  def get_or_register_user(email, attr \\ %{}) do
    res =
      case get_user_by_email(email) do
        nil -> attr |> Map.put(:email, email) |> register_org()
        user -> {:ok, user}
      end

    with {:ok, user} <- res do
      auto_join_orgs(user)
      res
    end
  end

  # def get_user_by_provider_email(provider, email) when provider in [:github] do
  #   query =
  #     from(u in User,
  #       join: i in assoc(u, :identities),
  #       where:
  #         i.provider == ^to_string(provider) and
  #           fragment("lower(?)", u.email) == ^String.downcase(email)
  #     )

  #   Repo.one(query)
  # end

  def get_user_by_provider_id(provider, id) when provider in [:github] do
    query =
      from(u in User,
        left_join: i in Identity,
        on: i.provider == "github" and u.provider_id == ^to_string(id),
        where: u.provider == "github" and u.provider_id == ^to_string(id),
        select: {u, i}
      )

    Repo.one(query)
  end

  def get_user_by_handle(handle) do
    query =
      from(u in User,
        where: u.handle == ^handle,
        select: u
      )

    Repo.one(query)
  end

  def get_access_token(%User{} = user) do
    case Repo.one(from(i in Identity, where: i.user_id == ^user.id and i.provider == "github")) do
      %Identity{provider_token: token} -> {:ok, token}
      _ -> {:error, :not_found}
    end
  end

  def has_fresh_token?(nil), do: false

  def has_fresh_token?(%User{} = user) do
    # TODO: use refresh tokens and check expiration
    case get_access_token(user) do
      {:ok, token} ->
        case Github.get_user(token, user.provider_id) do
          {:ok, _} -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  def get_random_access_tokens(n) when is_integer(n) and n > 0 do
    case Identity
         |> where([i], i.provider == "github" and not is_nil(i.provider_token))
         |> order_by(fragment("RANDOM()"))
         |> limit(^n)
         |> select([i], i.provider_token)
         |> Repo.all() do
      [""] -> []
      tokens -> tokens
    end
  end

  def last_context(nil), do: "nil"

  def last_context(%User{last_context: nil} = user) do
    contexts = get_contexts(user)

    last_debit_query =
      from(t in Transaction,
        join: u in assoc(t, :user),
        where: t.type == :debit,
        where: u.id in ^Enum.map(contexts, & &1.id),
        order_by: [desc: t.succeeded_at],
        limit: 1,
        select_merge: %{user: u}
      )

    last_bounty_query =
      from(b in Bounty,
        join: c in assoc(b, :creator),
        where: c.id in ^Enum.map(contexts, & &1.id),
        order_by: [desc: b.inserted_at],
        limit: 1,
        select_merge: %{creator: c}
      )

    new_context =
      cond do
        last_debit = Repo.one(last_debit_query) -> last_debit.user.handle
        last_bounty = Repo.one(last_bounty_query) -> last_bounty.owner.handle
        true -> default_context()
      end

    update_settings(user, %{last_context: new_context})

    new_context
  end

  def last_context(%User{last_context: last_context}), do: last_context

  def get_last_context_user(nil), do: nil

  def get_last_context_user(%User{} = user) do
    case last_context(user) do
      "personal" ->
        user

      "preview/" <> ctx ->
        case String.split(ctx, "/") do
          [id, _repo_owner, _repo_name] -> get_user(id)
          _ -> nil
        end

      "repo/" <> _repo_full_name ->
        user

      last_context ->
        get_user_by_handle(last_context)
    end
  end

  def ensure_org_context(%User{} = user) do
    case get_last_context_user(user) do
      %User{type: :organization} = ctx ->
        {:ok, ctx}

      _ ->
        orgs = Organizations.get_user_orgs(user)

        new_context = if orgs == [], do: user, else: List.first(orgs)

        update_settings(user, %{last_context: new_context.handle})
    end
  end

  def default_context, do: "personal"

  def set_context(%User{} = user, "personal") do
    update_settings(user, %{last_context: "personal"})
  end

  def set_context(%User{} = user, "preview/" <> id) do
    context =
      case Repo.get(User, id) do
        nil ->
          nil

        user ->
          case user.last_context do
            "repo/" <> repo_full_name -> "preview/#{id}/#{repo_full_name}"
            _ -> nil
          end
      end

    case context do
      nil -> {:error, :not_found}
      context -> update_settings(user, %{last_context: context})
    end
  end

  def set_context(%User{} = user, context) do
    if context == user.handle do
      update_settings(user, %{last_context: context})
    else
      membership =
        Repo.one(
          from(m in Member,
            join: o in assoc(m, :org),
            where: m.user_id == ^user.id and o.handle == ^context
          )
        )

      if membership || user.is_admin do
        update_settings(user, %{last_context: context})
      else
        {:error, :unauthorized}
      end
    end
  end

  def get_contexts(nil), do: []

  def get_contexts(%User{} = user) do
    [user | Organizations.get_user_orgs(user)]
  end

  # TODO: fetch from db
  def list_community(tech_stack) do
    community_file = :algora |> :code.priv_dir() |> Path.join("dev/community/#{tech_stack}.json")

    with true <- File.exists?(community_file),
         {:ok, contents} <- File.read(community_file),
         {:ok, community} <- Jason.decode(contents) do
      community
    else
      _ -> []
    end
  end

  # TODO: remove hardcoded techs
  def list_techs do
    tech_order = [
      "TypeScript",
      "Rust",
      "Scala",
      "Python",
      "Go",
      "C++",
      "Java",
      "Swift",
      "PHP",
      "Elixir",
      "Haskell",
      "Ruby"
    ]

    :algora
    |> :code.priv_dir()
    |> Path.join("dev/community")
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.map(&String.trim_trailing(&1, ".json"))
    |> Enum.sort_by(fn tech -> Enum.find_index(tech_order, &(&1 == tech)) || 999 end)
  end

  def deliver_totp_signup_email(email, code) do
    email =
      Email.new()
      |> Email.to(email)
      |> Email.from({"Algora", "info@algora.io"})
      |> Email.subject("#{code} - Algora Sign-up Verification")
      |> Email.text_body("""
      Hi there,

      To complete the sign-up process; enter the 6-digit code in the original window:

      #{code}

      If you didn't request this link, you can safely ignore this email.

      --------------------------------------------------------------------------------

      For correspondence, please email the Algora founders at ioannis@algora.io and zafer@algora.io

      © 2025 Algora PBC.
      """)

    Algora.Mailer.deliver(email)
  end

  def deliver_totp_login_email(user, code) do
    email =
      Email.new()
      |> Email.to({user.display_name, user.email})
      |> Email.from({"Algora", "info@algora.io"})
      |> Email.subject("#{code} - Algora Sign-in Verification")
      |> Email.text_body("""
      Hello #{user.display_name},

      To complete the sign-in process; enter the 6-digit code in the original window:

      #{code}

      If you didn't request this link, you can safely ignore this email.

      --------------------------------------------------------------------------------

      For correspondence, please email the Algora founders at ioannis@algora.io and zafer@algora.io

      © 2025 Algora PBC.
      """)

    Algora.Mailer.deliver(email)
  end

  def list_user_media(%User{} = user) do
    Repo.all(from m in UserMedia, where: m.user_id == ^user.id)
  end

  def youtube_url?(url) do
    String.contains?(url, "youtube.com") or String.contains?(url, "youtu.be")
  end

  def canonicalize_youtube_url(url) do
    cond do
      # Handle youtu.be URLs
      String.contains?(url, "youtu.be/") ->
        id = url |> String.split("youtu.be/") |> List.last() |> String.split("?") |> List.first()
        "https://youtube.com/embed/#{id}"

      # Handle youtube.com/watch?v= URLs
      String.contains?(url, "youtube.com/watch?v=") ->
        id = url |> String.split("v=") |> List.last() |> String.split("&") |> List.first()
        "https://youtube.com/embed/#{id}"

      # Handle youtube.com/embed/ URLs
      String.contains?(url, "youtube.com/embed/") ->
        "https://youtube.com/embed/#{url |> String.split("embed/") |> List.last()}"

      true ->
        url
    end
  end

  def create_user_media(%User{} = user, attrs) do
    if youtube_url?(attrs["url"]) do
      %UserMedia{}
      |> UserMedia.changeset(
        attrs
        |> Map.put("user_id", user.id)
        |> Map.put("original_url", attrs["url"])
        |> Map.update!("url", &canonicalize_youtube_url/1)
      )
      |> Repo.insert()
    else
      with {:ok, %{body: body, headers: headers, status: status}} when status in 200..299 <-
             fetch_media(attrs["url"]),
           object_path = media_object_path(user.id, body),
           {:ok, _} <-
             Algora.S3.upload(body, object_path,
               content_type: extract_content_type(headers),
               cache_control: "public, max-age=31536000, immutable"
             ) do
        s3_url = Path.join(Algora.S3.bucket_url(), object_path)

        %UserMedia{}
        |> UserMedia.changeset(
          attrs
          |> Map.put("user_id", user.id)
          |> Map.put("original_url", attrs["url"])
          |> Map.put("url", s3_url)
        )
        |> Repo.insert()
      else
        {:ok, %{status: status}} ->
          Logger.error("Failed to process media: #{inspect(status)}")
          {:error, status}

        error ->
          Logger.error("Failed to process media: #{inspect(error)}")
          {:error, :media_processing_failed}
      end
    end
  end

  def fetch_or_create_user_media(%User{} = user, attrs) do
    # TODO: persist and compare against original URL
    case Repo.fetch_by(UserMedia, user_id: user.id, original_url: attrs["url"]) do
      {:ok, media} -> {:ok, media}
      _ -> create_user_media(user, attrs)
    end
  end

  defp media_object_path(user_id, body) do
    hash = :md5 |> :crypto.hash(body) |> Base.encode16(case: :lower)
    Path.join(["media", to_string(user_id), hash])
  end

  def fetch_media(url, redirect_count \\ 0) do
    if redirect_count > 3 do
      {:error, :too_many_redirects}
    else
      case :get |> Finch.build(url) |> Finch.request(Algora.Finch) do
        {:ok, %{status: status, headers: headers}} when status in 300..399 ->
          case List.keyfind(headers, "location", 0) do
            {_, location} -> fetch_media(location, redirect_count + 1)
            nil -> {:error, :missing_redirect_location}
          end

        {:ok, %{status: status}} when status in 400..499 ->
          new_url = url |> URI.parse() |> Map.put(:query, nil) |> to_string()

          if new_url == url do
            {:error, status}
          else
            fetch_media(new_url, redirect_count + 1)
          end

        other ->
          other
      end
    end
  end

  defp extract_content_type(headers) do
    case List.keyfind(headers, "content-type", 0) do
      {_, content_type} -> content_type
      nil -> "application/octet-stream"
    end
  end

  def delete_user_media(%UserMedia{} = media) do
    Repo.delete(media)
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
end
