defmodule Algora.Chat.Thread do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity

  typed_schema "threads" do
    field :title, :string

    has_many :messages, Algora.Chat.Message
    has_many :participants, Algora.Chat.Participant
    has_many :activities, {"thread_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> generate_id()
  end
end
