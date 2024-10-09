defmodule Algora.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string

    belongs_to :user, Algora.Accounts.User
    has_many :milestones, Algora.Projects.Milestone
    has_many :assignees, Algora.Projects.Assignee

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
