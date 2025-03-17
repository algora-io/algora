defmodule AlgoraWeb.Forms.TipForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Algora.Types.USD
  alias Algora.Validations

  embedded_schema do
    field :github_handle, :string
    field :amount, USD
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:github_handle, :amount])
    |> validate_required([:github_handle, :amount])
    |> Validations.validate_money_positive(:amount)
  end
end
