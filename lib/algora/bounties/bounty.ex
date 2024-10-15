defmodule Algora.Bounties.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "bounties" do
    field :amount, :decimal
    field :currency, :string

    belongs_to :task, Algora.Work.Task
    belongs_to :owner, Algora.Accounts.User
    belongs_to :creator, Algora.Accounts.User
    has_many :attempts, Algora.Bounties.Attempt
    has_many :claims, Algora.Bounties.Claim
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:amount, :currency, :task_id, :owner_id, :creator_id])
    |> validate_required([:amount, :currency, :task_id, :owner_id, :creator_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:currency, ["USD"])
  end
end
