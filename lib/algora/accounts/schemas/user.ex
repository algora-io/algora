defmodule Algora.Accounts.User do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Activities.Activity
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Tip
  alias Algora.Contracts.Contract
  alias Algora.MoneyUtils
  alias Algora.Organizations.Member
  alias Algora.Types.Money
  alias Algora.Workspace.Installation
  alias AlgoraWeb.Endpoint

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "users" do
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
    field :categories, {:array, :string}, default: []
    field :featured, :boolean, default: false
    field :priority, :integer, default: 0
    field :fee_pct, :integer, default: 19
    field :seeded, :boolean, default: false
    field :activated, :boolean, default: false
    field :max_open_attempts, :integer, default: 3
    field :manual_assignment, :boolean, default: false
    field :is_admin, :boolean, default: false

    field :seeking_bounties, :boolean, default: false
    field :seeking_contracts, :boolean, default: false
    field :seeking_jobs, :boolean, default: false
    field :hiring, :boolean, default: false

    field :hourly_rate_min, Money
    field :hourly_rate_max, Money
    field :hours_per_week, :integer

    field :total_earned, Money, virtual: true
    field :completed_bounties_count, :integer, virtual: true
    field :contributed_projects_count, :integer, virtual: true

    field :need_avatar, :boolean, default: false

    field :bounty_mode, Ecto.Enum,
      values: [:community, :exclusive, :public],
      default: :public

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

    field :login_token, :string, virtual: true

    has_many :identities, Identity
    has_many :memberships, Member, foreign_key: :user_id
    has_many :members, Member, foreign_key: :org_id
    has_many :owned_bounties, Bounty, foreign_key: :owner_id
    has_many :created_bounties, Bounty, foreign_key: :creator_id
    has_many :owned_tips, Tip, foreign_key: :owner_id
    has_many :created_tips, Tip, foreign_key: :creator_id
    has_many :received_tips, Tip, foreign_key: :recipient_id
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :repositories, Algora.Workspace.Repository
    has_many :transactions, Algora.Payments.Transaction, foreign_key: :user_id
    has_many :owned_installations, Installation, foreign_key: :owner_id
    has_many :connected_installations, Installation, foreign_key: :connected_user_id
    has_many :contractor_contracts, Contract, foreign_key: :contractor_id
    has_many :client_contracts, Contract, foreign_key: :client_id
    has_many :activities, {"user_activities", Activity}, foreign_key: :assoc_id

    has_one :customer, Algora.Payments.Customer, foreign_key: :user_id

    timestamps()
  end

  def after_load({:ok, struct}), do: {:ok, after_load(struct)}
  def after_load({:error, _} = result), do: result
  def after_load(nil), do: nil

  def after_load(struct) do
    Enum.reduce([:total_earned], struct, &MoneyUtils.ensure_money_field(&2, &1))
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

  def github_registration_changeset(%User{} = user, info, primary_email, emails, token) do
    identity_changeset =
      Identity.github_registration_changeset(user, info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "display_name" => user.display_name || get_change(identity_changeset, :provider_name),
        "bio" => user.bio || info["bio"],
        "location" => user.location || info["location"],
        "avatar_url" => user.avatar_url || info["avatar_url"],
        "website_url" => user.website_url || info["blog"],
        "github_url" => user.github_url || info["html_url"],
        "provider" => "github",
        "provider_id" => to_string(info["id"]),
        "provider_login" => info["login"],
        "provider_meta" => info
      }

      user
      |> cast(params, [
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
      |> validate_required([:display_name])
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
      :website_url,
      :location,
      :bio,
      :avatar_url,
      :handle,
      :domain,
      :tech_stack,
      :categories,
      :hourly_rate_min,
      :hourly_rate_max,
      :hours_per_week,
      :last_context
    ])
    |> generate_id()
    |> validate_required([:type, :handle, :email, :display_name])
    |> validate_email()
    |> unique_constraint(:handle)
    |> unique_constraint(:email)
  end

  def settings_changeset(%User{} = user, params) do
    user
    |> cast(params, [
      :handle,
      :display_name,
      :last_context,
      :need_avatar,
      :website_url,
      :bio,
      :country,
      :location,
      :timezone
    ])
    |> validate_required([:handle, :display_name])
    |> validate_handle()
    |> validate_timezone()
  end

  def login_changeset(%User{} = user, params) do
    cast(user, params, [:email, :login_token])
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
    reserved_words =
      ~w(personal org admin support help security team staff official auth tip home dashboard bounties community user payment claims orgs projects jobs leaderboard onboarding pricing developers companies contracts community blog docs open hiring sdk api)

    changeset
    |> validate_format(:handle, ~r/^[a-zA-Z0-9_-]{2,32}$/)
    |> validate_exclusion(:handle, reserved_words, message: "is reserved")
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

  def is_admin_changeset(user, is_admin) do
    cast(user, %{is_admin: is_admin}, [:is_admin])
  end

  def validate_timezone(changeset) do
    validate_inclusion(changeset, :timezone, Tzdata.zone_list())
  end

  defp type_from_provider(:github, "Organization"), do: :organization
  defp type_from_provider(:github, _), do: :individual

  def handle(%{handle: handle}) when is_binary(handle), do: handle
  def handle(%{provider_login: handle}), do: handle

  def url(%{handle: handle, type: :individual}) when is_binary(handle), do: "#{Endpoint.url()}/@/#{handle}"
  def url(%{handle: handle, type: :organization}), do: "#{Endpoint.url()}/org/#{handle}"
  def url(%{handle: handle}) when is_binary(handle), do: "#{Endpoint.url()}/org/#{handle}"
  def url(%{provider_login: handle}), do: "https://github.com/#{handle}"
end
