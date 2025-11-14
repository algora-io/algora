defmodule Algora.Repo.Migrations.AddJobUrlsToLeads do
  use Ecto.Migration

  def change do
    alter table(:leads) do
      add :job_urls, {:array, :string}, default: []
    end
  end
end
