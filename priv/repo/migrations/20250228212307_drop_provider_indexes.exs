defmodule Algora.Repo.Migrations.DropProviderIndexes do
  use Ecto.Migration

  def up do
    drop unique_index(:payment_methods, [:provider, :provider_id])
    drop unique_index(:customers, [:provider, :provider_id])
  end

  def down do
    create unique_index(:payment_methods, [:provider, :provider_id])
    create unique_index(:customers, [:provider, :provider_id])
  end
end
