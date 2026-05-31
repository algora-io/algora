defmodule Algora.Crypto.Jobs.VerifyEscrow do
  @moduledoc """
  Oban job for verifying pending crypto escrow transactions on-chain.

  This job is enqueued after a crypto escrow is created to poll for
  on-chain confirmation. It retries with exponential backoff.
  """

  use Oban.Worker,
    queue: :crypto,
    max_attempts: 10,
    unique: [period: :infinity]

  alias Algora.Crypto.OnChainVerifier
  alias Algora.Crypto.CryptoEscrow
  alias Algora.Repo

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"escrow_id" => escrow_id, "action" => action, "signature" => signature}}) do
    case action do
      "create" ->
        OnChainVerifier.verify_creation(escrow_id, signature)

      "release" ->
        OnChainVerifier.verify_release(escrow_id, signature)

      "refund" ->
        OnChainVerifier.verify_refund(escrow_id, signature)

      unknown ->
        Logger.error("Unknown escrow verification action: #{unknown}")
        {:error, :unknown_action}
    end
  end

  @doc """
  Enqueues a verification job for an escrow creation.
  """
  def enqueue_creation(escrow_id, signature) do
    __MODULE__.new(%{escrow_id: escrow_id, action: "create", signature: signature})
    |> Oban.insert()
  end

  @doc """
  Enqueues a verification job for an escrow release.
  """
  def enqueue_release(escrow_id, signature) do
    __MODULE__.new(%{escrow_id: escrow_id, action: "release", signature: signature})
    |> Oban.insert()
  end

  @doc """
  Enqueues a verification job for an escrow refund.
  """
  def enqueue_refund(escrow_id, signature) do
    __MODULE__.new(%{escrow_id: escrow_id, action: "refund", signature: signature})
    |> Oban.insert()
  end
end
