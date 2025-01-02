defmodule Algora.Comments do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Algora.Comments.CommentCursor
  alias Algora.Repo

  def get_comment_cursor(provider, repo_owner, repo_name) do
    Repo.get_by(CommentCursor, provider: provider, repo_owner: repo_owner, repo_name: repo_name)
  end

  def delete_comment_cursor(provider, repo_owner, repo_name) do
    case get_comment_cursor(provider, repo_owner, repo_name) do
      nil -> {:error, :cursor_not_found}
      cursor -> Repo.delete(cursor)
    end
  end

  def create_comment_cursor(attrs \\ %{}) do
    %CommentCursor{}
    |> CommentCursor.changeset(attrs)
    |> Repo.insert()
  end

  def update_comment_cursor(%CommentCursor{} = comment_cursor, attrs) do
    comment_cursor
    |> CommentCursor.changeset(attrs)
    |> Repo.update()
  end

  def list_cursors do
    Repo.all(from(p in CommentCursor))
  end
end
