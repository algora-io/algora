defmodule Algora.Repo.Migrations.AddCandidateVisibilityFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :candidates_require_login, :boolean, default: true
      add :candidates_require_confirmation, :boolean, default: true
    end
  end
end
