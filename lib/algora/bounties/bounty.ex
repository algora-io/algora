defmodule Algora.Bounties.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bounties" do
    field :title, :string
    field :description, :string
    field :amount, :decimal

    belongs_to :user, Algora.Accounts.User
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:title, :description, :amount])
    |> validate_required([:title, :description, :amount])
  end
end
