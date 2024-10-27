defmodule Algora.Accounts do
  import Ecto.Query
  import Ecto.Changeset

  alias Algora.Repo
  alias Algora.Accounts.{User, Identity}

  @spec list_matching_devs(
          params :: %{
            optional(:country) => String.t(),
            optional(:limit) => non_neg_integer(),
            optional(:skills) => [String.t()]
          }
        ) :: [map()]
  def list_matching_devs(opts) do
    User
    |> where(type: :individual)
    |> filter_by_country(opts[:country])
    |> filter_by_skills(opts[:skills])
    |> limit(^Keyword.get(opts, :limit, 100))
    |> order_by(desc: :stargazers_count)
    |> Repo.all()
    |> Enum.map(fn user ->
      %{
        name: user.name || user.handle,
        handle: user.handle,
        flag: get_flag(user),
        skills: user.tech_stack |> Enum.take(6),
        amount: :rand.uniform(20_000),
        bounties: :rand.uniform(40),
        projects: :rand.uniform(10),
        avatar_url: user.avatar_url
      }
    end)
  end

  def list_orgs(opts) do
    query =
      from u in User,
        where: u.type == :organization and u.seeded == false and not(is_nil(u.provider_login)),
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
      {nil, nil} -> create_user(info, primary_email, emails, token)
      {user, nil} -> update_user(user, info, primary_email, emails, token)
      {user, _identity} -> update_github_token(user, token)
    end
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

  defp filter_by_country(query, nil), do: query

  defp filter_by_country(query, country),
    do: where(query, [u], u.country == ^String.upcase(country))

  defp filter_by_skills(query, nil), do: query

  defp filter_by_skills(query, skills) when is_list(skills) and length(skills) > 0 do
    query
    |> where([u], fragment("? && ?", u.tech_stack, ^skills))
  end

  defp get_flag(user), do: Algora.Misc.CountryEmojis.get(user.country, "🌎")
end
