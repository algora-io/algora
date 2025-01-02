defmodule Algora.Bounties.Attempt do
  @moduledoc false
  use Algora.Schema

  @type t() :: %__MODULE__{}

  schema "attempts" do
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:bounty_id, :user_id])
    |> validate_required([:bounty_id, :user_id])
  end
end
