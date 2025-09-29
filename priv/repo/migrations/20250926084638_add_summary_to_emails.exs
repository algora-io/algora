defmodule Algora.Repo.Migrations.AddSummaryToEmails do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      add :summary, :text
    end
  end
end
