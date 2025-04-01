defmodule Algora.Repo.Migrations.MakeTicketUrlNullable do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      modify :url, :string, null: true
    end
  end
end
