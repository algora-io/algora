defmodule Algora.Repo.Migrations.AddResumeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :resume, :text
    end
  end
end
