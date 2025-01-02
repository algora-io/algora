defmodule Algora.Chat.Thread do
  @moduledoc false
  use Algora.Schema

  schema "threads" do
    field :title, :string

    has_many :messages, Algora.Chat.Message
    has_many :participants, Algora.Chat.Participant

    timestamps()
  end

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> generate_id()
  end
end
