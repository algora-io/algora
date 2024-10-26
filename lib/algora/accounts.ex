defmodule Algora.Accounts do
  import Ecto.Query
  import Ecto.Changeset

  alias Algora.Repo
  alias Algora.Accounts.{User, Identity}

  def list_users(opts) do
    User
    |> where(type: :individual)
    |> filter_by_country(opts[:country])
    |> limit(^Keyword.fetch!(opts, :limit))
    |> order_by(desc: :stargazers_count)
    |> Repo.all()
  end

  def list_matching_devs(country_code) do
    emoji = fn ->
      Enum.random(["🇺🇸", "🇬🇧", "🇨🇦", "🇩🇪", "🇮🇳"])
    end

    users = list_users(country: String.upcase(country_code), limit: 8)

    Enum.map(users, fn user ->
      %{
        name: user.name || user.handle,
        handle: user.handle,
        flag: (user.country && Algora.Misc.CountryEmojis.get(user.country)) || emoji.(),
        skills: user.tech_stack |> Enum.take(6),
        earned: :rand.uniform(50),
        bounties: :rand.uniform(40),
        projects: :rand.uniform(10),
        avatar_url: user.avatar_url
      }
    end)
  end

  def list_orgs(opts) do
    Repo.all(
      from u in User,
        where: u.type == :organization and u.seeded == false and is_nil(u.provider_login),
        limit: ^Keyword.fetch!(opts, :limit),
        order_by: [desc: u.stargazers_count]
    )
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
  defp filter_by_country(query, country), do: where(query, [u], u.country == ^country)
end
