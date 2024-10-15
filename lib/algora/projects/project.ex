defmodule Algora.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "projects" do
    field :name, :string

    belongs_to :user, Algora.Accounts.User
    has_many :milestones, Algora.Projects.Milestone
    has_many :assignees, Algora.Projects.Assignee
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
