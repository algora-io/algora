defmodule Algora.Bounties.Bonus do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "bonuses" do
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Accounts.User

    has_many :activities, {"bonus_activities", Algora.Activities.Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(bonus, attrs) do
    bonus
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end
end
