defmodule AlgoraWeb.Forms.ContractForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Algora.Types.USD
  alias Algora.Validations

  embedded_schema do
    field :hourly_rate, USD
    field :hours_per_week, :integer
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:hourly_rate, :hours_per_week])
    |> validate_required([:hourly_rate, :hours_per_week])
    |> Validations.validate_money_positive(:hourly_rate)
    |> validate_number(:hours_per_week, greater_than: 0, less_than_or_equal_to: 40)
  end
end
