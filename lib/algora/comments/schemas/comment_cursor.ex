defmodule Algora.Comments.CommentCursor do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  schema "comment_cursors" do
    field :provider, :string
    field :repo_owner, :string
    field :repo_name, :string
    field :timestamp, :utc_datetime_usec
    field :last_polled_at, :utc_datetime_usec
    field :last_comment_id, :string

    timestamps()
  end

  @doc false
  def changeset(comment_cursor, attrs) do
    comment_cursor
    |> cast(attrs, [
      :provider,
      :repo_owner,
      :repo_name,
      :timestamp,
      :last_polled_at,
      :last_comment_id
    ])
    |> generate_id()
    |> validate_required([:provider, :repo_owner, :repo_name, :timestamp])
    |> unique_constraint([:provider, :repo_owner, :repo_name])
  end
end
