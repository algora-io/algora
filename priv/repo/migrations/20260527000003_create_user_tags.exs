defmodule Algora.Repo.Migrations.CreateUserTagsTable do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    create table(:user_tags, primary_key: false) do
      add :user_id, references(:users, type: :text, on_delete: :delete_all), null: false
      add :tag, :text, null: false
      timestamps()
    end

    execute "ALTER TABLE user_tags ADD PRIMARY KEY (user_id, tag)"
    create index(:user_tags, [:tag], name: :user_tags_tag_idx, concurrently: true)

    execute """
    INSERT INTO user_tags (user_id, tag, inserted_at, updated_at)
    SELECT id, lower(unnest(internal_tags)), now(), now()
    FROM users
    WHERE internal_tags <> '{}'
    ON CONFLICT DO NOTHING
    """
  end

  def down do
    drop table(:user_tags)
  end
end
