defmodule Algora.Bounties.Attempt do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "attempts" do
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Accounts.User

    has_many :activities, {"attempt_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end
end
