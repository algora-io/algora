defmodule Algora.Repo.Migrations.AddPhoneNumberToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone_number, :text
    end
  end
end
