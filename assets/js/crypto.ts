/**
 * Algora Crypto - Solana Wallet Integration
 *
 * Provides LiveView hooks for:
 * - Connecting/disconnecting Solana wallets (Phantom, Solflare, etc.)
 * - Creating on-chain escrow transactions
 * - Releasing and refunding escrows
 *
 * This module is non-custodial: private keys never leave the user's wallet.
 * All transaction signing happens client-side via the wallet adapter.
 */

// ============================================================
// Types
// ============================================================

interface SolanaWallet {
  isPhantom?: boolean;
  isSolflare?: boolean;
  isConnected: boolean;
  publicKey: { toString(): string };
  connect(): Promise<{ publicKey: { toString(): string } }>;
  disconnect(): Promise<void>;
  signTransaction(tx: any): Promise<any>;
  signAllTransactions(txs: any[]): Promise<any[]>;
}

interface WindowWithSolana extends Window {
  solana?: SolanaWallet;
  phantom?: { solana?: SolanaWallet };
  solflare?: { isSolflare?: boolean } & SolanaWallet;
}

declare const window: WindowWithSolana;

// ============================================================
// Wallet Detection & Connection
// ============================================================

function detectWallet(): SolanaWallet | null {
  // Priority: Phantom > Solflare > Generic solana
  if (window.phantom?.solana?.isPhantom) {
    return window.phantom.solana;
  }
  if (window.solflare?.isSolflare) {
    return window.solflare as SolanaWallet;
  }
  if (window.solana) {
    return window.solana;
  }
  return null;
}

function getWalletName(wallet: SolanaWallet): string {
  if (wallet.isPhantom) return "Phantom";
  if (wallet.isSolflare) return "Solflare";
  return "Unknown";
}

// ============================================================
// API Helpers
// ============================================================

async function apiCall(method: string, path: string, body?: any): Promise<any> {
  const opts: RequestInit = {
    method,
    headers: { "Content-Type": "application/json" },
    credentials: "same-origin",
  };
  if (body) {
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(`/api/crypto${path}`, opts);
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error || `API error: ${res.status}`);
  }
  return data;
}

// ============================================================
// LiveView Hooks
// ============================================================

export const CryptoWalletHook = {
  mounted() {
    this.wallet = detectWallet();

    // Listen for wallet events
    if (this.wallet) {
      this.wallet.on?.("disconnect", () => {
        this.pushEvent("crypto_wallet_disconnected", {});
      });

      this.wallet.on?.("accountChanged", (publicKey: any) => {
        if (publicKey) {
          this.pushEvent("crypto_wallet_changed", {
            address: publicKey.toString(),
          });
        } else {
          this.pushEvent("crypto_wallet_disconnected", {});
        }
      });
    }

    // Handle events from LiveView
    this.handleEvent("crypto_connect_wallet", () => this.connectWallet());
    this.handleEvent("crypto_disconnect_wallet", () => this.disconnectWallet());
    this.handleEvent("crypto_check_wallet", () => this.checkWalletStatus());
  },

  async connectWallet() {
    const wallet = detectWallet();
    if (!wallet) {
      this.pushEvent("crypto_wallet_error", {
        error: "no_wallet_found",
        message:
          "No Solana wallet detected. Please install Phantom or Solflare.",
      });
      return;
    }

    try {
      const response = await wallet.connect();
      const address = response.publicKey.toString();
      const walletName = getWalletName(wallet);

      // Link wallet to user account on backend
      const result = await apiCall("POST", "/wallets", {
        address,
        network: "solana",
        label: walletName,
      });

      this.pushEvent("crypto_wallet_connected", {
        address,
        wallet_id: result.id,
        wallet_name: walletName,
      });
    } catch (error: any) {
      if (error.code === 4001) {
        // User rejected the connection
        this.pushEvent("crypto_wallet_error", {
          error: "connection_rejected",
          message: "Wallet connection was rejected by user.",
        });
      } else {
        this.pushEvent("crypto_wallet_error", {
          error: "connection_failed",
          message: error.message || "Failed to connect wallet.",
        });
      }
    }
  },

  async disconnectWallet() {
    const wallet = detectWallet();
    if (wallet?.isConnected) {
      try {
        await wallet.disconnect();
        this.pushEvent("crypto_wallet_disconnected", {});
      } catch {
        // Wallet disconnect failed, but we can still update UI
        this.pushEvent("crypto_wallet_disconnected", {});
      }
    }
  },

  checkWalletStatus() {
    const wallet = detectWallet();
    if (wallet?.isConnected && wallet.publicKey) {
      this.pushEvent("crypto_wallet_status", {
        connected: true,
        address: wallet.publicKey.toString(),
        wallet_name: getWalletName(wallet),
      });
    } else {
      this.pushEvent("crypto_wallet_status", {
        connected: false,
      });
    }
  },
};

