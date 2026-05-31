defmodule Algora.Repo.Migrations.CreateCryptoWallets do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE crypto_network AS ENUM ('solana')", "DROP TYPE crypto_network"
    execute "CREATE TYPE wallet_status AS ENUM ('active', 'inactive', 'verification_pending')",
            "DROP TYPE wallet_status"

    create table(:crypto_wallets, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :string), null: false
      add :address, :string, null: false
      add :network, :crypto_network, null: false, default: "solana"
      add :status, :wallet_status, null: false, default: "active"
      add :label, :string
      add :provider_meta, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:crypto_wallets, [:address, :network])
    create index(:crypto_wallets, [:user_id])
    create index(:crypto_wallets, [:network])
  end
end
