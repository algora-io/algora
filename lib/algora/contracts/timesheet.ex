defmodule Algora.Contracts.Timesheet do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "timesheets" do
    field :hours_worked, :integer
    field :start_date, :date
    field :end_date, :date
    field :description, :string

    belongs_to :contract, Algora.Contracts.Contract
    belongs_to :provider, Algora.Users.User
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(timesheet, attrs) do
    timesheet
    |> cast(attrs, [:hours_worked, :start_date, :end_date, :description])
    |> validate_required([:hours_worked, :start_date, :end_date])
    |> generate_id()
  end
end
