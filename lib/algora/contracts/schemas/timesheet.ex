defmodule Algora.Contracts.Timesheet do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "timesheets" do
    field :hours_worked, :integer
    field :description, :string

    belongs_to :contract, Algora.Contracts.Contract
    has_many :transactions, Algora.Payments.Transaction

    has_many :activities, {"timesheet_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(timesheet, attrs) do
    timesheet
    |> cast(attrs, [:hours_worked, :description])
    |> validate_required([:hours_worked])
    |> generate_id()
  end
end
