defmodule Algora.Repo.Migrations.AddCompanyPitchAndAlgoraNoteToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :company_pitch, :text
      add :algora_note, :text
    end
  end
end
