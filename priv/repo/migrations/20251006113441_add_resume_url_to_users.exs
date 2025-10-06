defmodule Algora.Repo.Migrations.AddResumeUrlToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :resume_url, :string
    end
  end
end
