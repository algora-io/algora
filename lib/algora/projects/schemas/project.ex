defmodule Algora.Projects.Project do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "projects" do
    field :name, :string

    belongs_to :user, Algora.Accounts.User
    # has_many :milestones, Algora.Projects.Milestone
    # has_many :assignees, Algora.Projects.Assignee
    # has_many :transactions, Algora.Payments.Transaction
    has_many :activities, {"project_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
