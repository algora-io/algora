defmodule Algora.Repo.Migrations.AddEmploymentInfoToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :employment_info, :map, default: %{}
    end
  end
end
