defmodule Algora.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
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
