defmodule Algora.Chat.Message do
  @moduledoc false
  use Algora.Schema

  typed_schema "messages" do
    field :content, :string

    belongs_to :thread, Algora.Chat.Thread
    belongs_to :sender, Algora.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :thread_id, :sender_id])
    |> validate_required([:content, :thread_id, :sender_id])
    |> generate_id()
  end
end
