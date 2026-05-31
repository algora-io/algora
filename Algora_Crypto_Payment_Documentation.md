# Algora Crypto Payment System — Technical Documentation

> **Repository**: [algora-io/algora](https://github.com/algora-io/algora)
> **Date**: 2026-05-31
> **Commit**: `96de1097 feat: add Solana USDC crypto payment system with on-chain escrow`
> **Author**: Community Contributor

---

## Table of Contents

1. [Overview](#overview)
2. [Design Decisions](#design-decisions)
3. [Architecture](#architecture)
4. [Smart Contract (Solana Escrow)](#smart-contract-solana-escrow)
5. [Backend (Elixir/Phoenix)](#backend-elixirphoenix)
6. [Frontend (TypeScript/LiveView)](#frontend-typescriptliveview)
7. [Database Schema](#database-schema)
8. [API Reference](#api-reference)
9. [Configuration](#configuration)
10. [Security Model](#security-model)
11. [Fee Structure](#fee-structure)
12. [File Map](#file-map)
13. [Deployment Checklist](#deployment-checklist)
14. [MVP Scope & Limitations](#mvp-scope--limitations)

---

## Overview

This document describes the complete implementation of the crypto payment system added to the Algora bounty platform. The system enables bounty sponsors to pay contributors using **USDC on Solana** through a non-custodial, on-chain escrow mechanism. The platform never holds private keys — all transaction signing happens client-side via wallet adapters (Phantom, Solflare).

The implementation integrates into Algora's existing Payment Service Provider (PSP) architecture as a new `PaymentProvider "crypto"`, alongside the existing Stripe provider. This means the crypto payment flow reuses the same transaction schema, group IDs, and ledger logic already used for fiat payments.

### Key Properties

- **Non-custodial**: Private keys never leave the user's wallet; the server only records on-chain events
- **On-chain escrow**: USDC is locked in a Program Derived Address (PDA) until released or refunded
- **On-chain verification**: All escrow lifecycle events are verified via Solana RPC before updating the database
- **Extensible design**: Although MVP only supports USDC on Solana, the architecture supports adding other chains/tokens

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Token** | USDC only (MVP) | Most widely adopted stablecoin; eliminates price volatility for bounty amounts |
| **Chain** | Solana only (MVP) | Sub-cent gas fees (< $0.01), ~400ms finality, strong wallet ecosystem |
| **Wallet Model** | Non-custodial (Wallet Adapter) | No regulatory burden of holding keys; users retain full control |
| **Escrow Mechanism** | On-chain Smart Contract (PDA) | Trust-minimized; funds locked on-chain, not in a server-controlled wallet |
| **Verification** | On-chain via Solana RPC | Backend polls for transaction confirmation; events parsed from log messages |
| **Payout** | Direct to contributor wallet | No intermediate holding; on release, 95% goes to contributor, 5% to platform |
| **Platform Fee** | 5% (500 bps) | Matches existing Stripe fee; taken from escrow on release |
| **Gas** | Paid by payer | Solana gas is negligible (< $0.01); not deducted from bounty amount |
| **Security** | Nonce + Deadline + ReentrancyGuard + Events | Standard Solana/Anchor security patterns; PDA-based authority prevents unauthorized access |
| **PSP Integration** | `PaymentProvider "crypto"` | Fits into existing PSP architecture; same transaction/group_id schema as Stripe |

---

## Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Browser   │     │   Phoenix Server  │     │   Solana Chain   │
│             │     │                  │     │                  │
│  Phantom /  │────▶│  CryptoController│     │  Escrow Program  │
│  Solflare   │     │  PSP.Crypto      │     │  (PDA Accounts)  │
│  Wallet     │     │  Crypto context   │     │                  │
│             │     │  OnChainVerifier  │◀────│  EscrowCreated   │
│  crypto.ts  │     │  Solana RPC       │     │  EscrowReleased  │
│  solana_    │     │  VerifyEscrowJob  │     │  EscrowRefunded  │
│  escrow.ts  │     │                  │     │                  │
└─────────────┘     └──────────────────┘     └──────────────────┘
       │                    │                         ▲
       │                    │                         │
       │    1. Get escrow   │    3. Verify on-chain   │
       │       params       │       + record          │
       │───────────────────▶│                         │
       │                    │                         │
       │    2. Build + sign │                         │
       │    + send tx       │                         │
       │─────────────────────────────────────────────▶│
       │                    │                         │
       │    4. Submit sig   │                         │
       │───────────────────▶│                         │
       │                    │───poll for confirmation─▶│
       │                    │◀──confirmed/finalized───│
```

### Payment Flow

1. **Payer initiates**: Frontend calls `GET /api/crypto/escrow-params` to get escrow parameters (addresses, amounts, deadline)
2. **Build transaction**: Frontend constructs the `create_escrow` instruction using `solana_escrow.ts`
3. **Sign & send**: Wallet adapter signs the transaction; it's sent to the Solana RPC
4. **Confirm with backend**: Frontend submits the transaction signature to `POST /api/crypto/escrow/confirm`
5. **Backend verification**: `VerifyEscrowJob` polls Solana RPC for confirmation; parses `EscrowCreated` event from logs
6. **Record escrow**: On successful verification, backend creates escrow record + charge/debit/credit transactions
7. **Release**: When work is done, payer calls `POST /api/crypto/escrow/:id/release` after signing release transaction
8. **On-chain release**: Smart contract splits funds: 95% to contributor, 5% to platform wallet
9. **Refund**: If deadline passes, payer can call `POST /api/crypto/escrow/:id/refund`

---

## Smart Contract (Solana Escrow)

The escrow smart contract is built with the **Anchor framework** and located at `contracts/solana-escrow/`.

### Program Structure

```
contracts/solana-escrow/
├── programs/
│   └── solana-escrow/
│       └── src/
│           ├── lib.rs           # Program entry point + instruction dispatch
│           ├── state.rs         # EscrowAccount struct + EscrowState enum
│           ├── errors.rs        # Custom error codes
│           └── instructions/
│               ├── mod.rs       # Re-exports instruction modules
│               ├── create.rs    # create_escrow instruction
│               ├── release.rs   # release_escrow instruction
│               └── refund.rs    # refund_escrow instruction
├── tests/
│   └── escrow.ts               # Integration tests
├── migrations/
│   └── deploy.ts               # Deployment script
├── Anchor.toml                 # Anchor configuration
├── Cargo.toml                  # Rust workspace config
├── package.json                # npm dependencies for testing
└── tsconfig.json               # TypeScript config
```

### Instructions

#### `create_escrow`

Deposits USDC from the payer into an escrow PDA token account.

**Parameters:**
- `escrow_id: String` — Unique identifier matching Algora DB `group_id` (max 64 chars)
- `amount: u64` — USDC amount in smallest unit (micro-USDC, 6 decimals)
- `platform_fee_bps: u16` — Platform fee in basis points (500 = 5%)
- `deadline: i64` — Unix timestamp after which refund is allowed

**Accounts:**
- `escrow_account` (PDA: `[b"escrow", escrow_id.as_bytes()]`) — Initialized with escrow metadata
- `escrow_token_account` (PDA: `[b"escrow_token", escrow_id.as_bytes()]`) — Holds the escrowed USDC
- `payer_token_account` — Payer's USDC token account (source of deposit)
- `contributor` — Contributor's wallet address (stored for release)
- `platform_wallet` — Platform's wallet address (receives fee on release)
- `mint` — USDC mint address
- `payer` (Signer) — The payer creating the escrow

**Validations:**
- `amount > 0`
- `platform_fee_bps <= 10000`
- `deadline > current_timestamp`
- `escrow_id` non-empty and within length limit
- Payer has sufficient USDC balance

**Event emitted:** `EscrowCreated` with all escrow parameters

#### `release_escrow`

Releases escrowed funds to the contributor (minus platform fee).

**Parameters:**
- `escrow_id: String` — Escrow identifier

**Validations:**
- Only the original payer (escrow creator) can release
- Escrow must be in `Created` state
- Deadline must not have passed

**Transfer logic:**
- `contributor_amount = amount - (amount * platform_fee_bps / 10000)` → contributor token account
- `platform_fee = amount * platform_fee_bps / 10000` → platform token account

**Event emitted:** `EscrowReleased` with `escrow_id`, `contributor_amount`, `platform_fee`

#### `refund_escrow`

Refunds the full escrowed amount back to the payer.

**Parameters:**
- `escrow_id: String` — Escrow identifier

**Validations:**
- Only the original payer can request refund
- Escrow must be in `Created` state
- Deadline must have passed

**Event emitted:** `EscrowRefunded` with `escrow_id`, `refund_amount`

### EscrowAccount State

| Field | Type | Description |
|-------|------|-------------|
| `escrow_id` | `String` | Unique identifier (max 64 chars) |
| `payer` | `Pubkey` | Depositor wallet address |
| `contributor` | `Pubkey` | Recipient wallet address |
| `platform_wallet` | `Pubkey` | Platform fee recipient |
| `mint` | `Pubkey` | SPL token mint (USDC) |
| `amount` | `u64` | Total escrowed amount (micro-USDC) |
| `platform_fee_bps` | `u16` | Platform fee in basis points |
| `deadline` | `i64` | Unix timestamp for refund eligibility |
| `nonce` | `u64` | Replay protection counter |
| `state` | `EscrowState` | `Created`, `Released`, or `Refunded` |
| `created_at` | `i64` | Creation timestamp |
| `bump` | `u8` | PDA bump seed |
| `token_bump` | `u8` | Token PDA bump seed |

### Error Codes

| Error | Description |
|-------|-------------|
| `EscrowNotFound` | Escrow account does not exist |
| `EscrowAlreadyExists` | Duplicate escrow ID |
| `Unauthorized` | Caller is not the escrow creator |
| `EscrowExpired` | Deadline has passed |
| `EscrowNotExpired` | Deadline not yet passed (for refunds) |
| `EscrowAlreadyReleased` | Escrow already in Released state |
| `EscrowAlreadyRefunded` | Escrow already in Refunded state |
| `InvalidAmount` | Amount must be > 0 |
| `DeadlinePassed` | Deadline is in the past |
| `DeadlineNotPassed` | Refund not yet available |
| `InvalidPlatformFeeBps` | Fee exceeds 10000 bps (100%) |
| `InvalidEscrowId` | ID is empty or exceeds 64 chars |
| `InsufficientBalance` | Payer lacks USDC balance |
| `MathOverflow` | Overflow in fee calculation |

---

## Backend (Elixir/Phoenix)

### Module Architecture

```
lib/algora/
├── crypto/
│   ├── crypto.ex                 # Public API context (wallet & escrow management)
│   ├── solana.ex                 # Solana RPC client (HTTP via Finch)
│   ├── on_chain_verifier.ex      # Polling-based on-chain event verification
│   ├── jobs/
│   │   └── verify_escrow.ex      # Oban job for async escrow verification
│   └── schemas/
│       ├── crypto_wallet.ex      # Wallet schema + changesets
│       └── crypto_escrow.ex      # Escrow schema + changesets + fee calculations
├── psp/
│   └── crypto/
│       └── crypto.ex             # Payment Service Provider interface (matches Stripe PSP)
└── algora_web/
    ├── controllers/
    │   └── crypto_controller.ex  # REST API endpoints for crypto operations
    └── router.ex                 # Route definitions (/api/crypto/*)
```

### `Algora.Crypto` (Context Module)

The main context module providing the public API for crypto payment operations.

**Wallet Operations:**
- `link_wallet/2` — Links a Solana wallet to a user (validates address on-chain first)
- `unlink_wallet/1` — Soft-deletes a wallet (sets status to `:inactive` for audit trail)
- `get_active_wallet/2` — Gets the user's active Solana wallet
- `list_wallets/2` — Lists all wallets with optional network/status filters
- `get_wallet_by_address/2` — Resolves a user by their on-chain address
- `has_crypto_wallet?/1` — Checks if a user can receive crypto payments

**Escrow Operations:**
- `record_escrow_created/1` — Records a new on-chain escrow event
- `create_crypto_escrow/1` — Full escrow creation with transaction group (charge + debit + credit)
- `process_escrow_release/2` — Updates escrow state on release confirmation
- `process_escrow_refund/2` — Updates escrow state on refund confirmation
- `build_escrow_transaction_data/1` — Builds params for frontend transaction construction

**Transaction Helpers:**
- `create_crypto_transactions/1` — Creates the charge/debit/credit transaction trio
- `update_escrow_transactions/2` — Updates all transactions in a group to `:succeeded` or `:canceled`

### `Algora.Crypto.Solana` (RPC Client)

HTTP client for Solana JSON-RPC, using Finch for connection pooling.

**Configuration:**
- `rpc_url/0` — Returns configured Solana RPC URL
- `ws_url/0` — Returns configured Solana WebSocket URL
- `escrow_program_id/0` — Returns escrow program ID
- `usdc_mint/0` — Returns USDC mint address (`EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`)

**Address Validation:**
- `validate_address/1` — Validates Solana address format (base58, 32-44 chars) and checks on-chain existence

**RPC Methods:**
- `get_account_info/1` — Fetches account data
- `get_balance/1` — Gets SOL balance in lamports
- `get_token_balance/1` — Gets USDC balance for a token account
- `confirm_transaction/1` — Checks transaction confirmation status
- `get_transaction/1` — Fetches full transaction details
- `get_latest_blockhash/0` — Gets recent blockhash for tx construction
- `get_minimum_balance_for_rent_exemption/1` — Gets rent exemption minimum

**Event Verification:**
- `verify_escrow_created/1` — Parses `EscrowCreated` event from transaction logs
- `verify_escrow_released/1` — Parses `EscrowReleased` event from transaction logs
- `verify_escrow_refunded/1` — Parses `EscrowRefunded` event from transaction logs

All RPC calls use a 30-second timeout and parse the JSON-RPC response, returning `{:ok, result}` or `{:error, reason}`.

### `Algora.Crypto.OnChainVerifier` (Verification Service)

Polls the Solana blockchain to confirm escrow lifecycle events before updating the database.

**Configuration:**
- Max retries: 10
- Poll interval: 3 seconds
- Total max wait: ~30 seconds

**Methods:**
- `verify_creation/2` — Polls for escrow creation confirmation, then verifies and records
- `verify_release/2` — Polls for release confirmation, then processes release
- `verify_refund/2` — Polls for refund confirmation, then processes refund

On failed transactions, the escrow is marked as `:failed` and associated transactions are set to `:failed` status.

### `Algora.Crypto.Jobs.VerifyEscrow` (Oban Worker)

Async job for verifying pending escrow transactions. Enqueued after signature submission.

**Configuration:**
- Queue: `:crypto`
- Max attempts: 10
- Unique: forever (prevents duplicate verification)

**Actions:**
- `"create"` → `OnChainVerifier.verify_creation/2`
- `"release"` → `OnChainVerifier.verify_release/2`
- `"refund"` → `OnChainVerifier.verify_refund/2`

### `Algora.PSP.Crypto` (Payment Service Provider)

Implements the same PSP interface as `Algora.PSP.Stripe` but for crypto payments. This is the integration point with Algora's existing payment system.

**Methods:**
- `create_session/1` — Returns escrow parameters (unlike Stripe which returns a checkout URL)
- `verify_and_record_escrow/1` — Verifies on-chain tx and enqueues verification job
- `process_release/2` — Processes a release signature
- `process_refund/2` — Processes a refund signature
- `payouts_enabled?/1` — Checks if user has an active crypto wallet
- `fee_structure/0` — Returns `{platform_fee_bps: 500, transaction_fee_pct: 0}`

---

## Frontend (TypeScript/LiveView)

### `assets/js/crypto.ts` — Wallet & Escrow Hooks

Provides Phoenix LiveView hooks for browser-side crypto operations.

**`CryptoWalletHook`** — Manages wallet connection lifecycle:
- Detects installed wallets (Phantom > Solflare > Generic)
- Handles connect/disconnect via wallet adapter
- Links wallet address to user account via `POST /api/crypto/wallets`
- Listens for wallet events (disconnect, account change)
- Pushes events back to LiveView: `crypto_wallet_connected`, `crypto_wallet_error`, `crypto_wallet_disconnected`, `crypto_wallet_status`

**`CryptoEscrowHook`** — Manages escrow lifecycle:
- `createEscrow(params)` — 4-step process: get params → build tx → sign+send → confirm with backend
- `releaseEscrow(params)` — Build release tx → sign+send → confirm
- `refundEscrow(params)` — Build refund tx → sign+send → confirm
- Pushes events: `crypto_escrow_created`, `crypto_escrow_released`, `crypto_escrow_refunded`, `crypto_escrow_error`

**RPC Connection:** Reads Solana RPC URL from `<meta name="solana-rpc-url">` tag, falls back to devnet.

### `assets/js/solana_escrow.ts` — Transaction Builder

Constructs raw Solana transactions for the escrow smart contract using `@solana/web3.js` and `@solana/spl-token`.

**PDA Derivation:**
- Escrow: `[b"escrow", escrow_id]`
- Escrow Token: `[b"escrow_token", escrow_id]`

**Exported Functions:**
- `buildCreateEscrowTx(params)` — Builds the `create_escrow` instruction with all required accounts
- `buildReleaseEscrowTx(escrow)` — Builds the `release_escrow` instruction
- `buildRefundEscrowTx(escrow)` — Builds the `refund_escrow` instruction

**Instruction Data Encoding:**
- Uses 8-byte Anchor discriminators (placeholder values — must be replaced with actual IDL discriminators before deployment)
- `create_escrow`: discriminator + escrow_id (length-prefixed) + amount (u64) + platform_fee_bps (u16) + deadline (i64)
- `release_escrow`: discriminator + escrow_id (length-prefixed)
- `refund_escrow`: discriminator + escrow_id (length-prefixed)

> **IMPORTANT**: The instruction discriminators are currently placeholder values (`0x00` bytes). Before deploying to mainnet, these MUST be replaced with the actual discriminators from the Anchor IDL. Run: `anchor idl build && cat target/idl/solana_escrow.json | jq '.instructions[].discriminator'`

---

## Database Schema

### `crypto_wallets` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | `string (PK)` | Unique identifier (Nanoid) |
| `user_id` | `string (FK → users)` | Owning user |
| `address` | `string` | On-chain wallet address (base58) |
| `network` | `enum: solana` | Blockchain network |
| `status` | `enum: active, inactive, verification_pending` | Wallet status |
| `label` | `string` | Display name (e.g., "Phantom") |
| `provider_meta` | `jsonb` | Additional metadata |
| `inserted_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update time |

**Indexes:** `UNIQUE (address, network)`, `user_id`, `network`

### `crypto_escrows` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | `string (PK)` | Unique identifier (Nanoid) |
| `group_id` | `string (UNIQUE)` | Transaction group ID (links to transactions) |
| `payer_wallet_id` | `string (FK → crypto_wallets)` | Payer's linked wallet |
| `contributor_wallet_id` | `string (FK → crypto_wallets)` | Contributor's linked wallet |
| `platform_wallet_id` | `string (FK → crypto_wallets)` | Platform fee wallet |
| `network` | `enum: solana` | Blockchain network |
| `mint_address` | `string` | USDC mint address |
| `amount` | `bigint` | Escrowed amount (micro-USDC) |
| `platform_fee_bps` | `integer (default: 500)` | Platform fee in basis points |
| `deadline` | `timestamp` | Refund eligibility deadline |
| `state` | `enum: created, released, refunded, failed` | Escrow state |
| `escrow_account_address` | `string (UNIQUE)` | On-chain PDA address |
| `escrow_token_account_address` | `string` | On-chain token PDA address |
| `create_transaction_signature` | `string` | Solana tx signature (create) |
| `release_transaction_signature` | `string` | Solana tx signature (release) |
| `refund_transaction_signature` | `string` | Solana tx signature (refund) |
| `nonce` | `bigint (default: 0)` | Replay protection counter |
| `provider_meta` | `jsonb` | Additional metadata |
| `bounty_id` | `string (FK → bounties, nullable)` | Associated bounty |
| `tip_id` | `string (FK → tips, nullable)` | Associated tip |
| `claim_id` | `string (FK → claims, nullable)` | Associated claim |
| `transaction_id` | `string (FK → transactions, nullable)` | Associated transaction |
| `inserted_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update time |

**Indexes:** `UNIQUE group_id`, `UNIQUE escrow_account_address`, `payer_wallet_id`, `contributor_wallet_id`, `state`, `network`, `bounty_id`, `tip_id`

### Custom PostgreSQL Enums

```sql
CREATE TYPE crypto_network AS ENUM ('solana');
CREATE TYPE wallet_status AS ENUM ('active', 'inactive', 'verification_pending');
CREATE TYPE escrow_state AS ENUM ('created', 'released', 'refunded', 'failed');
```

---

## API Reference

All crypto endpoints are under `/api/crypto` and require authentication.

### Wallet Management

#### `POST /api/crypto/wallets`
Links a Solana wallet to the authenticated user.

**Request:**
```json
{
  "address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
  "network": "solana",
  "label": "Phantom"
}
```

**Response (201):**
```json
{
  "id": "V1StGXR8_Z5jdHi6B-myT",
  "address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
  "network": "solana",
  "status": "active",
  "label": "Phantom"
}
```

#### `DELETE /api/crypto/wallets/:id`
Unlinks a wallet (sets status to inactive).

**Response (200):**
```json
{ "success": true }
```

### Escrow Operations

#### `GET /api/crypto/escrow-params`
Returns escrow parameters for frontend transaction construction.

**Query params:** `contributor_handle` or `contributor_id`, `amount`, optional `bounty_id`, `tip_id`, `claim_id`

**Response (200):**
```json
{
  "provider": "crypto",
  "escrow_id": "abc123",
  "network": "solana",
  "payer_address": "7xKX...",
  "contributor_address": "9yKX...",
  "platform_address": "5zKX...",
  "mint_address": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
  "amount": 100000000,
  "platform_fee_bps": 500,
  "deadline": 1735689600,
  "program_id": "Escrow11111111111111111111111111111111111111"
}
```

#### `POST /api/crypto/escrow/confirm`
Confirms escrow creation with the on-chain transaction signature.

**Request:**
```json
{
  "escrow_id": "abc123",
  "signature": "5UfDuX7...",
  "escrow_account_address": "CxV2h...",
  "escrow_token_account_address": "DyW3i..."
}
```

**Response (200):**
```json
{
  "escrow_id": "abc123",
  "state": "created",
  "message": "Escrow creation submitted for verification"
}
```

#### `POST /api/crypto/escrow/:id/release`
Submits a release signature for the payer to release escrowed funds.

**Request:**
```json
{ "signature": "6VgEvY8..." }
```

**Response (200):**
```json
{
  "escrow_id": "abc123",
  "state": "released",
  "message": "Escrow release submitted for verification"
}
```

#### `POST /api/crypto/escrow/:id/refund`
Submits a refund signature.

**Request:**
```json
{ "signature": "7WhFwZ9..." }
```

**Response (200):**
```json
{
  "escrow_id": "abc123",
  "state": "refunded",
  "message": "Escrow refund submitted for verification"
}
```

#### `GET /api/crypto/escrow/:id`
Gets escrow status and details.

**Response (200):**
```json
{
  "id": "abc123",
  "group_id": "grp_456",
  "state": "created",
  "network": "solana",
  "amount": 100000000,
  "platform_fee_bps": 500,
  "deadline": "2026-06-30T00:00:00Z",
  "escrow_account_address": "CxV2h...",
  "create_transaction_signature": "5UfDuX7...",
  "release_transaction_signature": null,
  "refund_transaction_signature": null,
  "inserted_at": "2026-05-31T12:00:00Z"
}
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SOLANA_RPC_URL` | `https://api.mainnet-beta.solana.com` | Solana JSON-RPC endpoint |
| `SOLANA_WS_URL` | `wss://api.mainnet-beta.solana.com` | Solana WebSocket endpoint |
| `SOLANA_ESCROW_PROGRAM_ID` | — | Deployed escrow program ID (required) |
| `CRYPTO_PLATFORM_WALLET_ADDRESS` | — | Platform wallet for receiving 5% fee (must be linked in DB) |

### Development Config

```elixir
# config/dev.exs
config :algora, :crypto,
  solana_rpc_url: "https://api.devnet.solana.com",
  solana_ws_url: "wss://api.devnet.solana.com",
  solana_escrow_program_id: "Escrow11111111111111111111111111111111111111",
  crypto_platform_wallet_address: nil
```

### Production Config

```elixir
# config/runtime.exs
config :algora, :crypto,
  solana_rpc_url: System.get_env("SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com"),
  solana_ws_url: System.get_env("SOLANA_WS_URL", "wss://api.mainnet-beta.solana.com"),
  solana_escrow_program_id: System.get_env("SOLANA_ESCROW_PROGRAM_ID"),
  crypto_platform_wallet_address: System.get_env("CRYPTO_PLATFORM_WALLET_ADDRESS")
```

### Frontend Meta Tags

The frontend reads configuration from HTML meta tags injected by the server:

```html
<meta name="solana-rpc-url" content="https://api.devnet.solana.com" />
<meta name="solana-escrow-program-id" content="Escrow11111111111111111111111111111111111111" />
```

---

## Security Model

### Non-Custodial by Design

The platform never possesses, handles, or has access to private keys. All signing operations occur client-side within the user's wallet extension (Phantom, Solflare). The server only:

1. Provides parameters for transaction construction
2. Verifies on-chain events after they occur
3. Records the results in the database

This means even a complete server compromise cannot result in loss of user funds.

### PDA-Based Escrow Security

Funds are locked in Program Derived Addresses (PDAs) that are controlled exclusively by the escrow smart contract. No external entity — including the platform — can move funds from a PDA without invoking the contract's instructions with the required signers.

- **Create**: Only the payer can create an escrow (must sign the transaction)
- **Release**: Only the original payer can release funds (Signer check against stored `payer` pubkey)
- **Refund**: Only the original payer can request a refund (Signer check + deadline enforcement)

### On-Chain Verification

Before updating any database state, the backend verifies that the corresponding on-chain transaction:

1. Has been confirmed (not just submitted) with `confirmed` or `finalized` status
2. Was executed by the correct escrow program (program ID check)
3. Contains the expected event in its log messages (EscrowCreated/EscrowReleased/EscrowRefunded)

Failed transactions result in the escrow being marked as `:failed` and associated transactions being set to `:failed` status.

### Replay Protection

Each escrow has a `nonce` field that increments with each state transition. The escrow ID (`group_id`) is globally unique (Nanoid), preventing replay of creation transactions. State transitions are guarded by checking the current state before allowing transitions.

### Audit Trail

- Wallet unlinking is soft-delete (status → `inactive`) to maintain history
- All escrow state transitions are recorded with transaction signatures
- `provider_meta` JSONB field stores verification timestamps and additional metadata
- Transaction group IDs link all related financial records together

---

## Fee Structure

| Fee | Amount | Who Pays | When |
|-----|--------|----------|------|
| Platform fee | 5% (500 bps) | Deducted from escrow | On release |
| Solana gas | < $0.01 | Payer | On every transaction |
| Transaction fee | 0% | N/A | N/A |

**Example:** For a $100 bounty:
- Escrow amount: 100 USDC
- On release: 95 USDC → contributor, 5 USDC → platform wallet
- Gas: ~$0.00025 per transaction (paid separately by payer in SOL)

The platform fee matches the existing Stripe fee structure, maintaining consistency for bounty sponsors regardless of payment method.

---

## File Map

Complete list of files added/modified for the crypto payment system:

### New Files (Backend)

| File | Description |
|------|-------------|
| `lib/algora/crypto/crypto.ex` | Crypto context module (wallet + escrow API) |
| `lib/algora/crypto/solana.ex` | Solana JSON-RPC client |
| `lib/algora/crypto/on_chain_verifier.ex` | On-chain event verification service |
| `lib/algora/crypto/jobs/verify_escrow.ex` | Oban worker for async verification |
| `lib/algora/crypto/schemas/crypto_wallet.ex` | Wallet schema + changesets |
| `lib/algora/crypto/schemas/crypto_escrow.ex` | Escrow schema + changesets + fee math |
| `lib/algora/psp/crypto/crypto.ex` | Crypto PSP interface |
| `lib/algora_web/controllers/crypto_controller.ex` | REST API controller |

### New Files (Frontend)

| File | Description |
|------|-------------|
| `assets/js/crypto.ts` | LiveView hooks for wallet + escrow |
| `assets/js/solana_escrow.ts` | Transaction builder for escrow instructions |

### New Files (Smart Contract)

| File | Description |
|------|-------------|
| `contracts/solana-escrow/programs/solana-escrow/src/lib.rs` | Program entry point |
| `contracts/solana-escrow/programs/solana-escrow/src/state.rs` | EscrowAccount struct |
| `contracts/solana-escrow/programs/solana-escrow/src/errors.rs` | Error codes |
| `contracts/solana-escrow/programs/solana-escrow/src/instructions/mod.rs` | Instruction re-exports |
| `contracts/solana-escrow/programs/solana-escrow/src/instructions/create.rs` | create_escrow handler |
| `contracts/solana-escrow/programs/solana-escrow/src/instructions/release.rs` | release_escrow handler |
| `contracts/solana-escrow/programs/solana-escrow/src/instructions/refund.rs` | refund_escrow handler |
| `contracts/solana-escrow/tests/escrow.ts` | Integration tests |
| `contracts/solana-escrow/migrations/deploy.ts` | Deployment script |
| `contracts/solana-escrow/Anchor.toml` | Anchor configuration |
| `contracts/solana-escrow/Cargo.toml` | Rust workspace config |
| `contracts/solana-escrow/programs/solana-escrow/Cargo.toml` | Program Cargo config |
| `contracts/solana-escrow/package.json` | npm dependencies |
| `contracts/solana-escrow/tsconfig.json` | TypeScript config |
| `contracts/solana-escrow/.gitignore` | Git ignore rules |

### New Files (Database)

| File | Description |
|------|-------------|
| `priv/repo/migrations/20260531121341_create_crypto_wallets.exs` | crypto_wallets table |
| `priv/repo/migrations/20260531121342_create_crypto_escrows.exs` | crypto_escrows table |

### Modified Files

| File | Change |
|------|--------|
| `lib/algora_web/router.ex` | Added `/api/crypto/*` routes |
| `config/runtime.exs` | Added crypto config block |
| `config/dev.exs` | Added crypto config block (devnet) |
| `.env.example` | Added `SOLANA_RPC_URL`, `SOLANA_WS_URL`, `SOLANA_ESCROW_PROGRAM_ID`, `CRYPTO_PLATFORM_WALLET_ADDRESS` |

---

## Deployment Checklist

Before deploying the crypto payment system to production:

- [ ] **Deploy escrow program** to Solana mainnet: `anchor deploy --provider.cluster mainnet-beta`
- [ ] **Update program ID** in `lib.rs` (`declare_id!`) with the actual deployed address
- [ ] **Update instruction discriminators** in `solana_escrow.ts` with actual Anchor IDL values
- [ ] **Set environment variables**: `SOLANA_ESCROW_PROGRAM_ID`, `CRYPTO_PLATFORM_WALLET_ADDRESS`
- [ ] **Link platform wallet**: Call `POST /api/crypto/wallets` with the platform wallet address
- [ ] **Run database migrations**: `mix ecto.migrate`
- [ ] **Configure Solana RPC**: Use a dedicated RPC endpoint (Helius, QuickNode, or Triton) for production reliability
- [ ] **Test on devnet** first: Set `SOLANA_RPC_URL` to devnet and test the full flow
- [ ] **Set up Oban queue**: Ensure the `:crypto` queue is configured in Oban for verification jobs
- [ ] **Monitor**: Set up alerts for failed verifications, stuck escrows, and RPC errors

---

## MVP Scope & Limitations

### What's Included (MVP)

- USDC on Solana as the only payment token
- Non-custodial wallet linking (Phantom, Solflare)
- On-chain escrow with create/release/refund lifecycle
- On-chain verification via Solana RPC polling
- 5% platform fee deducted on release
- Integration with existing PSP transaction system
- REST API for all crypto operations
- LiveView hooks for frontend integration
- Oban job for async verification

### What's NOT Included (Future)

- **Multi-chain support** (Ethereum, Polygon, etc.) — architecture is extensible but not implemented
- **Other tokens** (SOL, USDT, etc.) — only USDC mint is configured
- **Dispute resolution** — no on-chain or off-chain dispute mechanism
- **Partial payments** — escrow is all-or-nothing; no partial releases
- **Recurring payments** — no subscription or drip functionality
- **WebSocket subscriptions** — verification uses polling instead of real-time WebSocket events
- **Wallet balance display** — no UI for showing USDC balance
- **Transaction history UI** — no dedicated crypto transaction page (uses existing transactions page)
- **Fee customization** — platform fee is hardcoded at 500 bps per escrow
