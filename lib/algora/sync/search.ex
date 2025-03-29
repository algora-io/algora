defmodule Algora.Sync do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Algora.Repo
  alias Algora.Sync.SyncCursor

  def get_sync_cursor(provider, resource) do
    Repo.get_by(SyncCursor, provider: provider, resource: resource)
  end

  def delete_sync_cursor(provider, resource) do
    case get_sync_cursor(provider, resource) do
      nil -> {:error, :cursor_not_found}
      cursor -> Repo.delete(cursor)
    end
  end

  def create_sync_cursor(attrs \\ %{}) do
    %SyncCursor{}
    |> SyncCursor.changeset(attrs)
    |> Repo.insert()
  end

  def update_sync_cursor(%SyncCursor{} = sync_cursor, attrs) do
    sync_cursor
    |> SyncCursor.changeset(attrs)
    |> Repo.update()
  end

  def list_cursors do
    Repo.all(from(p in SyncCursor))
  end
end
