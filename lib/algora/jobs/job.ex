defmodule Algora.Jobs.Job do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "jobs" do
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
