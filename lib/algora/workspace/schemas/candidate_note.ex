defmodule Algora.Workspace.CandidateNote do
  @moduledoc """
  Schema for storing candidate notes/highlights.
  """
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Jobs.JobPosting
  alias Algora.Workspace.CandidateNote

  typed_schema "candidate_notes" do
    field :notes, {:array, :string}, null: false

    belongs_to :user, User, null: false
    belongs_to :job, JobPosting

    timestamps()
  end

  @doc """
  Changeset for creating or updating candidate notes.
  """
  def changeset(%CandidateNote{} = note, attrs) do
    note
    |> cast(attrs, [:user_id, :job_id, :notes])
    |> validate_required([:user_id, :notes])
    |> generate_id()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:job_id)
    |> unique_constraint([:user_id, :job_id])
  end
end
