defmodule Algora.Chat.Participant do
  @moduledoc false
  use Algora.Schema

  typed_schema "chat_participants" do
    field :last_read_at, :utc_datetime_usec

    belongs_to :thread, Algora.Chat.Thread
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:last_read_at, :thread_id, :user_id])
    |> validate_required([:last_read_at, :thread_id, :user_id])
    |> foreign_key_constraint(:thread_id)
    |> foreign_key_constraint(:user_id)
    |> generate_id()
  end
end
