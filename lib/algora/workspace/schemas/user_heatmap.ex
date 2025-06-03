defmodule Algora.Workspace.UserHeatmap do
  @moduledoc """
  Schema for tracking user heatmaps.
  """
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Workspace.UserHeatmap

  typed_schema "user_heatmaps" do
    field :data, :map, null: false

    belongs_to :user, User, null: false

    timestamps()
  end

  @doc """
  Changeset for creating or updating a user heatmap.
  """
  def changeset(%UserHeatmap{} = heatmap, attrs) do
    heatmap
    |> cast(attrs, [:user_id, :data])
    |> validate_required([:user_id, :data])
    |> generate_id()
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
