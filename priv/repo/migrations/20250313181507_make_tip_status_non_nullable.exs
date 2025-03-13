defmodule Algora.Repo.Migrations.MakeTipStatusNonNullable do
  use Ecto.Migration

  def change do
    alter table(:tips) do
      modify :status, :string, null: false, default: "open"
    end
  end
end
