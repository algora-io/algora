defmodule Algora.Repo.Migrations.CreatePaymentMethods do
  use Ecto.Migration

  def change do
    create table(:payment_methods) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, null: false
      add :provider_customer_id, :string, null: false
      add :is_default, :boolean, null: false, default: true

      add :customer_id, references(:customers, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:payment_methods, [:provider_customer_id])
    create unique_index(:payment_methods, [:provider, :provider_id])
    create unique_index(:payment_methods, [:customer_id], where: "is_default = true")
  end
end
