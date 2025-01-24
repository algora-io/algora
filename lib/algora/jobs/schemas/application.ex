defmodule Algora.Jobs.Application do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "applications" do
    belongs_to :job, Algora.Jobs.Job
    belongs_to :user, Algora.Accounts.User

    has_many :activities, {"application_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(application, attrs) do
    application
    |> cast(attrs, [:job_id, :user_id])
    |> validate_required([:job_id, :user_id])
  end
end
