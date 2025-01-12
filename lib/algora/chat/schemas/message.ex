defmodule Algora.Chat.Message do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "messages" do
    field :content, :string

    belongs_to :thread, Algora.Chat.Thread
    belongs_to :sender, Algora.Accounts.User

    has_many :activities, {"message_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :thread_id, :sender_id])
    |> validate_required([:content, :thread_id, :sender_id])
    |> generate_id()
  end
end
