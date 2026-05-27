defmodule Algora.Repo.Migrations.AddInternalTagsToUsers do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    alter table(:users) do
      add :internal_tags, {:array, :string}, default: [], null: false
    end

    create index(:users, [:internal_tags],
             name: :users_internal_tags_nonempty_index,
             using: :gin,
             where: "internal_tags <> '{}'",
             concurrently: true
           )
  end
end
