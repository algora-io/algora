defmodule Algora.Repo.Migrations.AddTopicsToRepositories do
  use Ecto.Migration

  def up do
    alter table(:repositories) do
      add :topics, {:array, :citext}, null: false, default: []
    end

    # Backfill topics from provider_meta
    execute """
    UPDATE repositories
    SET topics = ARRAY(
      SELECT jsonb_array_elements_text(
        COALESCE(provider_meta->'topics', '[]'::jsonb)
      )
    )
    """
  end

  def down do
    alter table(:repositories) do
      remove :topics
    end
  end
end
