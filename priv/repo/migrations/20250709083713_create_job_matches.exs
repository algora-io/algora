defmodule Algora.Repo.Migrations.CreateJobMatches do
  use Ecto.Migration

  def change do
    create table(:job_matches) do
      add :user_id, references(:users, on_delete: :delete_all, type: :string), null: false

      add :job_posting_id, references(:job_postings, on_delete: :delete_all, type: :string),
        null: false

      add :status, :string, null: false, default: "pending"
      add :score, :decimal, precision: 5, scale: 2
      add :notes, :text

      timestamps()
    end

    create unique_index(:job_matches, [:user_id, :job_posting_id])
    create index(:job_matches, [:user_id])
    create index(:job_matches, [:job_posting_id])
    create index(:job_matches, [:status])
  end
end
