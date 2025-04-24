defmodule Algora.Repo.Migrations.CreateJobApplications do
  use Ecto.Migration

  def change do
    create table(:job_applications, primary_key: false) do
      add :id, :string, primary_key: true
      add :status, :string, null: false, default: "pending"
      add :job_id, references(:job_postings, type: :string, on_delete: :restrict), null: false
      add :user_id, references(:users, type: :string, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:job_applications, [:job_id])
    create index(:job_applications, [:user_id])
    create unique_index(:job_applications, [:job_id, :user_id])
  end
end
