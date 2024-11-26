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
end
