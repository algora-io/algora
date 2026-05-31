defmodule Algora.PSP.Crypto do
  @moduledoc """
  Crypto Payment Service Provider interface.

  Provides the same interface as the Stripe PSP but for crypto payments.
  This module is called when the transaction provider is "crypto".

  Unlike Stripe, crypto payments don't use checkout sessions.
  Instead, the flow is:
  1. Frontend creates escrow on-chain via Wallet Adapter
  2. Backend verifies the on-chain transaction
  3. Backend records the escrow and transactions

  This module handles the backend side of step 2-3.
  """

  alias Algora.Crypto
  alias Algora.Crypto.CryptoEscrow
  alias Algora.Crypto.OnChainVerifier
  alias Algora.Crypto.Solana
  alias Algora.Repo

  require Logger

  # ============================================================
  # Session Creation (Crypto variant)
  # ============================================================

  @doc """
  Creates a "crypto session" — returns escrow parameters for the frontend
  to construct the on-chain transaction.

  Unlike Stripe sessions which redirect to a hosted checkout,
  crypto sessions return the data needed for client-side wallet signing.
  """
  @spec create_session(map()) :: {:ok, map()} | {:error, atom()}
  def create_session(%{
        payer: payer,
        contributor: contributor,
        amount: amount,
        bounty_id: bounty_id,
        tip_id: tip_id,
        claim_id: claim_id
      }) do
    escrow_data = Crypto.build_escrow_transaction_data(%{
      payer: payer,
      contributor: contributor,
      amount: amount
    })

    {:ok, %{
      provider: "crypto",
      escrow_id: escrow_data.escrow_id,
      network: escrow_data.network,
      payer_address: escrow_data.payer_address,
      contributor_address: escrow_data.contributor_address,
      platform_address: escrow_data.platform_address,
      mint_address: escrow_data.mint_address,
      amount: escrow_data.amount,
      platform_fee_bps: escrow_data.platform_fee_bps,
      deadline: escrow_data.deadline,
      program_id: Solana.escrow_program_id()
    }}
  end

  # ============================================================
  # Transaction Verification
  # ============================================================

  @doc """
  Verifies and records a crypto escrow creation.

  Called when the frontend submits the transaction signature
  after the user signs the escrow creation in their wallet.
  """
  @spec verify_and_record_escrow(map()) :: {:ok, CryptoEscrow.t()} | {:error, atom()}
  def verify_and_record_escrow(%{
        escrow_id: escrow_id,
        signature: signature,
        escrow_account_address: escrow_account_address,
        escrow_token_account_address: escrow_token_account_address
      }) do
    with {:ok, escrow} <- Repo.fetch(CryptoEscrow, escrow_id),
         {:ok, updated_escrow} <-
           escrow
           |> Ecto.Changeset.change(%{
             escrow_account_address: escrow_account_address,
             escrow_token_account_address: escrow_token_account_address,
             create_transaction_signature: signature
           })
           |> Repo.update() do
      # Enqueue verification job
      case Algora.Crypto.Jobs.VerifyEscrow.enqueue_creation(escrow_id, signature) do
        {:ok, _job} -> {:ok, updated_escrow}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Processes a release signature submitted by the payer.
  """
  @spec process_release(String.t(), String.t()) :: {:ok, CryptoEscrow.t()} | {:error, atom()}
  def process_release(escrow_id, signature) do
    OnChainVerifier.verify_release(escrow_id, signature)
  end

  @doc """
  Processes a refund signature submitted by the payer.
  """
  @spec process_refund(String.t(), String.t()) :: {:ok, CryptoEscrow.t()} | {:error, atom()}
  def process_refund(escrow_id, signature) do
    OnChainVerifier.verify_refund(escrow_id, signature)
  end

  # ============================================================
  # Account Management
  # ============================================================

  @doc """
  Checks if a user can receive crypto payouts by verifying
  they have an active wallet linked.
  """
  @spec payouts_enabled?(Algora.Accounts.User.t()) :: boolean()
  def payouts_enabled?(user) do
    Crypto.has_crypto_wallet?(user)
  end

  @doc """
  Returns the crypto fee structure.
  """
  @spec fee_structure() :: %{platform_fee_bps: integer(), transaction_fee_pct: Decimal.t()}
  def fee_structure do
    %{
      platform_fee_bps: CryptoEscrow.default_platform_fee_bps(),
      transaction_fee_pct: Crypto.get_crypto_transaction_fee_pct()
    }
  end
end
