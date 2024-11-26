defmodule Algora.Jobs.Application do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "applications" do
    belongs_to :job, Algora.Jobs.Job
    belongs_to :user, Algora.Users.User

    timestamps()
  end

  def changeset(application, attrs) do
    application
    |> cast(attrs, [:job_id, :user_id])
    |> validate_required([:job_id, :user_id])
  end
end
