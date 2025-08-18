defmodule Algora.Accounts.Follow do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  typed_schema "follows" do
    belongs_to :follower, User, foreign_key: :follower_id, type: :string
    belongs_to :followed, User, foreign_key: :followed_id, type: :string

    field :provider, :string, default: "github"
    field :provider_created_at, :utc_datetime_usec

    timestamps()
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followed_id, :provider, :provider_created_at])
    |> validate_required([:follower_id, :followed_id, :provider])
    |> generate_id()
    |> unique_constraint([:follower_id, :followed_id], name: :follows_follower_id_followed_id_index)
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:followed_id)
    |> validate_not_self_follow()
  end

  defp validate_not_self_follow(changeset) do
    follower_id = get_field(changeset, :follower_id)
    followed_id = get_field(changeset, :followed_id)

    if follower_id && followed_id && follower_id == followed_id do
      add_error(changeset, :followed_id, "cannot follow yourself")
    else
      changeset
    end
  end
end
