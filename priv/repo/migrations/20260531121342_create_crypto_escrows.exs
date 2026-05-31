defmodule Algora.Repo.Migrations.CreateCryptoEscrows do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE escrow_state AS ENUM ('created', 'released', 'refunded')",
            "DROP TYPE escrow_state"

    create table(:crypto_escrows, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :group_id, :string, null: false
      add :payer_wallet_id, references(:crypto_wallets, on_delete: :nothing, type: :string),
          null: false

      add :contributor_wallet_id, references(:crypto_wallets, on_delete: :nothing, type: :string),
          null: false

      add :platform_wallet_id, references(:crypto_wallets, on_delete: :nothing, type: :string),
          null: false

      add :network, :crypto_network, null: false, default: "solana"
      add :mint_address, :string, null: false
      add :amount, :bigint, null: false
      add :platform_fee_bps, :integer, null: false, default: 500
      add :deadline, :utc_datetime_usec, null: false
      add :state, :escrow_state, null: false, default: "created"
      add :escrow_account_address, :string
      add :escrow_token_account_address, :string
      add :create_transaction_signature, :string
      add :release_transaction_signature, :string
      add :refund_transaction_signature, :string
      add :nonce, :bigint, null: false, default: 0
      add :provider_meta, :map, default: %{}

      add :bounty_id, references(:bounties, on_delete: :nilify_all, type: :string)
      add :tip_id, references(:tips, on_delete: :nilify_all, type: :string)
      add :claim_id, references(:claims, on_delete: :nilify_all, type: :string)
      add :transaction_id, references(:transactions, on_delete: :nilify_all, type: :string)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:crypto_escrows, [:group_id])
    create unique_index(:crypto_escrows, [:escrow_account_address])
    create index(:crypto_escrows, [:payer_wallet_id])
    create index(:crypto_escrows, [:contributor_wallet_id])
    create index(:crypto_escrows, [:state])
    create index(:crypto_escrows, [:network])
    create index(:crypto_escrows, [:bounty_id])
    create index(:crypto_escrows, [:tip_id])
  end
end
