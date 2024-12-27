defmodule Algora.Events do
  import Ecto.Query, warn: false
  alias Algora.Repo
  alias Algora.Events.EventCursor

  def get_event_cursor(provider, repo_owner, repo_name) do
    Repo.get_by(EventCursor, provider: provider, repo_owner: repo_owner, repo_name: repo_name)
  end

  def create_event_cursor(attrs \\ %{}) do
    %EventCursor{}
    |> EventCursor.changeset(attrs)
    |> Repo.insert()
  end

  def update_event_cursor(%EventCursor{} = event_cursor, attrs) do
    event_cursor
    |> EventCursor.changeset(attrs)
    |> Repo.update()
  end

  def list_cursors do
    Repo.all(from(p in EventCursor))
  end
end
