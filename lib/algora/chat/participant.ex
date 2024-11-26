defmodule Algora.Chat.Participant do
  use Algora.Model

  schema "chat_participants" do
    field :last_read_at, :utc_datetime

    belongs_to :thread, Algora.Chat.Thread
    belongs_to :user, Algora.Users.User

    timestamps()
  end
end
