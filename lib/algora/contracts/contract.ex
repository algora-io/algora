defmodule Algora.Contracts.Contract do
  use Ecto.Schema

  schema "contracts" do
    field :status, Ecto.Enum,
      values: [:draft, :pending, :active, :completed, :cancelled, :disputed]

    field :start_date, :date
    field :end_date, :date
    field :hourly_rate, :decimal
    field :hours_per_week, :integer
    field :total_paid, :decimal, default: Decimal.new(0)
    field :escrow_amount, :decimal
    field :next_payment_date, :date
    field :payment_schedule, Ecto.Enum, values: [:weekly, :biweekly, :monthly]
    field :auto_renew, :boolean, default: false

    # Contract terms
    field :scope_of_work, :string
    field :deliverables, {:array, :string}
    # [{title, description, due_date, completed}]
    field :milestones, {:array, :map}

    # Relationships
    belongs_to :company, Algora.Organizations.Organization
    belongs_to :developer, Algora.Users.User
    has_many :payments, Algora.Contracts.Payment
    has_many :disputes, Algora.Contracts.Dispute
    has_many :reviews, Algora.Contracts.Review
    has_many :messages, Algora.Contracts.Message
    has_one :current_escrow, Algora.Contracts.Escrow

    timestamps()
  end
end
