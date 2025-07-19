defmodule Algora.Interviews.JobInterview do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "job_interviews" do
    field :status, Ecto.Enum, values: [:scheduled, :completed, :cancelled, :no_show]
    field :notes, :string
    field :scheduled_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :user, Algora.Accounts.User
    belongs_to :job_posting, Algora.Jobs.JobPosting

    timestamps()
  end

  def changeset(job_interview, attrs) do
    job_interview
    |> cast(attrs, [:user_id, :job_posting_id, :status, :notes, :scheduled_at, :completed_at])
    |> validate_required([:user_id, :job_posting_id, :status])
    |> validate_inclusion(:status, [:scheduled, :completed, :cancelled, :no_show])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:job_posting_id)
    |> generate_id()
  end
end
