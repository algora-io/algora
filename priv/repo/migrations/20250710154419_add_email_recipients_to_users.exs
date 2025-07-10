defmodule Algora.Repo.Migrations.AddEmailRecipientsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email_recipients, {:array, :map}, default: []
    end
  end
end
