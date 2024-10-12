defmodule Algora.Accounts do
  import Ecto.Query
  import Ecto.Changeset

  alias Algora.Repo
  alias Algora.Accounts.{User, Identity}

  def list_users(opts) do
    Repo.all(
      from u in User,
        where: u.type == "individual",
        limit: ^Keyword.fetch!(opts, :limit)
    )
  end

  def get_users_map(user_ids) when is_list(user_ids) do
    Repo.all(from u in User, where: u.id in ^user_ids, select: {u.id, u})
  end

  def admin?(%User{} = user) do
    user.email in Algora.config(:admin_emails)
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
    if user = get_user_by_provider_email(:github, primary_email) do
      update_github_token(user, token)
    else
      info
      |> User.github_registration_changeset(primary_email, emails, token)
      |> Repo.insert()
    end
  end

  def get_user_by_provider_email(provider, email) when provider in [:github] do
    query =
      from(u in User,
        join: i in assoc(u, :identities),
        where:
          i.provider == ^to_string(provider) and
            fragment("lower(?)", u.email) == ^String.downcase(email)
      )

    Repo.one(query)
  end

  def get_user_by_provider_id(provider, id) when provider in [:github] do
    query =
      from(u in User,
        join: i in assoc(u, :identities),
        where: i.provider == ^to_string(provider) and i.provider_id == ^id
      )

    Repo.one(query)
  end

  @spec get_access_token(%User{}) :: {:ok, String.t()} | {:error, atom()}
  def get_access_token(%User{} = user) do
    with identity <-
           Repo.one(from(i in Identity, where: i.user_id == ^user.id and i.provider == "github")) do
      {:ok, identity.provider_token}
    else
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
end
