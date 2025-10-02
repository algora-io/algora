defmodule Algora.Repo.Migrations.AddProviderLoginIndex do
  use Ecto.Migration

  def change do
    create index(:users, [:provider_login])
  end
end
