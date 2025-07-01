defmodule AlgoraWeb.Forms.ChallengeForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :email, :string
    field :description, :string
  end

  def changeset(form \\ %__MODULE__{}, attrs) do
    form
    |> cast(attrs, [:email, :description])
    |> validate_required([:email, :description])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:description, min: 1)
  end
end
