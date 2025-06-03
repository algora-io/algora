defmodule Algora.Repo.Migrations.CreateCandidateNotes do
  use Ecto.Migration

  def change do
    create table(:candidate_notes) do
      add :notes, {:array, :string}, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :job_id, references(:job_postings, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:candidate_notes, [:user_id, :job_id])
    create index(:candidate_notes, [:user_id])
    create index(:candidate_notes, [:job_id])
  end
end
