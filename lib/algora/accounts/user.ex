defmodule Algora.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts.{User, Identity}

  schema "users" do
    field :provider, :string
    field :provider_id, :string
    field :provider_login, :string
    field :provider_meta, :map

    field :email, :string
    field :name, :string
    field :handle, :string
    field :avatar_url, :string

    field :website_url, :string
    field :twitter_url, :string
    field :github_url, :string
    field :youtube_url, :string
    field :twitch_url, :string
    field :discord_url, :string
    field :slack_url, :string
    field :linkedin_url, :string

    has_many :identities, Identity
    has_many :bounties, Algora.Bounties.Bounty
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :projects, Algora.Projects.Project
    has_many :repositories, Algora.Work.Repository
    has_many :installations, Algora.Installations.Installation

    timestamps()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(info, primary_email, emails, token) do
    %{"login" => handle, "avatar_url" => avatar_url, "html_url" => website_url} = info

    identity_changeset =
      Identity.github_registration_changeset(info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "handle" => handle,
        "email" => primary_email,
        "name" => get_change(identity_changeset, :provider_name),
        "avatar_url" => avatar_url,
        "website_url" => website_url
      }

      %User{}
      |> cast(params, [:email, :name, :handle, :avatar_url, :website_url])
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
