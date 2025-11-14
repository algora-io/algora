defmodule Algora.Repo.Migrations.CreateLeads do
  use Ecto.Migration

  def change do
    # Drop existing tables if they exist
    drop_if_exists table(:lead_job_invitations)
    drop_if_exists table(:lead_jobs)
    drop_if_exists table(:leads)

    create table(:leads, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :seed, :text, null: false
      add :name, :string
      add :bio, :text
      add :avatar_url, :text
      add :website_url, :string
      add :careers_url, :string
      add :job_ids, {:array, :string}, default: []
      add :members, :jsonb, default: "[]"
      add :user_id, references(:users, type: :string, on_delete: :nilify_all)

      timestamps()
    end

    create index(:leads, [:user_id])
  end
end
