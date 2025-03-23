defmodule Algora.Search.SearchCursor do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "search_cursors" do
    field :provider, :string
    field :timestamp, :utc_datetime_usec
    field :last_polled_at, :utc_datetime_usec

    timestamps()
  end

  @doc false
  def changeset(search_cursor, attrs) do
    search_cursor
    |> cast(attrs, [:provider, :timestamp, :last_polled_at])
    |> generate_id()
    |> validate_required([:provider, :timestamp])
    |> unique_constraint([:provider])
  end
end
