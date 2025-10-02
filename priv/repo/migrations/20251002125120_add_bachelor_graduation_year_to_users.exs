defmodule Algora.Repo.Migrations.AddBachelorGraduationYearToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :grad_year, :integer
    end
  end
end
