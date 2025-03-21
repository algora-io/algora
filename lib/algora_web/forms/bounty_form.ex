defmodule AlgoraWeb.Forms.BountyForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Algora.Types.USD
  alias Algora.Validations

  embedded_schema do
    field :url, :string
    field :amount, USD
    field :visibility, Ecto.Enum, values: [:community, :exclusive, :public], default: :public
    field :shared_with, {:array, :string}, default: []

    embeds_one :ticket_ref, TicketRef, primary_key: false do
      field :owner, :string
      field :repo, :string
      field :number, :integer
      field :type, :string
    end
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:url, :amount, :visibility, :shared_with])
    |> validate_required([:url, :amount])
    |> Validations.validate_money_positive(:amount)
    |> Validations.validate_ticket_ref(:url, :ticket_ref)
  end
end
