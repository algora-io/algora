defmodule Algora.Chat.Message do
  use Algora.Model

  schema "messages" do
    field :content, :string

    belongs_to :thread, Algora.Chat.Thread
    belongs_to :sender, Algora.Users.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :thread_id, :sender_id])
    |> validate_required([:content, :thread_id, :sender_id])
  end
end
