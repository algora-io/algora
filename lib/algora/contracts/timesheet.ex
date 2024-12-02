defmodule Algora.Contracts.Timesheet do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "timesheets" do
    field :hours_worked, :integer
    field :description, :string

    belongs_to :contract, Algora.Contracts.Contract
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(timesheet, attrs) do
    timesheet
    |> cast(attrs, [:hours_worked, :description])
    |> validate_required([:hours_worked])
    |> generate_id()
  end
end
