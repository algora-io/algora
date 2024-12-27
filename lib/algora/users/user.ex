defmodule Algora.Users.User do
  use Algora.Schema

  alias Algora.MoneyUtils
  alias Algora.Users.User
  alias Algora.Users.Identity
  alias Algora.Workspace.Installation
  alias Money.Ecto.Composite.Type, as: MoneyType

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "users" do
    field :provider, :string
    field :provider_id, :string
    field :provider_login, :string
    field :provider_meta, :map, default: %{}

    field :type, Ecto.Enum, values: [:individual, :organization], default: :individual
    field :email, :string
    field :name, :string
    field :display_name, :string
    field :handle, :string
    field :last_context, :string
    field :bio, :string
    field :avatar_url, :string
    field :location, :string
    field :country, :string
    field :timezone, :string
    field :stargazers_count, :integer, default: 0
    field :domain, :string
    field :tech_stack, {:array, :string}, default: []
    field :featured, :boolean, default: false
    field :priority, :integer, default: 0
    field :fee_pct, :integer, default: 19
    field :seeded, :boolean, default: false
    field :activated, :boolean, default: false
    field :max_open_attempts, :integer, default: 3
    field :manual_assignment, :boolean, default: false

    field :hourly_rate_min, MoneyType, no_fraction_if_integer: true
    field :hourly_rate_max, MoneyType, no_fraction_if_integer: true
    field :hours_per_week, :integer

    field :total_earned, MoneyType, no_fraction_if_integer: true, virtual: true
    field :completed_bounties_count, :integer, virtual: true
    field :contributed_projects_count, :integer, virtual: true

    ## TODO: remove temporary fields
    field :message, :string, virtual: true
    field :flag, :string, virtual: true

    field :need_avatar, :boolean, default: false

    field :bounty_mode, Ecto.Enum,
      values: [:community, :experts_only, :public],
      default: :community

    field :website_url, :string
    field :twitter_url, :string
    field :github_url, :string
    field :youtube_url, :string
    field :twitch_url, :string
    field :discord_url, :string
    field :slack_url, :string
    field :linkedin_url, :string

    field :og_title, :string
    field :og_image_url, :string

    has_many :identities, Identity
    has_many :memberships, Algora.Organizations.Member, foreign_key: :user_id
    has_many :members, Algora.Organizations.Member, foreign_key: :org_id
    has_many :owned_bounties, Algora.Bounties.Bounty, foreign_key: :owner_id
    has_many :created_bounties, Algora.Bounties.Bounty, foreign_key: :creator_id
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :projects, Algora.Projects.Project
    has_many :repositories, Algora.Workspace.Repository
    has_many :transactions, Algora.Payments.Transaction, foreign_key: :user_id
    has_many :owned_installations, Installation, foreign_key: :owner_id
    has_many :connected_installations, Installation, foreign_key: :connected_user_id
    has_many :contractor_contracts, Algora.Contracts.Contract, foreign_key: :contractor_id
    has_many :client_contracts, Algora.Contracts.Contract, foreign_key: :client_id

    has_one :customer, Algora.Payments.Customer, foreign_key: :user_id

    timestamps()
  end

  def after_load({:ok, struct}), do: {:ok, after_load(struct)}
  def after_load({:error, _} = result), do: result
  def after_load(nil), do: nil

  def after_load(struct) do
    [:total_earned]
    |> Enum.reduce(struct, &MoneyUtils.ensure_money_field(&2, &1))
  end

  def org_registration_changeset(params) do
    %User{}
    |> cast(params, [:email])
    |> generate_id()
    |> validate_required([:email])
    |> validate_email()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(nil, info, primary_email, emails, token) do
    identity_changeset =
      Identity.github_registration_changeset(nil, info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "handle" => info["login"],
        "email" => primary_email,
        "display_name" => get_change(identity_changeset, :provider_name),
        "bio" => info["bio"],
        "location" => info["location"],
        "avatar_url" => info["avatar_url"],
        "website_url" => info["blog"],
        "github_url" => info["html_url"],
        "provider" => "github",
        "provider_id" => to_string(info["id"]),
        "provider_login" => info["login"],
        "provider_meta" => info
      }

      %User{}
      |> cast(params, [
        :handle,
        :email,
        :display_name,
        :bio,
        :location,
        :avatar_url,
        :website_url,
        :github_url,
        :provider,
        :provider_id,
        :provider_login,
        :provider_meta
      ])
      |> generate_id()
      |> validate_required([:email, :display_name, :handle])
      |> validate_handle()
      |> validate_email()
      |> unique_constraint(:email)
      |> unique_constraint(:handle)
      |> put_assoc(:identities, [identity_changeset])
    else
      %User{}
      |> change()
      |> Map.put(:valid?, false)
      |> put_assoc(:identities, [identity_changeset])
    end
  end

  def github_registration_changeset(user = %User{}, info, primary_email, emails, token) do
    identity_changeset =
      Identity.github_registration_changeset(user, info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "handle" => info["login"],
        "email" => primary_email,
        "display_name" => get_change(identity_changeset, :provider_name),
        "bio" => info["bio"],
        "location" => info["location"],
        "avatar_url" => info["avatar_url"],
        "website_url" => info["blog"],
        "github_url" => info["html_url"],
        "provider" => "github",
        "provider_id" => to_string(info["id"]),
        "provider_login" => info["login"],
        "provider_meta" => info
      }

      user
      |> cast(params, [
        :handle,
        :email,
        :display_name,
        :bio,
        :location,
        :avatar_url,
        :website_url,
        :github_url,
        :provider,
        :provider_id,
        :provider_login,
        :provider_meta
      ])
      |> generate_id()
      |> validate_required([:email, :display_name, :handle])
      |> validate_handle()
      |> validate_email()
    else
      user
      |> change()
      |> Map.put(:valid?, false)
    end
  end

  def org_registration_changeset(org, params) do
    org
    |> cast(params, [
      :email,
      :display_name,
      :bio,
      :avatar_url,
      :handle,
      :domain,
      :og_title,
      :og_image_url,
      :tech_stack,
      :hourly_rate_min,
      :hourly_rate_max,
      :hours_per_week,
      :website_url,
      :twitter_url,
      :github_url,
      :youtube_url,
      :twitch_url,
      :discord_url,
      :slack_url,
      :linkedin_url,
    ])
    |> generate_id()
    |> validate_required([:type, :handle, :email, :display_name])
  end

  def settings_changeset(%User{} = user, params) do
    user
    |> cast(params, [:handle, :display_name, :last_context, :need_avatar])
    |> validate_required([:handle, :display_name])
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

  def validate_handle(changeset) do
    changeset
    |> validate_format(:handle, ~r/^[a-zA-Z0-9_-]{2,32}$/)
    |> unsafe_validate_unique(:handle, Algora.Repo)
    |> unique_constraint(:handle)
  end

  def github_changeset(meta) do
    params = %{
      provider_id: to_string(meta["id"]),
      provider_login: meta["login"],
      type: type_from_provider(:github, meta["type"]),
      display_name: meta["name"],
      bio: meta["bio"],
      location: meta["location"],
      avatar_url: meta["avatar_url"],
      website_url: meta["blog"],
      github_url: meta["html_url"]
    }

    %User{provider: "github", provider_meta: meta}
    |> cast(
      params,
      [
        :provider_id,
        :provider_login,
        :type,
        :display_name,
        :bio,
        :location,
        :avatar_url,
        :website_url,
        :github_url
      ]
    )
    |> generate_id()
    |> validate_required([:provider_id, :provider_login, :type])
    |> unique_constraint([:provider, :provider_id])
  end

  def validate_timezone(changeset) do
    changeset
    |> validate_inclusion(:timezone, Tzdata.zone_list())
  end

  defp type_from_provider(:github, "Organization"), do: :organization
  defp type_from_provider(:github, _), do: :individual
end
