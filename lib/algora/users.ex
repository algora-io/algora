defmodule Algora.Users do
  import Ecto.Query
  import Ecto.Changeset
  require Algora.SQL

  alias Algora.Repo
  alias Algora.Users.User
  alias Algora.Users.Identity
  alias Algora.Payments.Transaction

  def base_query, do: User

  @type criteria :: %{
          optional(:id) => String.t(),
          optional(:limit) => non_neg_integer(),
          optional(:handle) => String.t(),
          optional(:handles) => [String.t()],
          optional(:min_earnings) => non_neg_integer(),
          optional(:sort_by_country) => String.t(),
          optional(:sort_by_tech_stack) => [String.t()]
        }

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:id, id}, query ->
        from([b] in query, where: b.id == ^id)

      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:handle, handle}, query ->
        from([b] in query, where: b.handle == ^handle)

      {:handles, handles}, query ->
        from([b] in query, where: b.handle in ^handles)

      {:min_earnings, min_amount}, query ->
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

  @spec list_developers_with(base_query :: Ecto.Query.t(), criteria :: criteria()) :: [map()]
  def list_developers_with(base_query, criteria \\ []) do
    criteria = Keyword.merge([limit: 10], criteria)

    base_users =
      base_query
      |> where([u], u.type == :individual)
      |> select([b], b.id)

    earnings_query =
      from t in Transaction,
        where: t.type == :credit and t.status == :succeeded,
        group_by: t.user_id,
        select: %{
          user_id: t.user_id,
          total_earned: sum(t.net_amount)
        }

    bounties_query =
      from t in Transaction,
        where: t.type == :credit and t.status == :succeeded and not is_nil(t.bounty_id),
        group_by: t.user_id,
        select: %{
          user_id: t.user_id,
          bounties_count: count(fragment("DISTINCT ?", t.bounty_id))
        }

    projects_query =
      from t in Transaction,
        join: lt in assoc(t, :linked_transaction),
        where: t.type == :credit and t.status == :succeeded and lt.type == :debit,
        group_by: t.user_id,
        select: %{
          user_id: t.user_id,
          projects_count: count(fragment("DISTINCT ?", lt.user_id))
        }

    User
    |> join(:inner, [u], b in subquery(base_users), as: :base, on: u.id == b.id)
    |> join(:left, [u], e in subquery(earnings_query), as: :earnings, on: e.user_id == u.id)
    |> join(:left, [u], b in subquery(bounties_query), as: :bounties, on: b.user_id == u.id)
    |> join(:left, [u], p in subquery(projects_query), as: :projects, on: p.user_id == u.id)
    |> apply_criteria(criteria)
    |> order_by([earnings: e], desc_nulls_last: e.total_earned)
    |> order_by([u], desc: u.id)
    |> select([u, earnings: e, bounties: b, projects: p], %{
      id: u.id,
      handle: u.handle,
      name: u.name,
      avatar_url: u.avatar_url,
      bio: u.bio,
      country: u.country,
      tech_stack: u.tech_stack,
      total_earned: Algora.SQL.money_or_zero(e.total_earned),
      completed_bounties_count: coalesce(b.bounties_count, 0),
      contributed_projects_count: coalesce(p.projects_count, 0),
      hourly_rate_min: u.hourly_rate_min,
      hourly_rate_max: u.hourly_rate_max,
      hours_per_week: u.hours_per_week
    })
    |> Repo.all()
    |> Enum.map(&User.after_load/1)
    |> Enum.map(fn user ->
      Map.merge(user, %{
        flag: get_flag(user),
        message: """
        Hey 👋

        I'm a #{Enum.join(Enum.take(user.tech_stack, 1), ", ")} dev who loves building cool stuff. Always excited to work on new projects - would love to chat!
        """
      })
    end)
  end

  def list_developers(criteria \\ []) do
    base_query()
    |> list_developers_with(criteria)
  end

  def fetch_developer(id) do
    case list_developers(id: id, limit: 1) do
      [developer] -> {:ok, developer}
      _ -> {:error, :not_found}
    end
  end

  def fetch_developer_by(criteria) do
    criteria = Keyword.put(criteria, :limit, 1)

    case list_developers(criteria) do
      [developer] -> {:ok, developer}
      _ -> {:error, :not_found}
    end
  end

  # HACK: eventually fetch dynamically
  def list_featured_developers(_country \\ nil) do
    list_developers(handles: ["carver", "jianyang", "aly", "john", "bighead"])
  end

  def list_orgs(opts) do
    query =
      from u in User,
        where: u.type == :organization and u.seeded == false and not is_nil(u.provider_login),
        limit: ^Keyword.get(opts, :limit, 100),
        order_by: [desc: u.priority, desc: u.stargazers_count]

    query
    |> Repo.all()
    |> Enum.map(fn user ->
      %{
        name: user.name || user.handle,
        handle: user.handle,
        flag: get_flag(user),
        amount: :rand.uniform(100_000),
        tech_stack: user.tech_stack |> Enum.take(6),
        avatar_url: user.avatar_url
      }
    end)
  end

  def get_users_map(user_ids) when is_list(user_ids) do
    Repo.all(from u in User, where: u.id in ^user_ids, select: {u.id, u})
  end

  def admin?(%User{} = user) do
    user.email in Algora.config([:admin_emails])
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

  ## User registration

  @doc """
  Registers a user from their GitHub information.
  """
  def register_github_user(primary_email, info, emails, token) do
    query =
      from(u in User,
        left_join: i in Identity,
        on: i.provider == "github" and u.provider_id == ^to_string(info["id"]),
        where: u.provider == "github" and u.provider_id == ^to_string(info["id"]),
        select: {u, i}
      )

    case Repo.one(query) do
      nil -> create_user(info, primary_email, emails, token)
      {user, nil} -> update_user(user, info, primary_email, emails, token)
      {user, _identity} -> update_github_token(user, token)
    end
  end

  def register_org(params) do
    User.org_registration_changeset(params) |> Repo.insert()
  end

  def create_user(info, primary_email, emails, token) do
    User.github_registration_changeset(nil, info, primary_email, emails, token)
    |> Repo.insert()
  end

  def update_user(user, info, primary_email, emails, token) do
    with {:ok, _} <-
           Identity.github_registration_changeset(user, info, primary_email, emails, token)
           |> Repo.insert(),
         {:ok, user} <-
           user
           |> User.github_registration_changeset(info, primary_email, emails, token)
           |> Repo.update() do
      {:ok, user}
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

  def get_access_token(%User{} = user) do
    case Repo.one(from(i in Identity, where: i.user_id == ^user.id and i.provider == "github")) do
      %Identity{provider_token: token} -> {:ok, token}
      _ -> {:error, :not_found}
    end
  end

  def get_random_access_tokens(n) when is_integer(n) and n > 0 do
    Identity
    |> where([i], i.provider == "github" and not is_nil(i.provider_token))
    |> order_by(fragment("RANDOM()"))
    |> limit(^n)
    |> select([i], i.provider_token)
    |> Repo.all()
  end

  defp update_github_token(%User{} = user, new_token) do
    identity =
      Repo.one!(from(i in Identity, where: i.user_id == ^user.id and i.provider == "github"))

    {:ok, _} =
      identity
      |> change()
      |> put_change(:provider_token, new_token)
      |> Repo.update()

    {:ok, Repo.preload(user, :identities, force: true)}
  end

  defp get_flag(user), do: Algora.Misc.CountryEmojis.get(user.country, "🌎")
end
