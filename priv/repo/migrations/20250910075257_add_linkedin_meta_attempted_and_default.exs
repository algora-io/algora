defmodule Algora.Repo.Migrations.AddLinkedinMetaAttemptedAndDefault do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :linkedin_meta_attempted, :boolean, default: false
      modify :linkedin_meta, :map, default: %{}
    end

    execute "UPDATE users SET linkedin_meta = '{}' WHERE linkedin_meta IS NULL"
  end
end
