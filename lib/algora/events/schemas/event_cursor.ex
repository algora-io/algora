defmodule Algora.Events.EventCursor do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  typed_schema "event_cursors" do
    field :provider, :string
    field :repo_owner, :string
    field :repo_name, :string
    field :last_event_id, :string
    field :last_polled_at, :utc_datetime_usec

    timestamps()
  end

  @doc false
  def changeset(event_cursor, attrs) do
    event_cursor
    |> cast(attrs, [:provider, :repo_owner, :repo_name, :last_event_id, :last_polled_at])
    |> generate_id()
    |> validate_required([:provider, :repo_owner, :repo_name])
    |> unique_constraint([:provider, :repo_owner, :repo_name])
  end
end
