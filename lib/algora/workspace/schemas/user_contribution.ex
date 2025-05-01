defmodule Algora.Workspace.UserContribution do
  @moduledoc """
  Schema for tracking user contributions to repositories.
  """
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Workspace.Repository
  alias Algora.Workspace.UserContribution

  typed_schema "user_contributions" do
    field :contribution_count, :integer, null: false, default: 0
    field :last_fetched_at, :utc_datetime_usec, null: false

    belongs_to :user, User, null: false
    belongs_to :repository, Repository, null: false

    timestamps()
  end

  @doc """
  Changeset for creating or updating a user contribution.
  """
  def changeset(%UserContribution{} = contribution, attrs) do
    contribution
    |> cast(attrs, [:user_id, :repository_id, :contribution_count, :last_fetched_at])
    |> validate_required([:user_id, :repository_id, :contribution_count, :last_fetched_at])
    |> generate_id()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:repository_id)
    |> unique_constraint([:user_id, :repository_id])
  end
end
