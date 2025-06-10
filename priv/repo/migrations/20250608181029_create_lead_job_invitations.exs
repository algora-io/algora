defmodule Algora.Repo.Migrations.CreateLeadJobInvitations do
  use Ecto.Migration

  def change do
    create table(:lead_job_invitations, primary_key: false) do
      add :id, :string, primary_key: true
      add :status, :string, null: false, default: "pending"

      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :lead_job_id, references(:lead_jobs, type: :string, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:lead_job_invitations, [:user_id, :lead_job_id],
             name: :lead_job_invitations_user_id_lead_job_id_index
           )
  end
end
