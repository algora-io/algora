defmodule Algora.Repo.Migrations.AddReferredByToTalents do
  use Ecto.Migration

  def change do
    alter table(:talents) do
      add :referred_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:talents, [:referred_by_id])
  end
end
