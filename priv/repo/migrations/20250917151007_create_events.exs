defmodule Algora.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :string, primary_key: true
      add :type, :string, null: false
      add :payload, :map
      add :origin_id, :string, null: false
      add :seq, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:events, [:type])
    create index(:events, [:origin_id])
    create index(:events, [:origin_id, :seq])
    create index(:events, [:inserted_at])
  end
end
