defmodule Algora.Bounties.Attempt do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "attempts" do
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active, null: false
    field :warnings_count, :integer, default: 0, null: false

    belongs_to :ticket, Algora.Workspace.Ticket, null: false
    belongs_to :user, Algora.Accounts.User, null: false

    has_many :activities, {"attempt_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:ticket_id, :user_id])
    |> generate_id()
    |> validate_required([:ticket_id, :user_id])
    |> unique_constraint([:ticket_id, :user_id])
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:user_id)
  end
end
