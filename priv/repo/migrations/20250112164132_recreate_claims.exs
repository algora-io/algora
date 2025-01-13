defmodule Algora.Repo.Migrations.RecreateClaims do
  use Ecto.Migration

  def up do
    drop index(:claims, [:bounty_id])
    drop index(:claims, [:user_id])
    drop table(:claims)

    create table(:claims) do
      add :status, :string, null: false
      add :type, :string, null: false
      add :url, :string, null: false
      add :group_id, :string, null: false

      add :source_id, references(:tickets, on_delete: :nothing), null: false
      add :target_id, references(:tickets, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:claims, [:target_id, :user_id])
    create index(:claims, [:source_id])
    create index(:claims, [:target_id])
    create index(:claims, [:user_id])
  end

  def down do
    drop unique_index(:claims, [:target_id, :user_id])
    drop index(:claims, [:source_id])
    drop index(:claims, [:target_id])
    drop index(:claims, [:user_id])
    drop table(:claims)

    create table(:claims) do
      add :provider, :string
      add :provider_id, :string
      add :provider_meta, :map

      add :type, :string

      add :status, :string

      add :merged_at, :utc_datetime_usec
      add :approved_at, :utc_datetime_usec
      add :rejected_at, :utc_datetime_usec
      add :charged_at, :utc_datetime_usec
      add :paid_at, :utc_datetime_usec

      add :title, :string
      add :description, :string
      add :url, :string
      add :group_id, :string

      add :bounty_id, references(:bounties, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:claims, [:bounty_id])
    create index(:claims, [:user_id])
  end
end
