defmodule Algora.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :provider, :string
      add :provider_id, :string
      add :provider_meta, :map

      add :type, :string
      add :title, :string
      add :description, :text
      add :number, :integer
      add :url, :string

      add :repository_id, references(:repositories, on_delete: :delete_all)

      timestamps()
    end

    create index(:tickets, [:repository_id])

    # TODO: Reenable this after migration is complete.
    # create unique_index(:tickets, [:provider, :provider_id])
  end
end
