defmodule Algora.Jobs.Job do
  @moduledoc false
  use Algora.Schema

  typed_schema "jobs" do
    belongs_to :user, Algora.Accounts.User

    has_many :activities, {"job_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
