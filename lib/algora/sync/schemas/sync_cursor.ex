defmodule Algora.Sync.SyncCursor do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "sync_cursors" do
    field :provider, :string
    field :resource, :string
    field :timestamp, :utc_datetime_usec
    field :last_polled_at, :utc_datetime_usec

    timestamps()
  end

  @doc false
  def changeset(search_cursor, attrs) do
    search_cursor
    |> cast(attrs, [:provider, :resource, :timestamp, :last_polled_at])
    |> generate_id()
    |> validate_required([:provider, :resource, :timestamp])
    |> unique_constraint([:provider, :resource])
  end
end
