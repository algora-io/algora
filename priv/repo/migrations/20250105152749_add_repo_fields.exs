defmodule Algora.Repo.Migrations.AddRepoFields do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :description, :text
      add :og_image_url, :string
      add :og_image_updated_at, :utc_datetime_usec
    end

    # Backfill existing repositories with default values
    execute """
    UPDATE repositories
    SET og_image_url = REPLACE(url, 'https://github.com', 'https://opengraph.githubassets.com/0')
    WHERE og_image_url IS NULL
    """

    # Make columns non-nullable after backfill
    alter table(:repositories) do
      modify :og_image_url, :string, null: false
    end
  end
end
