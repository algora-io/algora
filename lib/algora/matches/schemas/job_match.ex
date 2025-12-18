defmodule Algora.Matches.JobMatch do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "job_matches" do
    field :status, Ecto.Enum,
      values: [:pending, :discarded, :automatched, :dripped, :approved, :highlighted],
      default: :pending

    field :score, :decimal
    field :notes, :string
    field :company_approved_at, :utc_datetime_usec
    field :company_bookmarked_at, :utc_datetime_usec
    field :company_discarded_at, :utc_datetime_usec
    field :candidate_approved_at, :utc_datetime_usec
    field :candidate_bookmarked_at, :utc_datetime_usec
    field :candidate_discarded_at, :utc_datetime_usec
    field :custom_sort_order, :integer
    field :anonymize, :boolean, default: true
    field :company_notes, :string
    field :dripped_at, :utc_datetime_usec
    field :locked, :boolean, default: false
    field :is_draft, :boolean, default: false
    field :eval, :map
    field :provider_candidate_id, :string
    field :provider_application_id, :string
    field :provider_candidate_meta, :map, default: %{}
    field :provider_application_meta, :map, default: %{}
    field :provider_feedback_meta, :map, default: %{}
    field :provider_interviews_meta, :map, default: %{}

    belongs_to :user, Algora.Accounts.User
    belongs_to :job_posting, Algora.Jobs.JobPosting

    timestamps()
  end

  def changeset(job_match, attrs) do
    job_match
    |> cast(attrs, [
      :user_id,
      :job_posting_id,
      :status,
      :score,
      :notes,
      :company_approved_at,
      :company_bookmarked_at,
      :company_discarded_at,
      :candidate_approved_at,
      :candidate_bookmarked_at,
      :candidate_discarded_at,
      :custom_sort_order,
      :anonymize,
      :company_notes,
      :dripped_at,
      :locked,
      :is_draft,
      :eval,
      :provider_candidate_id,
      :provider_application_id,
      :provider_candidate_meta,
      :provider_application_meta,
      :provider_feedback_meta,
      :provider_interviews_meta
    ])
    |> validate_required([:user_id, :job_posting_id])
    |> validate_inclusion(:status, [:pending, :discarded, :automatched, :dripped, :approved, :highlighted])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:job_posting_id)
    |> unique_constraint([:user_id, :job_posting_id])
    |> generate_id()
  end

  def get_application_history(match) do
    get_in(match.provider_application_meta, ["applicationHistory"]) || []
  end

  def get_application_feedback(match) do
    get_in(match.provider_feedback_meta, ["feedbacks"]) || []
  end

  def get_interview_schedules(match) do
    get_in(match.provider_interviews_meta, ["schedules"]) || []
  end
end
