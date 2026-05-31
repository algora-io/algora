defmodule Algora.Crypto.CryptoEscrow do
  @moduledoc """
  Schema for on-chain escrow records.

  Tracks the lifecycle of a crypto escrow from creation through
  release or refund. Each escrow corresponds to an on-chain PDA
  account in the Solana Escrow smart contract.

  The escrow flow:
  1. `created` - USDC deposited into escrow PDA on-chain
  2. `released` - Funds released to contributor (95%) + platform (5%)
  3. `refunded` - Funds returned to payer after deadline
  """

  use Algora.Schema

  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Tip
  alias Algora.Payments.Transaction

  @networks [:solana]
  @states [:created, :released, :refunded, :failed]

  @default_platform_fee_bps 500
  @default_mint_address "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

  typed_schema "crypto_escrows" do
    field :group_id, :string, null: false
    field :network, Ecto.Enum, values: @networks, null: false, default: :solana
    field :mint_address, :string, null: false
    field :amount, :integer, null: false
    field :platform_fee_bps, :integer, null: false, default: @default_platform_fee_bps
    field :deadline, :utc_datetime_usec, null: false
    field :state, Ecto.Enum, values: @states, null: false, default: :created

    # On-chain account addresses
    field :escrow_account_address, :string
    field :escrow_token_account_address, :string

    # Transaction signatures
    field :create_transaction_signature, :string
    field :release_transaction_signature, :string
    field :refund_transaction_signature, :string

    field :nonce, :integer, null: false, default: 0
    field :provider_meta, :map, default: %{}

    belongs_to :payer_wallet, Algora.Crypto.CryptoWallet, null: false
    belongs_to :contributor_wallet, Algora.Crypto.CryptoWallet, null: false
    belongs_to :platform_wallet, Algora.Crypto.CryptoWallet, null: false
    belongs_to :bounty, Bounty
    belongs_to :tip, Tip
    belongs_to :claim, Claim
    belongs_to :transaction, Transaction

    timestamps()
  end

  @doc """
  Changeset for creating a new escrow record.
  """
  def changeset(escrow, attrs) do
    escrow
    |> cast(attrs, [
      :id,
      :group_id,
      :network,
      :mint_address,
      :amount,
      :platform_fee_bps,
      :deadline,
      :state,
      :escrow_account_address,
      :escrow_token_account_address,
      :create_transaction_signature,
      :nonce,
      :provider_meta,
      :payer_wallet_id,
      :contributor_wallet_id,
      :platform_wallet_id,
      :bounty_id,
      :tip_id,
      :claim_id,
      :transaction_id
    ])
    |> validate_required([
      :group_id,
      :network,
      :mint_address,
      :amount,
      :platform_fee_bps,
      :deadline,
      :payer_wallet_id,
      :contributor_wallet_id,
      :platform_wallet_id
    ])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:platform_fee_bps, greater_than: 0, less_than_or_equal_to: 10000)
    |> unique_constraint(:group_id)
    |> unique_constraint(:escrow_account_address)
    |> foreign_key_constraint(:payer_wallet_id)
    |> foreign_key_constraint(:contributor_wallet_id)
    |> foreign_key_constraint(:platform_wallet_id)
    |> foreign_key_constraint(:bounty_id)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:claim_id)
    |> foreign_key_constraint(:transaction_id)
    |> put_default_mint_address()
    |> generate_id()
  end

  @doc """
  Changeset for marking escrow as released.
  """
  def release_changeset(escrow, attrs) do
    escrow
    |> cast(attrs, [:release_transaction_signature, :provider_meta])
    |> validate_required([:release_transaction_signature])
    |> put_change(:state, :released)
  end

  @doc """
  Changeset for marking escrow as refunded.
  """
  def refund_changeset(escrow, attrs) do
    escrow
    |> cast(attrs, [:refund_transaction_signature, :provider_meta])
    |> validate_required([:refund_transaction_signature])
    |> put_change(:state, :refunded)
  end

  @doc """
  Calculates the platform fee amount in USDC lamports (6 decimals).
  """
  def platform_fee_amount(%__MODULE__{amount: amount, platform_fee_bps: bps}) do
    div(amount * bps, 10_000)
  end

  @doc """
  Calculates the contributor amount in USDC lamports (6 decimals).
  """
  def contributor_amount(%__MODULE__{amount: amount, platform_fee_bps: bps}) do
    amount - div(amount * bps, 10_000)
  end

  @doc """
  Returns the default USDC mint address for Solana mainnet.
  """
  def default_mint_address, do: @default_mint_address

  @doc """
  Returns the default platform fee in basis points.
  """
  def default_platform_fee_bps, do: @default_platform_fee_bps

  defp put_default_mint_address(changeset) do
    case get_field(changeset, :mint_address) do
      nil -> put_change(changeset, :mint_address, @default_mint_address)
      _ -> changeset
    end
  end
end
