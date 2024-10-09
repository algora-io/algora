defmodule Algora.Work.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :due_date, :utc_datetime

    belongs_to :repository, Algora.Work.Repository
    belongs_to :user, Algora.Accounts.User
    has_many :bounties, Algora.Bounties.Bounty

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :due_date])
    |> validate_required([:title, :description, :due_date])
  end
end
