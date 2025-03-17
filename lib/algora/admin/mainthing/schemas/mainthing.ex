defmodule Algora.Admin.Mainthings.Mainthing do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "mainthings" do
    field :content, :string, null: false

    timestamps()
  end

  def changeset(mainthing, attrs) do
    mainthing
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> generate_id()
  end
end
