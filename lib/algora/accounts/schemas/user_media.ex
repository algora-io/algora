defmodule Algora.Accounts.UserMedia do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  typed_schema "user_media" do
    field :url, :string

    belongs_to :user, User

    timestamps()
  end

  def changeset(user_media, attrs) do
    user_media
    |> cast(attrs, [:url, :user_id])
    |> validate_required([:url, :user_id])
    |> generate_id()
    |> foreign_key_constraint(:user_id)
  end
end
