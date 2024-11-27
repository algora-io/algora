defmodule Algora.Chat.Participant do
  use Algora.Model

  schema "chat_participants" do
    field :last_read_at, :utc_datetime

    belongs_to :thread, Algora.Chat.Thread
    belongs_to :user, Algora.Users.User

    timestamps()
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:last_read_at])
    |> validate_required([:last_read_at])
  end
end
