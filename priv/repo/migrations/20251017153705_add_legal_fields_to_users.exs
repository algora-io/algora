defmodule Algora.Repo.Migrations.AddLegalFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :jurisdiction, :string
      add :entity_type, :string
      add :executive_email, :string
    end
  end
end
