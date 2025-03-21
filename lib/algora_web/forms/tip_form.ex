defmodule AlgoraWeb.Forms.TipForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Algora.Types.USD
  alias Algora.Validations

  embedded_schema do
    field :url, :string
    field :github_handle, :string
    field :amount, USD

    embeds_one :ticket_ref, TicketRef, primary_key: false do
      field :owner, :string
      field :repo, :string
      field :number, :integer
      field :type, :string
    end
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:url, :github_handle, :amount])
    |> validate_required([:url, :github_handle, :amount])
    |> Validations.validate_money_positive(:amount)
    |> Validations.validate_ticket_ref(:url, :ticket_ref)
  end
end
