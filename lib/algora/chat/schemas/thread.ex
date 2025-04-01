defmodule Algora.Chat.Thread do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "threads" do
    field :title, :string
    field :bounty_id, :string
    has_many :messages, Algora.Chat.Message
    has_many :participants, Algora.Chat.Participant
    has_many :activities, {"thread_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:title, :bounty_id])
    |> validate_required([:title])
    |> generate_id()
    |> unique_constraint(:bounty_id)
  end
end
