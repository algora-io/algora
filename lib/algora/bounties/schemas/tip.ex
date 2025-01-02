defmodule Algora.Bounties.Tip do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  @type t() :: %__MODULE__{}

  schema "tips" do
    field :amount, Money.Ecto.Composite.Type, no_fraction_if_integer: true
    field :status, Ecto.Enum, values: [:open, :cancelled, :paid]

    belongs_to :ticket, Algora.Workspace.Ticket
    belongs_to :owner, User
    belongs_to :creator, User
    belongs_to :recipient, User
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(tip, attrs) do
    tip
    |> cast(attrs, [:amount, :ticket_id, :owner_id, :creator_id, :recipient_id])
    |> validate_required([:amount, :owner_id, :creator_id, :recipient_id])
    |> generate_id()
    |> foreign_key_constraint(:ticket)
    |> foreign_key_constraint(:owner)
    |> foreign_key_constraint(:creator)
    |> foreign_key_constraint(:recipient)
    |> Algora.Validations.validate_money_positive(:amount)
  end
end
