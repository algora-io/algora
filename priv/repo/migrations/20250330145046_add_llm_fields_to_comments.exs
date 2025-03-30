defmodule Algora.Repo.Migrations.AddLlmFieldsToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :llm_analyzed_at, :utc_datetime_usec
      add :llm_analysis, :text
    end

    create index(:comments, [:llm_analyzed_at])
  end
end
