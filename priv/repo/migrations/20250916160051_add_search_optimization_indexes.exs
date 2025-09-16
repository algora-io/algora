defmodule Algora.Repo.Migrations.AddSearchOptimizationIndexes do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION IF EXISTS pg_trgm"

    create index(:users, ["lower(provider_login) gin_trgm_ops"],
             using: :gin,
             where: "provider_login IS NOT NULL"
           )

    create index(:users, ["lower(bio) gin_trgm_ops"],
             using: :gin,
             where: "bio IS NOT NULL"
           )

    create index(:users, ["lower(readme) gin_trgm_ops"],
             using: :gin,
             where: "readme IS NOT NULL"
           )

    create index(:users, ["lower(internal_notes) gin_trgm_ops"],
             using: :gin,
             where: "internal_notes IS NOT NULL"
           )

    create index(:users, ["lower(provider_meta ->> 'company') gin_trgm_ops"],
             using: :gin,
             where: "provider_meta ->> 'company' IS NOT NULL"
           )

    create index(:users, ["lower(linkedin_meta ->> 'experience') gin_trgm_ops"],
             using: :gin,
             where: "linkedin_meta ->> 'experience' IS NOT NULL"
           )

    create index(:repositories, [:user_id, "lower(name)"], where: "name IS NOT NULL")
  end
end