export const CryptoEscrowHook = {
  mounted() {
    this.handleEvent(
      "crypto_create_escrow",
      (params: any) => this.createEscrow(params),
    );
    this.handleEvent(
      "crypto_release_escrow",
      (params: any) => this.releaseEscrow(params),
    );
    this.handleEvent(
      "crypto_refund_escrow",
      (params: any) => this.refundEscrow(params),
    );
  },

  async createEscrow(params: {
    contributor_handle: string;
    amount: string;
    bounty_id?: string;
    tip_id?: string;
    claim_id?: string;
  }) {
    try {
      // Step 1: Get escrow parameters from backend
      const escrowParams = await apiCall("GET", "/escrow-params", null);

      // Step 2: Build the on-chain transaction
      // This requires the Solana web3.js library loaded
      const { buildCreateEscrowTx } = await import("./solana_escrow");
      const { transaction, escrowAccountAddress, escrowTokenAccountAddress } =
        await buildCreateEscrowTx(escrowParams);

      // Step 3: Sign and send via wallet adapter
      const wallet = detectWallet();
      if (!wallet?.isConnected) {
        throw new Error("Wallet not connected");
      }

      const signedTx = await wallet.signTransaction(transaction);
      const signature = await connection(escrowParams.network).sendRawTransaction(
        signedTx.serialize(),
      );

      // Step 4: Confirm with backend
      await apiCall("POST", "/escrow/confirm", {
        escrow_id: escrowParams.escrow_id,
        signature,
        escrow_account_address: escrowAccountAddress,
        escrow_token_account_address: escrowTokenAccountAddress,
      });

      this.pushEvent("crypto_escrow_created", {
        escrow_id: escrowParams.escrow_id,
        signature,
      });
    } catch (error: any) {
      this.pushEvent("crypto_escrow_error", {
        action: "create",
        error: error.message || "Failed to create escrow",
      });
    }
  },

  async releaseEscrow(params: { escrow_id: string }) {
    try {
      const wallet = detectWallet();
      if (!wallet?.isConnected) {
        throw new Error("Wallet not connected");
      }

      // Get escrow details
      const escrow = await apiCall("GET", `/escrow/${params.escrow_id}`);

      // Build release transaction
      const { buildReleaseEscrowTx } = await import("./solana_escrow");
      const transaction = await buildReleaseEscrowTx(escrow);

      // Sign and send
      const signedTx = await wallet.signTransaction(transaction);
      const signature = await connection(escrow.network).sendRawTransaction(
        signedTx.serialize(),
      );

      // Confirm with backend
      await apiCall("POST", `/escrow/${params.escrow_id}/release`, {
        signature,
      });

      this.pushEvent("crypto_escrow_released", {
        escrow_id: params.escrow_id,
        signature,
      });
    } catch (error: any) {
      this.pushEvent("crypto_escrow_error", {
        action: "release",
        error: error.message || "Failed to release escrow",
      });
    }
  },

  async refundEscrow(params: { escrow_id: string }) {
    try {
      const wallet = detectWallet();
      if (!wallet?.isConnected) {
        throw new Error("Wallet not connected");
      }

      const escrow = await apiCall("GET", `/escrow/${params.escrow_id}`);

      const { buildRefundEscrowTx } = await import("./solana_escrow");
      const transaction = await buildRefundEscrowTx(escrow);

      const signedTx = await wallet.signTransaction(transaction);
      const signature = await connection(escrow.network).sendRawTransaction(
        signedTx.serialize(),
      );

      await apiCall("POST", `/escrow/${params.escrow_id}/refund`, {
        signature,
      });

      this.pushEvent("crypto_escrow_refunded", {
        escrow_id: params.escrow_id,
        signature,
      });
    } catch (error: any) {
      this.pushEvent("crypto_escrow_error", {
        action: "refund",
        error: error.message || "Failed to refund escrow",
      });
    }
  },
};

// ============================================================
// Helpers
// ============================================================

function connection(network: string) {
  // Returns a Solana RPC connection
  // This would use @solana/web3.js Connection
  const rpcUrl =
    network === "solana"
      ? document
          .querySelector("meta[name='solana-rpc-url']")
          ?.getAttribute("content") ||
        "https://api.devnet.solana.com"
      : "https://api.devnet.solana.com";

  // Placeholder — actual Connection would come from @solana/web3.js
  return {
    sendRawTransaction: async (serialized: Buffer) => {
      const response = await fetch(rpcUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "sendTransaction",
          params: [
            btoa(String.fromCharCode.apply(null, serialized as any)),
            { encoding: "base64" },
          ],
        }),
      });
      const result = await response.json();
      if (result.error) throw new Error(result.error.message);
      return result.result;
    },
  };
}

export default { CryptoWalletHook, CryptoEscrowHook };
