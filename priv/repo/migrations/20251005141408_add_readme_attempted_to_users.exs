defmodule Algora.Repo.Migrations.AddReadmeAttemptedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :readme_attempted, :boolean, default: false, null: false
    end

    create index(:users, [:readme_attempted])
  end
end
