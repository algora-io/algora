defmodule Algora.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :ticket_id, references(:tickets, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:comments, [:ticket_id])
    create index(:comments, [:user_id])
    create unique_index(:comments, [:provider, :provider_id])
  end
end
