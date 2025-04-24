defmodule Algora.Repo.Migrations.CreateJobPostings do
  use Ecto.Migration

  def change do
    create table(:job_postings, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :string
      add :description, :text
      add :tech_stack, {:array, :string}, default: []
      add :url, :string
      add :company_name, :string
      add :company_url, :string
      add :email, :string
      add :status, :string, null: false, default: "initialized"
      add :expires_at, :utc_datetime_usec
      add :user_id, references(:users, type: :string, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:job_postings, [:user_id])
    create index(:job_postings, [:status])

    alter table(:transactions) do
      add :job_id, references(:job_postings, type: :string, on_delete: :restrict)
    end
  end
end
