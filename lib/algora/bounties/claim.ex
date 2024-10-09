defmodule Algora.Bounties.Claim do
  use Ecto.Schema
  import Ecto.Changeset

  schema "claims" do
    field :group_id, :string

    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end
end
