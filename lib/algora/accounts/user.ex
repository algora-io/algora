defmodule Algora.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts.{User, Identity}

  schema "users" do
    field :email, :string
    field :name, :string
    field :handle, :string
    field :avatar_url, :string
    field :external_homepage_url, :string

    has_many :identities, Identity

    timestamps()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(info, primary_email, emails, token) do
    %{"login" => handle, "avatar_url" => avatar_url, "html_url" => external_homepage_url} = info

    identity_changeset =
      Identity.github_registration_changeset(info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "handle" => handle,
        "email" => primary_email,
        "name" => get_change(identity_changeset, :provider_name),
        "avatar_url" => avatar_url,
        "external_homepage_url" => external_homepage_url
      }

      %User{}
      |> cast(params, [:email, :name, :handle, :avatar_url, :external_homepage_url])
      |> validate_required([:email, :name, :handle])
      |> validate_handle()
      |> validate_email()
      |> put_assoc(:identities, [identity_changeset])
    else
      %User{}
      |> change()
      |> Map.put(:valid?, false)
      |> put_assoc(:identities, [identity_changeset])
    end
  end

  def settings_changeset(%User{} = user, params) do
    user
    |> cast(params, [:handle, :name])
    |> validate_required([:handle, :name])
    |> validate_handle()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Algora.Repo)
    |> unique_constraint(:email)
  end

  defp validate_handle(changeset) do
    changeset
    |> validate_format(:handle, ~r/^[a-zA-Z0-9_-]{2,32}$/)
    |> unsafe_validate_unique(:handle, Algora.Repo)
    |> unique_constraint(:handle)
  end
end
