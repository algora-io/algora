defmodule Algora.Jobs.JobApplication do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Jobs.JobPosting

  typed_schema "job_applications" do
    field :status, Ecto.Enum, values: [:pending], null: false, default: :pending
    field :imported_at, :utc_datetime_usec
    belongs_to :job, JobPosting, null: false
    belongs_to :user, User, null: false

    timestamps()
  end

  def changeset(job_application, attrs) do
    job_application
    |> cast(attrs, [:status, :job_id, :user_id, :imported_at])
    |> generate_id()
    |> validate_required([:status, :job_id, :user_id])
    |> unique_constraint([:job_id, :user_id])
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:user_id)
  end
end
