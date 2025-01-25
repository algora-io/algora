defmodule Algora.Workspace.CommandResponse do
  @moduledoc """
  Schema for tracking command comments and their corresponding bot responses.
  This allows updating existing bot responses instead of creating new ones.
  """
  use Algora.Schema

  typed_schema "command_responses" do
    field :provider, :string, null: false
    field :provider_meta, :map, null: false
    field :provider_command_id, :string
    field :provider_response_id, :string, null: false
    field :command_source, Ecto.Enum, values: [:ticket, :comment], null: false
    field :command_type, Ecto.Enum, values: [:bounty, :attempt, :claim], null: false

    belongs_to :ticket, Algora.Workspace.Ticket, null: false

    timestamps()
  end

  def changeset(command_response, attrs) do
    command_response
    |> cast(attrs, [
      :provider,
      :provider_meta,
      :provider_command_id,
      :provider_response_id,
      :command_source,
      :command_type,
      :ticket_id
    ])
    |> validate_required([
      :provider,
      :provider_meta,
      :provider_response_id,
      :command_source,
      :command_type,
      :ticket_id
    ])
    |> generate_id()
    |> foreign_key_constraint(:ticket_id)
    |> unique_constraint([:provider, :provider_command_id])
  end
end
