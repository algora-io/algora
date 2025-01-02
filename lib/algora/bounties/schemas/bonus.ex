defmodule Algora.Bounties.Bonus do
  @moduledoc false
  use Algora.Schema

  @type t() :: %__MODULE__{}

  schema "bonuses" do
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(bonus, attrs) do
    bonus
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end
end
