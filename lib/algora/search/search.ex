defmodule Algora.Search do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Algora.Search.SearchCursor
  alias Algora.Repo

  def get_search_cursor(provider) do
    Repo.get_by(SearchCursor, provider: provider)
  end

  def delete_search_cursor(provider) do
    case get_search_cursor(provider) do
      nil -> {:error, :cursor_not_found}
      cursor -> Repo.delete(cursor)
    end
  end

  def create_search_cursor(attrs \\ %{}) do
    %SearchCursor{}
    |> SearchCursor.changeset(attrs)
    |> Repo.insert()
  end

  def update_search_cursor(%SearchCursor{} = search_cursor, attrs) do
    search_cursor
    |> SearchCursor.changeset(attrs)
    |> Repo.update()
  end

  def list_cursors do
    Repo.all(from(p in SearchCursor))
  end
end
