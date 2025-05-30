defmodule Algora.Repo.Migrations.CreateLeadsAndLeadJobs do
  use Ecto.Migration

  def change do
    create table(:leads) do
      add :handle, :citext, null: false
      add :name, :string, null: false
      add :bio, :text
      add :avatar_url, :text

      timestamps()
    end

    create unique_index(:leads, [:handle])

    create table(:lead_jobs) do
      add :lead_id, references(:leads, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :description, :text
      add :tech_stack, {:array, :citext}, default: []
      add :match_ids, {:array, :string}, default: []
      add :location, :string
      add :countries, {:array, :citext}, default: []
      add :regions, {:array, :citext}, default: []

      timestamps()
    end

    create index(:lead_jobs, [:lead_id])
  end
end
