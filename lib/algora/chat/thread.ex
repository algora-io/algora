defmodule Algora.Chat.Thread do
  use Algora.Model

  schema "threads" do
    field :title, :string
    field :type, Ecto.Enum, values: [:direct, :group]

    has_many :messages, Algora.Chat.Message
    has_many :participants, Algora.Chat.Participant

    timestamps()
  end

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:title, :type])
    |> validate_required([:type])
  end
end
