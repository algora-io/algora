defmodule Algora.Accounts.User do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.Follow
  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Accounts.UserMedia
  alias Algora.Activities.Activity
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Tip
  alias Algora.Contracts.Contract
  alias Algora.MoneyUtils
  alias Algora.Organizations.Member
  alias Algora.Types.Money
  alias Algora.Util
  alias Algora.Workspace.Installation
  alias AlgoraWeb.Endpoint

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "users" do
    field :provider, :string
    field :provider_id, :string
    field :provider_login, :string
    field :provider_meta, :map, default: %{}

    field :type, Ecto.Enum, values: [:individual, :organization, :bot], default: :individual
    field :email, :string
    field :internal_email, :string
    field :internal_notes, :string
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
    field :followers_count, :integer, default: 0
    field :following_count, :integer, default: 0
    field :domain, :string
    field :tech_stack, {:array, :string}, default: []
    field :discovery_tech_stack, {:array, :string}, default: []
    field :categories, {:array, :string}, default: []
    field :featured, :boolean, default: false
    field :priority, :integer, default: 0
    field :fee_pct, :integer, default: 9
    field :fee_pct_prev, :integer, default: 9
    field :subscription_price, Money
    field :seeded, :boolean, default: false
    field :activated, :boolean, default: false
    field :max_open_attempts, :integer, default: 3
    field :manual_assignment, :boolean, default: false
    field :is_admin, :boolean, default: false
    field :contract_signed, :boolean, default: false
    field :last_active_at, :utc_datetime_usec
    field :last_job_match_email_at, :utc_datetime_usec
    field :last_dm_date, :utc_datetime_usec
    field :candidate_notes, :string
    field :dm_thread_url, :string
    field :contribution_scores, :map, default: %{}

    field :seeking_bounties, :boolean, default: false
    field :seeking_contracts, :boolean, default: false
    field :seeking_jobs, :boolean, default: false
    field :open_to_new_role, :boolean, default: true
    field :hiring, :boolean, default: false
    field :hiring_subscription, Ecto.Enum, values: [:inactive, :trial, :active], default: :inactive
    field :hiring_keywords, :string
    field :candidates_require_login, :boolean, default: true
    field :candidates_require_confirmation, :boolean, default: false

    field :hourly_rate_min, Money
    field :hourly_rate_max, Money
    field :hours_per_week, :integer
    field :min_compensation, Money
    field :willing_to_relocate, :boolean, default: false
    field :us_work_authorization, :boolean, default: false
    field :preferences, :string

    field :refer_to_company, :boolean, default: false
    field :company_domain, :string
    field :friends_recommendations, :boolean, default: false
    field :friends_github_handles, :string
    field :opt_out_algora, :boolean, default: false

    field :total_earned, Money, virtual: true
    field :transactions_count, :integer, virtual: true
    field :contributed_projects_count, :integer, virtual: true

    field :need_avatar, :boolean, default: false

    field :bounty_mode, Ecto.Enum,
      values: [:community, :exclusive, :public],
      default: :community

    field :website_url, :string
    field :twitter_url, :string
    field :github_url, :string
    field :youtube_url, :string
    field :twitch_url, :string
    field :discord_url, :string
    field :slack_url, :string
    field :linkedin_url, :string
    field :linkedin_meta, :map, default: %{}
    field :google_scholar_url, :string
    field :employment_info, :map, default: %{}

    field :og_title, :string
    field :og_image_url, :string

    field :login_token, :string, virtual: true
    field :signup_token, :string, virtual: true

    field :billing_name, :string
    field :billing_address, :string
    field :jurisdiction, :string
    field :entity_type, :string
    field :executive_name, :string
    field :executive_role, :string
    field :executive_email, :string
    field :recruiting_contract_id, :string

    field :system_bio, :string
    field :system_bio_meta, :map, default: %{}
    field :system_tags, {:array, :string}, default: []
    field :readme, :string

    field :location_meta, :map
    field :location_iso_lvl4, :string
    field :grad_year, :integer

    field :email_recipients, {:array, :map}, default: []
    field :language_contributions_synced, :boolean, default: false
    field :repo_contributions_synced, :boolean, default: false
    field :linkedin_url_attempted, :boolean, default: false
    field :linkedin_meta_attempted, :boolean, default: false
    field :readme_attempted, :boolean, default: false

    # Work arrangement preferences
    field :open_to_remote, :boolean, default: false
    field :open_to_hybrid, :boolean, default: false
    field :open_to_onsite, :boolean, default: false

    # Relocation preferences
    field :open_to_relocate_sf, :boolean, default: false
    field :open_to_relocate_ny, :boolean, default: false
    field :open_to_relocate_country, :boolean, default: false
    field :open_to_relocate_world, :boolean, default: false

    # Commitment preferences
    field :open_to_fulltime, :boolean, default: false
    field :open_to_contract, :boolean, default: false

    # Track preferences
    field :open_to_ic, :boolean, default: false
    field :open_to_manager, :boolean, default: false

    # Work authorization
    field :work_auth_us, :boolean, default: false
    field :work_auth_eu, :boolean, default: false

    # Security clearance
    field :security_clearance, Ecto.Enum, values: [:active, :eligible, :not_eligible]

    # Resume
    field :resume_url, :string

    # Phone number
    field :phone_number, :string

    # Earliest start date
    field :earliest_start_date, :date

    # Poaching targets - stores repos and companies to poach from
    field :poaching_targets, :string

    # Customer stage tracking
    field :stage, Ecto.Enum,
      values: [:inbound, :opening, :onboarding, :campaigning, :interviewing, :none],
      default: :none

    # Import tracking - identifies the source that imported this user
    field :import_source, :string

    # Company funding information (for organizations)
    field :latest_funding_round, :string
    field :amount_raised, Money
    field :company_valuation, Money

    # Ashby integration fields
    field :ashby_api_key, :string
    field :ashby_source_id, :string
    field :ashby_user_id, :string

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
    has_one :heatmap, Algora.Workspace.UserHeatmap, foreign_key: :user_id

    has_many :media, UserMedia
    has_many :job_matches, Algora.Matches.JobMatch, foreign_key: :user_id

    has_many :following_relationships, Follow, foreign_key: :follower_id
    has_many :following, through: [:following_relationships, :followed]
    has_many :follower_relationships, Follow, foreign_key: :followed_id
    has_many :followers, through: [:follower_relationships, :follower]

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
    |> cast(params, [:email, :display_name, :type])
    |> generate_id()
    |> validate_required([:email])
    |> validate_unique_email()
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
        "display_name" => info["name"],
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
      |> validate_required([:email, :handle])
      |> validate_handle()
      |> validate_unique_email()
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
      params =
        %{
          "handle" => user.handle || Algora.Organizations.ensure_unique_handle(info["login"]),
          "email" => user.email || primary_email,
          "display_name" => user.display_name || info["name"],
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

      params =
        if is_nil(user.provider_id) do
          Map.put(params, "display_name", info["name"])
        else
          params
        end

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
      |> validate_required([:email, :handle])
      |> validate_handle()
      |> validate_unique_email()
      |> unique_constraint(:email)
      |> unique_constraint(:handle)
    else
      user
      |> change()
      |> Map.put(:valid?, false)
    end
  end

  def user_registration_changeset(params) do
    %User{}
    |> cast(params, [:handle, :email])
    |> generate_id()
    |> validate_required([:email, :handle])
    |> validate_handle()
    |> validate_unique_email()
    |> unique_constraint(:email)
    |> unique_constraint(:handle)
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
    |> validate_required([:type, :handle, :email])
    |> validate_unique_email()
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
      :timezone,
      :tech_stack,
      :seeking_contracts,
      :seeking_bounties,
      :seeking_jobs,
      :hourly_rate_min,
      :hours_per_week,
      :preferences,
      :ashby_api_key,
      :ashby_source_id,
      :ashby_user_id
    ])
    |> validate_required([:handle])
    |> validate_handle()
    |> validate_timezone()
  end

  def login_changeset(%User{} = user, params) do
    cast(user, params, [:email, :login_token])
  end

  def signup_changeset(%User{} = user, params) do
    cast(user, params, [:email, :signup_token])
  end

  def validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def validate_unique_email(changeset) do
    changeset
    |> validate_email()
    |> unsafe_validate_unique(:email, Algora.Repo)
    |> unique_constraint(:email)
  end

  def validate_handle(changeset) do
    reserved_words =
      ~w(personal org admin support help security team staff official auth tip home dashboard bounties community user payment claims orgs projects jobs leaderboard onboarding pricing developers companies contracts blog docs open hiring sdk api repo go preview tv podcast)

    changeset
    |> validate_format(:handle, ~r/^[a-zA-Z0-9_-]{2,32}$/)
    |> validate_exclusion(:handle, reserved_words, message: "is reserved")
    |> unsafe_validate_unique(:handle, Algora.Repo)
    |> unique_constraint(:handle)
  end

  def get_domain(%{"type" => type}) when type != "Organization", do: nil

  def get_domain(%{"email" => email}) when is_binary(email) do
    domain = email |> String.split("@") |> List.last() |> Util.to_domain()

    if not Algora.Crawler.blacklisted?(domain), do: domain
  end

  def get_domain(%{"blog" => url}) when is_binary(url) do
    domain =
      with url when not is_nil(url) <- Util.normalize_url(url),
           %URI{host: host} when is_binary(host) and host != "" <- URI.parse(url) do
        Util.to_domain(host)
      else
        _ -> nil
      end

    if not Algora.Crawler.blacklisted?(domain), do: domain
  end

  def get_domain(_meta), do: nil

  def github_changeset(user \\ %User{}, meta) do
    params = %{
      provider_id: to_string(meta["id"]),
      provider_login: meta["login"],
      type: type_from_provider(:github, meta["type"]),
      display_name: meta["name"] || meta["login"],
      bio: meta["bio"],
      location: meta["location"],
      avatar_url: meta["avatar_url"],
      website_url: Util.normalize_url(meta["blog"]),
      github_url: meta["html_url"],
      domain: get_domain(meta),
      provider: "github",
      provider_meta: meta
    }

    user
    |> cast(
      params,
      [
        :provider,
        :provider_meta,
        :provider_id,
        :provider_login,
        :type,
        :display_name,
        :bio,
        :location,
        :avatar_url,
        :website_url,
        :github_url,
        :domain
      ]
    )
    |> generate_id()
    |> validate_required([:provider_id, :provider_login, :type])
    |> unique_constraint([:provider, :provider_id])
  end

  def is_admin_changeset(user, is_admin) do
    cast(user, %{is_admin: is_admin}, [:is_admin])
  end

  def job_preferences_changeset(%User{} = user, params) do
    user
    |> cast(params, [
      :min_compensation,
      :willing_to_relocate,
      :us_work_authorization,
      :linkedin_url,
      :google_scholar_url,
      :twitter_url,
      :youtube_url,
      :website_url,
      :location,
      :preferences,
      :display_name,
      :internal_email,
      :internal_notes,
      :candidate_notes,
      :refer_to_company,
      :company_domain,
      :friends_recommendations,
      :friends_github_handles,
      :opt_out_algora,
      :email_recipients,
      :employment_info,
      :open_to_remote,
      :open_to_hybrid,
      :open_to_onsite,
      :open_to_relocate_sf,
      :open_to_relocate_ny,
      :open_to_relocate_country,
      :open_to_relocate_world,
      :open_to_fulltime,
      :open_to_contract,
      :open_to_ic,
      :open_to_manager,
      :open_to_new_role,
      :work_auth_us,
      :work_auth_eu,
      :security_clearance,
      :phone_number,
      :resume_url,
      :earliest_start_date
    ])
    |> validate_url(:linkedin_url)
    |> validate_url(:google_scholar_url)
    |> validate_url(:twitter_url)
    |> validate_url(:youtube_url)
    |> validate_url(:website_url)
    |> validate_url(:resume_url)
  end

  def hiring_changeset(%User{} = user, params) do
    cast(user, params, [
      :preferences,
      :executive_name,
      :executive_role,
      :executive_email,
      :billing_name,
      :billing_address,
      :jurisdiction,
      :entity_type,
      :hiring_keywords,
      :poaching_targets,
      :ashby_api_key,
      :ashby_source_id,
      :ashby_user_id
    ])
  end

  def admin_pipeline_changeset(%User{} = user, params) do
    cast(user, params, [
      :open_to_new_role,
      :last_job_match_email_at,
      :last_dm_date,
      :candidate_notes,
      :dm_thread_url,
      :linkedin_url,
      :employment_info,
      :internal_email,
      :stage
    ])
  end

  defp validate_url(changeset, field) do
    validate_format(changeset, field, ~r/^https?:\/\/.*/, message: "must be a valid URL")
  end

  def validate_timezone(changeset) do
    validate_inclusion(changeset, :timezone, Tzdata.zone_list())
  end

  def type_from_provider(:github, "Bot"), do: :bot
  def type_from_provider(:github, "Organization"), do: :organization
  def type_from_provider(:github, _), do: :individual

  def handle(%{handle: handle}) when is_binary(handle), do: handle
  def handle(%{provider_login: handle}), do: handle

  def url(%{handle: handle}) when is_binary(handle), do: "#{Endpoint.url()}/#{handle}"
  def url(%{provider_login: handle}), do: "https://github.com/#{handle}"

  @doc """
  Returns the primary email for a user (internal_email > email > provider_meta["email"])
  """
  def primary_email(%User{} = user) do
    user.internal_email || user.email || get_in(user.provider_meta, ["email"])
  end
end
