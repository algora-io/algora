defmodule Algora.Crypto.OnChainVerifier do
  @moduledoc """
  On-chain verification service for crypto escrow events.

  Polls the Solana blockchain to verify escrow lifecycle events:
  - Escrow creation confirmation
  - Escrow release confirmation
  - Escrow refund confirmation

  This module is called by:
  - The CryptoWebhookController when a signature is submitted
  - The VerifyEscrowJob for periodic confirmation checks
  - The manual verification endpoint for debugging
  """

  alias Algora.Crypto
  alias Algora.Crypto.CryptoEscrow
  alias Algora.Crypto.Solana
  alias Algora.Repo

  require Logger

  @max_confirmation_retries 10
  @confirmation_poll_interval_ms 3_000

  @doc """
  Verifies an escrow creation transaction on-chain.

  Called after a payer submits the `create_escrow` transaction signature.
  Polls for confirmation up to the retry limit, then records the result.

  Returns:
  - `{:ok, escrow}` if confirmed and recorded
  - `{:error, :transaction_failed}` if the on-chain tx failed
  - `{:error, :confirmation_timeout}` if not confirmed within retries
  """
  @spec verify_creation(String.t(), String.t()) ::
          {:ok, CryptoEscrow.t()} | {:error, atom()}
  def verify_creation(escrow_id, signature) do
    with {:ok, escrow} <- Repo.fetch(CryptoEscrow, escrow_id),
         {:ok, _event} <- poll_for_confirmation(signature),
         {:ok, event_data} <- Solana.verify_escrow_created(signature) do
      Logger.info("Escrow #{escrow_id} creation confirmed on-chain: #{signature}")

      # Update the escrow with on-chain data
      escrow
      |> Ecto.Changeset.change(%{
        create_transaction_signature: signature,
        escrow_account_address: event_data[:escrow_account] || escrow.escrow_account_address,
        provider_meta: Map.merge(escrow.provider_meta || %{}, %{
          "verified_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "creation_signature" => signature
        })
      })
      |> Repo.update()
    else
      {:error, :confirmation_timeout} ->
        Logger.warning("Escrow #{escrow_id} creation confirmation timed out: #{signature}")
        {:error, :confirmation_timeout}

      {:error, :transaction_failed} ->
        Logger.error("Escrow #{escrow_id} creation transaction failed: #{signature}")
        mark_escrow_failed(escrow_id)
        {:error, :transaction_failed}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Verifies an escrow release transaction on-chain.

  Called after a payer submits the `release_escrow` transaction signature.
  """
  @spec verify_release(String.t(), String.t()) ::
          {:ok, CryptoEscrow.t()} | {:error, atom()}
  def verify_release(escrow_id, signature) do
    with {:ok, _event} <- poll_for_confirmation(signature),
         {:ok, event_data} <- Solana.verify_escrow_released(signature) do
      Logger.info("Escrow #{escrow_id} release confirmed on-chain: #{signature}")
      Crypto.process_escrow_release(escrow_id, signature)
    else
      {:error, :confirmation_timeout} ->
        Logger.warning("Escrow #{escrow_id} release confirmation timed out: #{signature}")
        {:error, :confirmation_timeout}

      {:error, :transaction_failed} ->
        Logger.error("Escrow #{escrow_id} release transaction failed: #{signature}")
        {:error, :transaction_failed}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Verifies an escrow refund transaction on-chain.

  Called after a payer submits the `refund_escrow` transaction signature.
  """
  @spec verify_refund(String.t(), String.t()) ::
          {:ok, CryptoEscrow.t()} | {:error, atom()}
  def verify_refund(escrow_id, signature) do
    with {:ok, _event} <- poll_for_confirmation(signature),
         {:ok, _event_data} <- Solana.verify_escrow_refunded(signature) do
      Logger.info("Escrow #{escrow_id} refund confirmed on-chain: #{signature}")
      Crypto.process_escrow_refund(escrow_id, signature)
    else
      {:error, :confirmation_timeout} ->
        Logger.warning("Escrow #{escrow_id} refund confirmation timed out: #{signature}")
        {:error, :confirmation_timeout}

      {:error, :transaction_failed} ->
        Logger.error("Escrow #{escrow_id} refund transaction failed: #{signature}")
        {:error, :transaction_failed}

      {:error, _} = error ->
        error
    end
  end

  # ============================================================
  # Private Helpers
  # ============================================================

  defp poll_for_confirmation(signature, retry \\ 0) do
    if retry >= @max_confirmation_retries do
      {:error, :confirmation_timeout}
    else
      case Solana.confirm_transaction(signature) do
        {:ok, %{status: status}} when status in ["confirmed", "finalized"] ->
          {:ok, %{status: status}}

        {:ok, %{status: "processed"}} ->
          Process.sleep(@confirmation_poll_interval_ms)
          poll_for_confirmation(signature, retry + 1)

        {:error, :transaction_not_found} ->
          Process.sleep(@confirmation_poll_interval_ms)
          poll_for_confirmation(signature, retry + 1)

        {:error, :transaction_failed} ->
          {:error, :transaction_failed}

        {:error, _} = error ->
          Process.sleep(@confirmation_poll_interval_ms)
          poll_for_confirmation(signature, retry + 1)
      end
    end
  end

  defp mark_escrow_failed(escrow_id) do
    with {:ok, escrow} <- Repo.fetch(CryptoEscrow, escrow_id) do
      escrow
      |> Ecto.Changeset.change(%{
        state: :failed,
        provider_meta: Map.merge(escrow.provider_meta || %{}, %{
          "failed_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "failure_reason" => "on_chain_transaction_failed"
        })
      })
      |> Repo.update()

      # Also cancel associated transactions
      from(t in Algora.Payments.Transaction,
        where: t.group_id == ^escrow.group_id,
        where: t.provider == "crypto"
      )
      |> Repo.update_all(set: [status: :failed])
    end
  end
end
