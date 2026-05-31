defmodule Algora.Crypto do
  @moduledoc """
  Context module for crypto payment operations.

  Handles the lifecycle of non-custodial crypto payments using
  Solana USDC with on-chain escrow. The platform never holds
  private keys — all signing happens client-side via wallet adapters.

  ## Architecture

  - **Wallets**: Users link their existing Solana wallets (Phantom, Solflare)
  - **Escrow**: Funds are held in on-chain PDAs until released/refunded
  - **Verification**: On-chain events are verified via Solana RPC
  - **Fees**: 5% platform fee + gas on payer (< $0.01 on Solana)

  ## Flow

  1. Payer creates escrow on-chain → USDC locked in PDA
  2. On `EscrowCreated` event → backend records escrow + updates transaction
  3. Contributor completes work → payer releases escrow on-chain
  4. On `EscrowReleased` event → backend updates escrow + transaction status
  5. If deadline passes → payer can refund on-chain
  """
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Crypto.CryptoEscrow
  alias Algora.Crypto.CryptoWallet
  alias Algora.Crypto.Solana
  alias Algora.MoneyUtils
  alias Algora.Repo

  require Logger

  # ============================================================
  # Wallet Management
  # ============================================================

  @doc """
  Links a Solana wallet address to a user account.

  The wallet address is validated against the Solana base58 format.
  A user can link multiple wallets but each address can only be linked once.
  """
  @spec link_wallet(User.t(), %{address: String.t(), network: :solana, label: String.t() | nil}) ::
          {:ok, CryptoWallet.t()} | {:error, Ecto.Changeset.t()}
  def link_wallet(%User{} = user, %{address: address, network: network} = attrs) do
    # Verify the address is valid on-chain before linking
    with :ok <- Solana.validate_address(address) do
      %CryptoWallet{}
      |> CryptoWallet.changeset(
        Map.merge(attrs, %{
          user_id: user.id,
          status: :active
        })
      )
      |> Repo.insert()
    end
  end

  @doc """
  Unlinks a wallet from a user account by setting status to inactive.
  Does not delete the record to maintain audit trail.
  """
  @spec unlink_wallet(String.t()) :: {:ok, CryptoWallet.t()} | {:error, Ecto.Changeset.t()}
  def unlink_wallet(wallet_id) do
    with {:ok, wallet} <- Repo.fetch(CryptoWallet, wallet_id) do
      wallet
      |> CryptoWallet.update_changeset(%{status: :inactive})
      |> Repo.update()
    end
  end

  @doc """
  Gets the active Solana wallet for a user.
  Returns the first active wallet found, or nil.
  """
  @spec get_active_wallet(User.t(), :solana) :: CryptoWallet.t() | nil
  def get_active_wallet(%User{} = user, network \\ :solana) do
    Repo.one(
      from w in CryptoWallet,
        where: w.user_id == ^user.id,
        where: w.network == ^network,
        where: w.status == :active,
        order_by: [desc: w.inserted_at],
        limit: 1
    )
  end

  @doc """
  Lists all wallets for a user, optionally filtered by network and status.
  """
  @spec list_wallets(User.t(), keyword()) :: [CryptoWallet.t()]
  def list_wallets(%User{} = user, opts \\ []) do
    query =
      from w in CryptoWallet,
        where: w.user_id == ^user.id,
        order_by: [desc: w.inserted_at]

    query =
      if network = opts[:network] do
        from w in query, where: w.network == ^network
      else
        query
      end

    query =
      if status = opts[:status] do
        from w in query, where: w.status == ^status
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a wallet by its on-chain address and network.
  Used for resolving contributors when processing on-chain events.
  """
  @spec get_wallet_by_address(String.t(), :solana) :: CryptoWallet.t() | nil
  def get_wallet_by_address(address, network \\ :solana) do
    Repo.get_by(CryptoWallet, address: address, network: network, status: :active)
  end

  # ============================================================
  # Escrow Management
  # ============================================================

  @doc """
  Records a newly created on-chain escrow.

  Called when the `EscrowCreated` event is detected on-chain.
  Creates the escrow record and links it to the relevant bounty/tip/claim.
  """
  @spec record_escrow_created(map()) ::
          {:ok, CryptoEscrow.t()} | {:error, Ecto.Changeset.t() | atom()}
  def record_escrow_created(attrs) do
    %CryptoEscrow{}
    |> CryptoEscrow.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a crypto escrow record and initializes associated transactions.

  This is called after the payer has confirmed the on-chain escrow creation.
  It records the escrow and creates the corresponding debit/credit transactions
  in the Algora payment system.
  """
  @spec create_crypto_escrow(map()) ::
          {:ok, {CryptoEscrow.t(), map()}} | {:error, atom() | Ecto.Changeset.t()}
  def create_crypto_escrow(%{
        payer: payer,
        contributor: contributor,
        amount: amount,
        bounty_id: bounty_id,
        tip_id: tip_id,
        claim_id: claim_id,
        escrow_account_address: escrow_account_address,
        escrow_token_account_address: escrow_token_account_address,
        create_transaction_signature: create_signature,
        deadline: deadline
      }) do
    payer_wallet = get_active_wallet(payer)
    contributor_wallet = get_active_wallet(contributor)
    platform_wallet = get_platform_wallet()

    cond do
      is_nil(payer_wallet) ->
        {:error, :payer_wallet_not_found}

      is_nil(contributor_wallet) ->
        {:error, :contributor_wallet_not_found}

      is_nil(platform_wallet) ->
        {:error, :platform_wallet_not_found}

      true ->
        group_id = Nanoid.generate()
        fee_bps = CryptoEscrow.default_platform_fee_bps()
        amount_lamports = MoneyUtils.to_minor_units(amount)

        Repo.tx(fn ->
          with {:ok, escrow} <-
                 record_escrow_created(%{
                   group_id: group_id,
                   payer_wallet_id: payer_wallet.id,
                   contributor_wallet_id: contributor_wallet.id,
                   platform_wallet_id: platform_wallet.id,
                   network: :solana,
                   mint_address: CryptoEscrow.default_mint_address(),
                   amount: amount_lamports,
                   platform_fee_bps: fee_bps,
                   deadline: deadline,
                   escrow_account_address: escrow_account_address,
                   escrow_token_account_address: escrow_token_account_address,
                   create_transaction_signature: create_signature,
                   bounty_id: bounty_id,
                   tip_id: tip_id,
                   claim_id: claim_id
                 }),
               {:ok, transactions} <-
                 create_crypto_transactions(%{
                   escrow: escrow,
                   payer: payer,
                   contributor: contributor,
                   amount: amount,
                   group_id: group_id
                 }) do
            {:ok, {escrow, transactions}}
          end
        end)
    end
  end

  @doc """
  Processes an escrow release event detected on-chain.

  Called when the `EscrowReleased` event is verified.
  Updates the escrow state and marks all associated transactions as succeeded.
  """
  @spec process_escrow_release(String.t(), String.t()) ::
          {:ok, CryptoEscrow.t()} | {:error, atom()}
  def process_escrow_release(escrow_id, release_signature) do
    with {:ok, escrow} <- Repo.fetch(CryptoEscrow, escrow_id),
         :created <- escrow.state || {:error, :escrow_not_in_created_state},
         {:ok, escrow} <-
           escrow
           |> CryptoEscrow.release_changeset(%{release_transaction_signature: release_signature})
           |> Repo.update() do
      # Update associated transactions to succeeded
      update_escrow_transactions(escrow, :succeeded)
      {:ok, escrow}
    else
      {:error, :escrow_not_in_created_state} -> {:error, :escrow_not_in_created_state}
      {:error, _} = error -> error
    end
  end

  @doc """
  Processes an escrow refund event detected on-chain.

  Called when the `EscrowRefunded` event is verified.
  Updates the escrow state and marks associated transactions as canceled.
  """
  @spec process_escrow_refund(String.t(), String.t()) ::
          {:ok, CryptoEscrow.t()} | {:error, atom()}
  def process_escrow_refund(escrow_id, refund_signature) do
    with {:ok, escrow} <- Repo.fetch(CryptoEscrow, escrow_id),
         :created <- escrow.state || {:error, :escrow_not_in_created_state},
         {:ok, escrow} <-
           escrow
           |> CryptoEscrow.refund_changeset(%{refund_transaction_signature: refund_signature})
           |> Repo.update() do
      update_escrow_transactions(escrow, :canceled)
      {:ok, escrow}
    else
      {:error, :escrow_not_in_created_state} -> {:error, :escrow_not_in_created_state}
      {:error, _} = error -> error
    end
  end

  @doc """
  Lists escrows matching the given criteria.
  """
  @spec list_escrows(keyword()) :: [CryptoEscrow.t()]
  def list_escrows(opts \\ []) do
    query = from e in CryptoEscrow, order_by: [desc: e.inserted_at]

    query =
      Enum.reduce(opts, query, fn
        {:state, state}, q -> from e in q, where: e.state == ^state
        {:payer_wallet_id, id}, q -> from e in q, where: e.payer_wallet_id == ^id
        {:contributor_wallet_id, id}, q -> from e in q, where: e.contributor_wallet_id == ^id
        {:bounty_id, id}, q -> from e in q, where: e.bounty_id == ^id
        {:limit, limit}, q -> from e in q, limit: ^limit
        _, q -> q
      end)

    Repo.all(query)
  end

  @doc """
  Gets an escrow by its group_id.
  """
  @spec get_escrow_by_group_id(String.t()) :: CryptoEscrow.t() | nil
  def get_escrow_by_group_id(group_id) do
    Repo.get_by(CryptoEscrow, group_id: group_id)
  end

  @doc """
  Checks if a user has a wallet that can receive crypto payments.
  """
  @spec has_crypto_wallet?(User.t()) :: boolean()
  def has_crypto_wallet?(%User{} = user) do
    get_active_wallet(user) != nil
  end

  @doc """
  Returns the crypto platform fee percentage as a Decimal.
  5% = 500 bps = 0.05
  """
  @spec get_crypto_platform_fee_pct() :: Decimal.t()
  def get_crypto_platform_fee_pct do
    Decimal.div(Decimal.new(CryptoEscrow.default_platform_fee_bps()), 10_000)
  end

  @doc """
  Returns the crypto transaction fee percentage (0% — gas paid by payer).
  """
  @spec get_crypto_transaction_fee_pct() :: Decimal.t()
  def get_crypto_transaction_fee_pct, do: Decimal.new(0)

  # ============================================================
  # Escrow Transaction Data
  # ============================================================

  @doc """
  Builds the transaction data needed by the frontend to create
  an on-chain escrow via the Solana Wallet Adapter.

  Returns the parameters that the client needs to sign and send
  the `create_escrow` instruction.
  """
  @spec build_escrow_transaction_data(map()) :: map()
  def build_escrow_transaction_data(%{
        payer: payer,
        contributor: contributor,
        amount: amount
      }) do
    payer_wallet = get_active_wallet(payer)
    contributor_wallet = get_active_wallet(contributor)
    platform_wallet = get_platform_wallet()
    escrow_id = Nanoid.generate()

    %{
      escrow_id: escrow_id,
      payer_address: payer_wallet && payer_wallet.address,
      contributor_address: contributor_wallet && contributor_wallet.address,
      platform_address: platform_wallet && platform_wallet.address,
      mint_address: CryptoEscrow.default_mint_address(),
      amount: MoneyUtils.to_minor_units(amount),
      platform_fee_bps: CryptoEscrow.default_platform_fee_bps(),
      deadline: DateTime.add(DateTime.utc_now(), 30, :day) |> DateTime.to_unix(),
      network: :solana
    }
  end

  # ============================================================
  # Private Helpers
  # ============================================================

  defp create_crypto_transactions(%{
         escrow: escrow,
         payer: payer,
         contributor: contributor,
         amount: amount,
         group_id: group_id
       }) do
    fee_pct = get_crypto_platform_fee_pct()
    platform_fee = Money.mult!(amount, fee_pct)
    contributor_amount = Money.sub!(amount, platform_fee)

    debit_id = Nanoid.generate()
    credit_id = Nanoid.generate()

    with {:ok, charge} <-
           create_crypto_transaction(%{
             id: Nanoid.generate(),
             user_id: payer.id,
             type: :charge,
             gross_amount: amount,
             net_amount: contributor_amount,
             total_fee: platform_fee,
             group_id: group_id,
             provider: "crypto",
             provider_id: escrow.escrow_account_address,
             provider_meta: %{
               escrow_id: escrow.id,
               create_signature: escrow.create_transaction_signature,
               network: to_string(escrow.network),
               mint_address: escrow.mint_address
             }
           }),
         {:ok, debit} <-
           create_crypto_transaction(%{
             id: debit_id,
             user_id: payer.id,
             type: :debit,
             amount: contributor_amount,
             group_id: group_id,
             linked_transaction_id: credit_id,
             provider: "crypto",
             provider_id: escrow.escrow_account_address,
             provider_meta: %{escrow_id: escrow.id, network: to_string(escrow.network)}
           }),
         {:ok, credit} <-
           create_crypto_transaction(%{
             id: credit_id,
             user_id: contributor.id,
             type: :credit,
             amount: contributor_amount,
             group_id: group_id,
             linked_transaction_id: debit_id,
             provider: "crypto",
             provider_id: escrow.escrow_account_address,
             provider_meta: %{escrow_id: escrow.id, network: to_string(escrow.network)}
           }) do
      {:ok, %{charge: charge, debit: debit, credit: credit}}
    end
  end

  defp create_crypto_transaction(%{type: type} = attrs)
       when type in [:debit, :credit] do
    %Algora.Payments.Transaction{}
    |> change(%{
      id: attrs[:id],
      provider: attrs[:provider],
      provider_id: attrs[:provider_id],
      provider_meta: attrs[:provider_meta],
      type: attrs[:type],
      status: :processing,
      user_id: attrs[:user_id],
      gross_amount: attrs[:amount],
      net_amount: attrs[:amount],
      total_fee: Money.zero(:USD),
      group_id: attrs[:group_id],
      linked_transaction_id: attrs[:linked_transaction_id]
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp create_crypto_transaction(attrs) do
    %Algora.Payments.Transaction{}
    |> change(%{
      id: attrs[:id],
      provider: attrs[:provider],
      provider_id: attrs[:provider_id],
      provider_meta: attrs[:provider_meta],
      type: attrs[:type],
      status: :processing,
      user_id: attrs[:user_id],
      gross_amount: attrs[:gross_amount],
      net_amount: attrs[:net_amount],
      total_fee: attrs[:total_fee],
      group_id: attrs[:group_id]
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp update_escrow_transactions(escrow, status) do
    from(t in Algora.Payments.Transaction,
      where: t.group_id == ^escrow.group_id,
      where: t.provider == "crypto"
    )
    |> Repo.update_all(
      set: [
        status: status,
        succeeded_at: if(status == :succeeded, do: DateTime.utc_now())
      ]
    )
  end

  defp get_platform_wallet do
    # The platform wallet is configured via application env
    # This is the wallet that receives the 5% platform fee
    case Application.get_env(:algora, :crypto_platform_wallet_address) do
      nil ->
        Logger.warning("No crypto platform wallet address configured")
        nil

      address ->
        case get_wallet_by_address(address) do
          nil ->
            Logger.warning("Platform wallet address #{address} not found in DB. Please link it first.")
            nil
          wallet ->
            wallet
        end
    end
  end
end
