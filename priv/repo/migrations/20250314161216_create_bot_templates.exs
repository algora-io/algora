defmodule Algora.Repo.Migrations.CreateBotTemplates do
  use Ecto.Migration

  def change do
    create table(:bot_templates) do
      add :template, :text, null: false
      add :type, :string, null: false
      add :active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:bot_templates, [:user_id, :type])
  end
end
