defmodule Algora.Repo.Migrations.AddUniqueIndexToClaimsUserIdSourceId do
  use Ecto.Migration

  def change do
    create unique_index(:claims, [:user_id, :source_id, :target_id])
  end
end
