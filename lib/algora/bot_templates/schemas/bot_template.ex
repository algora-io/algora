defmodule Algora.BotTemplates.BotTemplate do
  @moduledoc false
  use Algora.Schema

  import Ecto.Changeset

  @types [
    :multiple_attempts_detected,
    :attempt_rejected,
    :bounty_created,
    :claim_submitted,
    :bounty_awarded
  ]

  typed_schema "bot_templates" do
    field :template, :string, null: false
    field :type, Ecto.Enum, values: @types, null: false
    field :active, :boolean, null: false, default: true
    belongs_to :user, Algora.Accounts.User, null: false

    timestamps()
  end

  def changeset(bot_template, attrs) do
    bot_template
    |> cast(attrs, [:template, :type, :active, :org_id])
    |> validate_required([:template, :type, :org_id])
    |> generate_id()
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :type])
  end
end
