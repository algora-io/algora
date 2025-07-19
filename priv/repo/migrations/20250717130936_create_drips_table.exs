defmodule Algora.Repo.Migrations.CreateDripsTable do
  use Ecto.Migration

  def change do
    create table(:drips, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_ids, {:array, :string}, null: false
      add :org_id, references(:users, type: :string), null: false
      add :subject, :string
      add :body, :text
      add :email_addresses, {:array, :string}
      add :image_url, :string
      add :sent_at, :utc_datetime

      timestamps()
    end

    create index(:drips, [:org_id])
    create index(:drips, [:sent_at])
    create index(:drips, [:user_ids], using: :gin)
  end
end
