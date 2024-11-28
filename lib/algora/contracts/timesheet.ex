defmodule Algora.Contracts.Timesheet do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "timesheets" do
    field :hours_worked, :integer
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :description, :string

    belongs_to :contract, Algora.Contracts.Contract
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
