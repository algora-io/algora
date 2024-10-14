defmodule Algora.Bounties.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bounties" do
    field :amount, :decimal
    field :currency, :string

    belongs_to :task, Algora.Work.Task
    belongs_to :user, Algora.Accounts.User
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:title, :description, :amount])
    |> validate_required([:title, :description, :amount])
  end
end
