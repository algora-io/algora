defmodule Algora.Matches.JobMatch do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "job_matches" do
    field :status, Ecto.Enum, values: [:pending, :discarded, :approved, :highlighted], default: :pending
    field :score, :decimal
    field :notes, :string
    field :company_approved_at, :utc_datetime_usec
    field :company_bookmarked_at, :utc_datetime_usec
    field :company_discarded_at, :utc_datetime_usec
    field :candidate_approved_at, :utc_datetime_usec
    field :candidate_bookmarked_at, :utc_datetime_usec
    field :candidate_discarded_at, :utc_datetime_usec
    field :custom_sort_order, :integer

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
      :custom_sort_order
    ])
    |> validate_required([:user_id, :job_posting_id])
    |> validate_inclusion(:status, [:pending, :discarded, :approved, :highlighted])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:job_posting_id)
    |> unique_constraint([:user_id, :job_posting_id])
    |> generate_id()
  end
end
