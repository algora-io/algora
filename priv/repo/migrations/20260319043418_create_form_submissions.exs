defmodule Algora.Repo.Migrations.CreateFormSubmissions do
  use Ecto.Migration

  def change do
    create table(:form_submissions, primary_key: false) do
      add :id, :string, primary_key: true
      add :form, :string, null: false
      add :email, :string
      add :payload, :map, null: false, default: %{}

      timestamps()
    end

    create index(:form_submissions, [:form])
    create index(:form_submissions, [:email])
    create index(:form_submissions, [:inserted_at])
  end
end
