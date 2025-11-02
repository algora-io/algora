defmodule Algora.Jobs.JobPosting do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Money.Ecto.Composite.Type

  typed_schema "job_postings" do
    field :title, :string
    field :description, :string
    field :tech_stack, {:array, :string}, default: []
    field :url, :string
    field :company_name, :string
    field :company_url, :string
    field :email, :string
    field :status, Ecto.Enum, values: [:initialized, :processing, :active, :expired], null: false, default: :initialized
    field :expires_at, :utc_datetime_usec
    # e.g. "SF Bay Area (Remote)"
    field :location, :string
    # e.g. ["US", "CA", "BR"]
    field :countries, {:array, :string}, default: []
    # e.g. ["LATAM", "NA"]
    field :regions, {:array, :string}, default: []
    field :compensation, :string
    field :min_compensation, Type
    field :max_compensation, Type
    field :seniority, :string
    field :system_tags, {:array, :string}, default: []
    field :primary_tech, :string
    field :primary_tag, :string
    field :full_description, :string
    field :team, :string
    field :provider, :string
    field :provider_id, :string

    field :location_meta, :map
    field :location_iso_lvl4, :string
    field :location_types, {:array, Ecto.Enum}, values: [:remote, :hybrid, :onsite]
    field :locations, {:array, :string}, default: []
    field :states, {:array, :string}, default: []

    # Equity compensation details
    # Percentage-based equity (e.g., 0.25 for 0.25%)
    field :min_equity_pct, :decimal
    field :max_equity_pct, :decimal
    # Money-based equity (actual dollar value)
    field :min_equity, Type
    field :max_equity, Type

    belongs_to :user, User, null: false
    has_many :interviews, Algora.Interviews.JobInterview, foreign_key: :job_posting_id
    has_many :matches, Algora.Matches.JobMatch, foreign_key: :job_posting_id

    timestamps()
  end

  def changeset(job_posting, attrs) do
    job_posting
    |> cast(attrs, [
      :title,
      :description,
      :tech_stack,
      :url,
      :company_name,
      :company_url,
      :email,
      :status,
      :expires_at,
      :user_id,
      :location,
      :compensation,
      :seniority,
      :countries,
      :regions,
      :system_tags,
      :location_meta,
      :location_iso_lvl4,
      :primary_tech,
      :primary_tag,
      :full_description,
      :team,
      :provider,
      :provider_id,
      :location_types,
      :locations,
      :min_compensation,
      :max_compensation,
      :states,
      :min_equity_pct,
      :max_equity_pct,
      :min_equity,
      :max_equity
    ])
    |> generate_id()
    |> validate_required([:url])
    |> foreign_key_constraint(:user)
  end
end
