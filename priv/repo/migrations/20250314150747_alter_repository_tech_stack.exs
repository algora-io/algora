defmodule Algora.Repo.Migrations.AlterRepositoryTechStack do
  use Ecto.Migration

  def up do
    alter table(:repositories) do
      remove :language
      add :tech_stack, {:array, :citext}, null: false, default: "{}"
    end
  end

  def down do
    alter table(:repositories) do
      remove :tech_stack
      add :language, :string
    end
  end
end
