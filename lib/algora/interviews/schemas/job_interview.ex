defmodule Algora.Interviews.JobInterview do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  alias Algora.Accounts.User

  @interview_statuses [:initial, :ongoing, :passed, :failed, :withdrawn]

  typed_schema "job_interviews" do
    field :status, Ecto.Enum, values: @interview_statuses

    field :notes, :string
    field :scheduled_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :company_feedback, :string
    field :candidate_feedback, :string
    field :company_feedback_token, :string
    field :candidate_feedback_token, :string

    belongs_to :user, User
    belongs_to :job_posting, Algora.Jobs.JobPosting
    belongs_to :org, User

    timestamps()
  end

  def changeset(job_interview, attrs) do
    job_interview
    |> cast(attrs, [
      :user_id,
      :job_posting_id,
      :org_id,
      :status,
      :notes,
      :scheduled_at,
      :completed_at,
      :company_feedback,
      :candidate_feedback,
      :company_feedback_token,
      :candidate_feedback_token
    ])
    |> validate_required([:user_id, :job_posting_id, :org_id, :status])
    |> validate_inclusion(:status, @interview_statuses)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:job_posting_id)
    |> foreign_key_constraint(:org_id)
    |> unique_constraint([:user_id, :org_id])
    |> generate_id()
    |> maybe_generate_feedback_tokens()
  end

  defp maybe_generate_feedback_tokens(changeset) do
    if get_field(changeset, :id) && !get_field(changeset, :company_feedback_token) do
      changeset
      |> put_change(:company_feedback_token, Nanoid.generate(6))
      |> put_change(:candidate_feedback_token, Nanoid.generate(6))
    else
      changeset
    end
  end
end
