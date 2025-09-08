defmodule Algora.Repo.Migrations.AddAiFlagsToReplies do
  use Ecto.Migration

  def change do
    alter table(:replies) do
      add :interested_in_opportunities, :string
      add :has_enough_context, :string
      add :wants_to_unsubscribe, :string
      add :requires_urgent_attention, :string
    end
  end
end
