defmodule AlgoraWeb.CryptoController do
  @moduledoc """
  Controller for crypto payment webhook and API endpoints.

  Handles:
  - Escrow creation confirmations (signature submission)
  - Escrow release requests
  - Escrow refund requests
  - Wallet connection management
  """

  use AlgoraWeb, :controller

  alias Algora.Crypto
  alias Algora.Crypto.CryptoEscrow
  alias Algora.Crypto.CryptoWallet
  alias Algora.PSP.Crypto, as: CryptoPSP
  alias Algora.Repo

  plug :authenticate_user when action in [:link_wallet, :unlink_wallet, :escrow_params, :confirm_escrow, :release_escrow, :refund_escrow, :get_escrow]

  @doc """
  POST /api/crypto/wallets - Links a wallet to the authenticated user.
  """
  def link_wallet(conn, %{"address" => address, "network" => network}) do
    user = conn.assigns.current_user

    supported_networks = ["solana"]

    if network not in supported_networks do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Unsupported network. Supported: #{Enum.join(supported_networks, ", ")}"})
    else
      case Crypto.link_wallet(user, %{
             address: address,
             network: String.to_atom(network),
             label: conn.params["label"]
           }) do
        {:ok, wallet} ->
          conn
          |> put_status(:created)
          |> json(%{
            id: wallet.id,
            address: wallet.address,
            network: wallet.network,
            status: wallet.status,
            label: wallet.label
          })

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})

        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: to_string(reason)})
      end
    end
  end

  @doc """
  DELETE /api/crypto/wallets/:id - Unlinks a wallet.
  """
  def unlink_wallet(conn, %{"id" => wallet_id}) do
    user = conn.assigns.current_user

    with {:ok, wallet} <- Repo.fetch(CryptoWallet, wallet_id),
         true <- wallet.user_id == user.id do
      case Crypto.unlink_wallet(wallet_id) do
        {:ok, _wallet} ->
          conn |> json(%{success: true})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "wallet not found"})
    end
  end

  @doc """
  GET /api/crypto/escrow-params - Returns escrow parameters for frontend
  to construct the on-chain create_escrow transaction.
  """
  def escrow_params(conn, params) do
    user = conn.assigns.current_user

    with {:ok, contributor} <- resolve_contributor(params),
         amount when not is_nil(amount) <- parse_amount(params["amount"]),
         {:ok, session} <- CryptoPSP.create_session(%{
           payer: user,
           contributor: contributor,
           amount: amount,
           bounty_id: params["bounty_id"],
           tip_id: params["tip_id"],
           claim_id: params["claim_id"]
         }) do
      json(conn, session)
    else
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid or missing amount"})

      {:error, :payer_wallet_not_found} ->
        conn
        |> put_status(:precondition_failed)
        |> json(%{error: "No linked Solana wallet found. Please link a wallet first."})

      {:error, :contributor_wallet_not_found} ->
        conn
        |> put_status(:precondition_failed)
        |> json(%{error: "Recipient does not have a linked Solana wallet."})

      {:error, :contributor_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Contributor not found"})

      {:error, :contributor_required} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "contributor_handle or contributor_id is required"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  POST /api/crypto/escrow/confirm - Confirms escrow creation
  with the on-chain transaction signature.
  """
  def confirm_escrow(conn, %{
        "escrow_id" => escrow_id,
        "signature" => signature,
        "escrow_account_address" => escrow_account_address,
        "escrow_token_account_address" => escrow_token_account_address
      }) do
    case CryptoPSP.verify_and_record_escrow(%{
           escrow_id: escrow_id,
           signature: signature,
           escrow_account_address: escrow_account_address,
           escrow_token_account_address: escrow_token_account_address
         }) do
      {:ok, escrow} ->
        json(conn, %{
          escrow_id: escrow.id,
          state: escrow.state,
          message: "Escrow creation submitted for verification"
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Escrow not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  POST /api/crypto/escrow/:id/release - Submits a release signature
  for the payer to release escrowed funds to the contributor.
  """
  def release_escrow(conn, %{"id" => escrow_id, "signature" => signature}) do
    case CryptoPSP.process_release(escrow_id, signature) do
      {:ok, escrow} ->
        json(conn, %{
          escrow_id: escrow.id,
          state: escrow.state,
          message: "Escrow release submitted for verification"
        })

      {:error, :escrow_not_in_created_state} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Escrow is not in a releasable state"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  POST /api/crypto/escrow/:id/refund - Submits a refund signature.
  """
  def refund_escrow(conn, %{"id" => escrow_id, "signature" => signature}) do
    case CryptoPSP.process_refund(escrow_id, signature) do
      {:ok, escrow} ->
        json(conn, %{
          escrow_id: escrow.id,
          state: escrow.state,
          message: "Escrow refund submitted for verification"
        })

      {:error, :escrow_not_in_created_state} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Escrow is not in a refundable state"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  GET /api/crypto/escrow/:id - Gets escrow status.
  """
  def get_escrow(conn, %{"id" => escrow_id}) do
    case Repo.fetch(CryptoEscrow, escrow_id) do
      {:ok, escrow} ->
        json(conn, %{
          id: escrow.id,
          group_id: escrow.group_id,
          state: escrow.state,
          network: escrow.network,
          amount: escrow.amount,
          platform_fee_bps: escrow.platform_fee_bps,
          deadline: escrow.deadline,
          escrow_account_address: escrow.escrow_account_address,
          create_transaction_signature: escrow.create_transaction_signature,
          release_transaction_signature: escrow.release_transaction_signature,
          refund_transaction_signature: escrow.refund_transaction_signature,
          inserted_at: escrow.inserted_at
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Escrow not found"})
    end
  end

  # ============================================================
  # Private Helpers
  # ============================================================

  defp authenticate_user(conn, _opts) do
    if user = conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Authentication required"})
      |> halt()
    end
  end

  defp resolve_contributor(%{"contributor_handle" => handle}) when is_binary(handle) do
    case Algora.Accounts.get_user_by_handle(handle) do
      nil -> {:error, :contributor_not_found}
      user -> {:ok, user}
    end
  end

  defp resolve_contributor(%{"contributor_id" => id}) when is_binary(id) do
    case Algora.Accounts.get_user(id) do
      nil -> {:error, :contributor_not_found}
      user -> {:ok, user}
    end
  end

  defp resolve_contributor(_), do: {:error, :contributor_required}

  defp parse_amount(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {value, _} -> Money.new(round(value * 100), :USD)
      :error -> nil
    end
  end

  defp parse_amount(%Money{} = amount), do: amount

  defp parse_amount(_), do: nil

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end))
    end)
  end
end
