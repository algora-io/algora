defmodule Algora.Repo.Migrations.CreateLanguageContributions do
  use Ecto.Migration

  def change do
    create table(:language_contributions) do
      add :user_id, :string, null: false
      add :language, :citext, null: false
      add :prs, :integer, null: false
      add :percentage, :decimal, null: false

      timestamps()
    end

    create unique_index(:language_contributions, [:user_id, :language])
    create index(:language_contributions, [:user_id])
    create index(:language_contributions, [:language])
  end
end
