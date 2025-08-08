defmodule Algora.Repo.Migrations.CreateExperiences do
  use Ecto.Migration

  def change do
    create table(:experiences, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :title, :text, null: false
      add :company, :text, null: false
      add :employment_type, :string
      add :location, :text
      add :description, :text
      add :skills, {:array, :text}, default: []
      add :start_date, :date
      add :end_date, :date
      add :is_current, :boolean, default: false
      add :duration_text, :text
      add :company_url, :text
      add :source, :string

      timestamps()
    end

    create index(:experiences, [:user_id])
    create index(:experiences, [:start_date])
    create index(:experiences, [:user_id, :start_date])
    create index(:experiences, [:user_id, :is_current])
  end
end
