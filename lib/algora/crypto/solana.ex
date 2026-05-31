defmodule Algora.Crypto.Solana do
  @moduledoc """
  Solana RPC client for on-chain verification and transaction monitoring.

  Provides functions to:
  - Validate wallet addresses
  - Confirm transactions
  - Fetch escrow account state
  - Subscribe to on-chain events (via polling)
  - Verify escrow creation/release/refund events

  All RPC calls go through the configured Solana RPC endpoint.
  """

  require Logger

  @default_commitment "confirmed"
  @usdc_mint "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
  @escrow_program_id "Escrow11111111111111111111111111111111111111"

  # ============================================================
  # Configuration
  # ============================================================

  @doc """
  Returns the configured Solana RPC URL.
  """
  def rpc_url do
    Application.get_env(:algora, :solana_rpc_url, "https://api.mainnet-beta.solana.com")
  end

  @doc """
  Returns the configured Solana WebSocket URL for subscriptions.
  """
  def ws_url do
    Application.get_env(:algora, :solana_ws_url, "wss://api.mainnet-beta.solana.com")
  end

  @doc """
  Returns the escrow program ID.
  """
  def escrow_program_id do
    Application.get_env(:algora, :solana_escrow_program_id, @escrow_program_id)
  end

  @doc """
  Returns the USDC mint address.
  """
  def usdc_mint, do: @usdc_mint

  # ============================================================
  # Address Validation
  # ============================================================

  @doc """
  Validates that a Solana address is well-formed and exists on-chain.

  Returns `:ok` if valid, `{:error, reason}` otherwise.
  """
  @spec validate_address(String.t()) :: :ok | {:error, atom()}
  def validate_address(address) when is_binary(address) do
    cond do
      not valid_base58?(address) ->
        {:error, :invalid_base58}

      byte_size(address) not in 32..44 ->
        {:error, :invalid_length}

      true ->
        # Verify the account exists on-chain
        case get_account_info(address) do
          {:ok, _} -> :ok
          {:error, :not_found} -> {:error, :account_not_found}
          {:error, _} = error -> error
        end
    end
  end

  def validate_address(_), do: {:error, :invalid_address}

  defp valid_base58?(string) do
    String.match?(string, ~r/^[1-9A-HJ-NP-Za-km-z]+$/)
  end

  # ============================================================
  # RPC Methods
  # ============================================================

  @doc """
  Gets account info for a given Solana address.
  Returns the full account data including owner, lamports, and data.
  """
  @spec get_account_info(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_account_info(address) do
    case rpc_call("getAccountInfo", [address, %{encoding: "jsonParsed", commitment: @default_commitment}]) do
      {:ok, %{"result" => %{"value" => nil}}} ->
        {:error, :not_found}

      {:ok, %{"result" => %{"value" => account}}} ->
        {:ok, account}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets the balance of a Solana account in lamports.
  """
  @spec get_balance(String.t()) :: {:ok, non_neg_integer()} | {:error, atom()}
  def get_balance(address) do
    case rpc_call("getBalance", [address, %{commitment: @default_commitment}]) do
      {:ok, %{"result" => %{"value" => balance}}} ->
        {:ok, balance}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets the SPL token balance for a given token account.
  Returns the amount in the token's smallest unit.
  """
  @spec get_token_balance(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def get_token_balance(token_account_address) do
    case rpc_call("getTokenAccountsByOwner", [
           token_account_address,
           %{mint: @usdc_mint},
           %{encoding: "jsonParsed"}
         ]) do
      {:ok, %{"result" => %{"value" => [%{"account" => %{"data" => %{"parsed" => %{"info" => %{"tokenAmount" => %{"amount" => amount}}}}}}}]}} ->
        {:ok, amount}

      {:ok, %{"result" => %{"value" => []}}} ->
        {:ok, "0"}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Confirms a transaction by its signature.

  Returns `{:ok, confirmation}` with the full confirmation details,
  or `{:error, reason}` if the transaction failed or is not found.
  """
  @spec confirm_transaction(String.t()) :: {:ok, map()} | {:error, atom()}
  def confirm_transaction(signature) do
    case rpc_call("getSignatureStatuses", [[signature], %{searchTransactionHistory: true}]) do
      {:ok, %{"result" => %{"value" => [nil]}}} ->
        {:error, :transaction_not_found}

      {:ok, %{"result" => %{"value" => [%{"confirmationStatus" => status, "err" => err}]}}} ->
        case err do
          nil when status in ["confirmed", "finalized"] ->
            {:ok, %{status: status}}

          %{"InstructionError" => _} = error ->
            Logger.error("Transaction #{signature} failed: #{inspect(error)}")
            {:error, :transaction_failed}

          error ->
            Logger.error("Transaction #{signature} error: #{inspect(error)}")
            {:error, :transaction_failed}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets transaction details by signature.
  Returns full transaction data including logs and parsed instructions.
  """
  @spec get_transaction(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_transaction(signature) do
    case rpc_call("getTransaction", [signature, %{encoding: "jsonParsed", commitment: @default_commitment}]) do
      {:ok, %{"result" => nil}} ->
        {:error, :transaction_not_found}

      {:ok, %{"result" => transaction}} ->
        {:ok, transaction}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets the latest blockhash for transaction construction.
  """
  @spec get_latest_blockhash() :: {:ok, String.t()} | {:error, atom()}
  def get_latest_blockhash do
    case rpc_call("getLatestBlockhash", [%{commitment: @default_commitment}]) do
      {:ok, %{"result" => %{"value" => %{"blockhash" => blockhash}}}} ->
        {:ok, blockhash}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets the minimum rent exemption balance for a given data length.
  """
  @spec get_minimum_balance_for_rent_exemption(non_neg_integer()) :: {:ok, non_neg_integer()} | {:error, atom()}
  def get_minimum_balance_for_rent_exemption(data_length) do
    case rpc_call("getMinimumBalanceForRentExemption", [data_length]) do
      {:ok, %{"result" => balance}} ->
        {:ok, balance}

      {:error, _} = error ->
        error
    end
  end

  # ============================================================
  # Event Verification
  # ============================================================

  @doc """
  Verifies that an escrow was created on-chain by checking
  the transaction logs for the EscrowCreated event.

  Returns the parsed event data or an error.
  """
  @spec verify_escrow_created(String.t()) ::
          {:ok, %{escrow_id: String.t(), amount: integer(), escrow_account: String.t()}} | {:error, atom()}
  def verify_escrow_created(signature) do
    with {:ok, tx} <- get_transaction(signature),
         true <- is_escrow_program_transaction?(tx),
         false <- {:error, :not_escrow_program},
         {:ok, event_data} <- parse_escrow_created_event(tx) do
      {:ok, event_data}
    else
      {:error, _} = error -> error
      false -> {:error, :not_escrow_program}
    end
  end

  @doc """
  Verifies that an escrow was released on-chain.
  """
  @spec verify_escrow_released(String.t()) ::
          {:ok, %{escrow_id: String.t(), contributor_amount: integer(), platform_fee: integer()}} | {:error, atom()}
  def verify_escrow_released(signature) do
    with {:ok, tx} <- get_transaction(signature),
         true <- is_escrow_program_transaction?(tx),
         false <- {:error, :not_escrow_program},
         {:ok, event_data} <- parse_escrow_released_event(tx) do
      {:ok, event_data}
    else
      {:error, _} = error -> error
      false -> {:error, :not_escrow_program}
    end
  end

  @doc """
  Verifies that an escrow was refunded on-chain.
  """
  @spec verify_escrow_refunded(String.t()) ::
          {:ok, %{escrow_id: String.t(), refund_amount: integer()}} | {:error, atom()}
  def verify_escrow_refunded(signature) do
    with {:ok, tx} <- get_transaction(signature),
         true <- is_escrow_program_transaction?(tx),
         false <- {:error, :not_escrow_program},
         {:ok, event_data} <- parse_escrow_refunded_event(tx) do
      {:ok, event_data}
    else
      {:error, _} = error -> error
      false -> {:error, :not_escrow_program}
    end
  end

  # ============================================================
  # RPC Infrastructure
  # ============================================================

  defp rpc_call(method, params) do
    payload = %{
      jsonrpc: "2.0",
      id: System.unique_integer([:positive]),
      method: method,
      params: params
    }

    case Finch.build(:post, rpc_url(), [{"content-type", "application/json"}], Jason.encode!(payload))
         |> Finch.request(Algora.Finch, receive_timeout: 30_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => %{"message" => message}}} ->
            Logger.error("Solana RPC error (#{method}): #{message}")
            {:error, :rpc_error}

          {:ok, result} ->
            {:ok, result}
        end

      {:ok, %Finch.Response{status: status, body: body}} ->
        Logger.error("Solana RPC HTTP #{status}: #{body}")
        {:error, :http_error}

      {:error, error} ->
        Logger.error("Solana RPC request failed: #{inspect(error)}")
        {:error, :request_failed}
    end
  end

  # ============================================================
  # Event Parsing
  # ============================================================

  defp is_escrow_program_transaction?(%{"transaction" => %{"message" => %{"accountKeys" => keys}}}) do
    program_id = escrow_program_id()
    Enum.any?(keys, fn
      %{"pubkey" => ^program_id} -> true
      ^program_id -> true
      _ -> false
    end)
  end

  defp is_escrow_program_transaction?(_), do: false

  defp parse_escrow_created_event(%{"meta" => %{"logMessages" => logs}}) when is_list(logs) do
    case Enum.find(logs, &String.contains?(&1, "EscrowCreated")) do
      nil ->
        {:error, :event_not_found}

      log_line ->
        # Parse: "Event: EscrowCreated { escrow_id: ..., amount: ..., ... }"
        with {:ok, escrow_id} <- extract_event_field(log_line, "escrow_id"),
             {:ok, amount_str} <- extract_event_field(log_line, "amount"),
             {amount, ""} <- Integer.parse(amount_str) do
          {:ok, %{escrow_id: escrow_id, amount: amount}}
        else
          _ -> {:error, :event_parse_error}
        end
    end
  end

  defp parse_escrow_created_event(_), do: {:error, :no_logs}

  defp parse_escrow_released_event(%{"meta" => %{"logMessages" => logs}}) when is_list(logs) do
    case Enum.find(logs, &String.contains?(&1, "EscrowReleased")) do
      nil ->
        {:error, :event_not_found}

      log_line ->
        with {:ok, escrow_id} <- extract_event_field(log_line, "escrow_id"),
             {:ok, contributor_amount_str} <- extract_event_field(log_line, "contributor_amount"),
             {contributor_amount, ""} <- Integer.parse(contributor_amount_str),
             {:ok, platform_fee_str} <- extract_event_field(log_line, "platform_fee"),
             {platform_fee, ""} <- Integer.parse(platform_fee_str) do
          {:ok, %{escrow_id: escrow_id, contributor_amount: contributor_amount, platform_fee: platform_fee}}
        else
          _ -> {:error, :event_parse_error}
        end
    end
  end

  defp parse_escrow_released_event(_), do: {:error, :no_logs}

  defp parse_escrow_refunded_event(%{"meta" => %{"logMessages" => logs}}) when is_list(logs) do
    case Enum.find(logs, &String.contains?(&1, "EscrowRefunded")) do
      nil ->
        {:error, :event_not_found}

      log_line ->
        with {:ok, escrow_id} <- extract_event_field(log_line, "escrow_id"),
             {:ok, refund_amount_str} <- extract_event_field(log_line, "refund_amount"),
             {refund_amount, ""} <- Integer.parse(refund_amount_str) do
          {:ok, %{escrow_id: escrow_id, refund_amount: refund_amount}}
        else
          _ -> {:error, :event_parse_error}
        end
    end
  end

  defp parse_escrow_refunded_event(_), do: {:error, :no_logs}

  defp extract_event_field(log_line, field_name) do
    # Match patterns like: field_name: value  or  field_name: "value"
    case Regex.run(~r/#{field_name}:\s*"?([^,}"]+)"?/, log_line) do
      [_, value] -> {:ok, String.trim(value)}
      _ -> {:error, :field_not_found}
    end
  end
end
