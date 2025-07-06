defmodule Algora.Repo.Migrations.AddInternalEmailToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :internal_email, :string
    end
  end
end
