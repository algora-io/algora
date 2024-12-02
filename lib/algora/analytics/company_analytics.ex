defmodule Algora.Analytics.CompanyAnalytics do
  use Ecto.Schema

  schema "company_analytics" do
    belongs_to :organization, Algora.Users.User

    # Registration & Onboarding
    field :joined_at, :utc_datetime_usec
    field :card_saved_at, :utc_datetime_usec
    field :last_active_at, :utc_datetime_usec
    field :visit_count, :integer, default: 0

    # Job Status
    field :job_status, Ecto.Enum, values: [:null, :pending, :created, :published]
    field :job_created_at, :utc_datetime_usec
    field :job_published_at, :utc_datetime_usec

    # Contract Metrics
    field :total_contracts, :integer, default: 0
    field :active_contracts, :integer, default: 0
    field :prepaid_contracts, :integer, default: 0
    field :released_contracts, :integer, default: 0
    field :renewed_contracts, :integer, default: 0
    field :disputed_contracts, :integer, default: 0

    # Time to Fill
    field :first_contract_created_at, :utc_datetime_usec
    field :first_contract_filled_at, :utc_datetime_usec

    # Aggregate Contract Metrics
    field :total_matches, :integer, default: 0
    field :total_impressions, :integer, default: 0
    field :unique_impressions, :integer, default: 0
    field :total_clicks, :integer, default: 0

    timestamps()
  end
end
