defmodule Algora.Matches.JobMatch do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "job_matches" do
    field :status, Ecto.Enum, values: [:pending, :accepted, :rejected], default: :pending
    field :score, :decimal
    field :notes, :string

    belongs_to :user, Algora.Accounts.User
    belongs_to :job_posting, Algora.Jobs.JobPosting

    timestamps()
  end

  def changeset(job_match, attrs) do
    job_match
    |> cast(attrs, [:user_id, :job_posting_id, :status, :score, :notes])
    |> validate_required([:user_id, :job_posting_id])
    |> validate_inclusion(:status, [:pending, :accepted, :rejected])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:job_posting_id)
    |> unique_constraint([:user_id, :job_posting_id])
    |> generate_id()
  end
end
