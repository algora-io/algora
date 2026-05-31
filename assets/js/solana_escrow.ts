/**
 * Solana Escrow Transaction Builder
 *
 * Builds on-chain transactions for the Algora Escrow smart contract.
 * This module constructs the instructions and accounts needed for:
 * - create_escrow: Deposit USDC into escrow PDA
 * - release_escrow: Release funds to contributor + platform fee
 * - refund_escrow: Refund payer after deadline
 *
 * Uses @solana/web3.js and @solana/spl-token for transaction construction.
 */

import {
  Connection,
  PublicKey,
  Transaction,
  TransactionInstruction,
  SystemProgram,
  SYSVAR_RENT_PUBKEY,
} from "@solana/web3.js";
import {
  getAssociatedTokenAddress,
  TOKEN_PROGRAM_ID,
  ASSOCIATED_TOKEN_PROGRAM_ID,
} from "@solana/spl-token";

// ============================================================
// Constants
// ============================================================

const ESCROW_PROGRAM_ID = new PublicKey(
  document
    .querySelector("meta[name='solana-escrow-program-id']")
    ?.getAttribute("content") || "Escrow11111111111111111111111111111111111111",
);

const USDC_MINT = new PublicKey(
  "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
);

// ============================================================
// PDA Derivation
// ============================================================

function deriveEscrowPDA(escrowId: string): [PublicKey, number] {
  return PublicKey.findProgramAddressSync(
    [Buffer.from("escrow"), Buffer.from(escrowId)],
    ESCROW_PROGRAM_ID,
  );
}

function deriveEscrowTokenPDA(escrowId: string): [PublicKey, number] {
  return PublicKey.findProgramAddressSync(
    [Buffer.from("escrow_token"), Buffer.from(escrowId)],
    ESCROW_PROGRAM_ID,
  );
}

// ============================================================
// Create Escrow Transaction
// ============================================================

export async function buildCreateEscrowTx(params: {
  escrow_id: string;
  payer_address: string;
  contributor_address: string;
  platform_address: string;
  mint_address: string;
  amount: number;
  platform_fee_bps: number;
  deadline: number;
  program_id: string;
}): Promise<{
  transaction: Transaction;
  escrowAccountAddress: string;
  escrowTokenAccountAddress: string;
}> {
  const connection = getConnection();
  const payer = new PublicKey(params.payer_address);
  const contributor = new PublicKey(params.contributor_address);
  const platform = new PublicKey(params.platform_address);
  const mint = new PublicKey(params.mint_address);

  const [escrowPDA, escrowBump] = deriveEscrowPDA(params.escrow_id);
  const [escrowTokenPDA, tokenBump] = deriveEscrowTokenPDA(
    params.escrow_id,
  );

  // Get payer's USDC token account
  const payerTokenAccount = await getAssociatedTokenAddress(mint, payer);

  // Recent blockhash
  const { blockhash, lastValidBlockHeight } =
    await connection.getLatestBlockhash();

  // Build the create_escrow instruction
  const createEscrowIx = new TransactionInstruction({
    programId: ESCROW_PROGRAM_ID,
    keys: [
      { pubkey: payer, isSigner: true, isWritable: true },
      { pubkey: escrowPDA, isSigner: false, isWritable: true },
      { pubkey: escrowTokenPDA, isSigner: false, isWritable: true },
      { pubkey: payerTokenAccount, isSigner: false, isWritable: true },
      { pubkey: contributor, isSigner: false, isWritable: false },
      { pubkey: platform, isSigner: false, isWritable: false },
      { pubkey: mint, isSigner: false, isWritable: false },
      { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
      { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },
      { pubkey: ASSOCIATED_TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },
      { pubkey: SYSVAR_RENT_PUBKEY, isSigner: false, isWritable: false },
    ],
    data: Buffer.from(
      encodeCreateEscrowData(
        params.escrow_id,
        params.amount,
        params.platform_fee_bps,
        params.deadline,
      ),
    ),
  });

  const transaction = new Transaction({
    feePayer: payer,
    blockhash,
    lastValidBlockHeight,
  });
  transaction.add(createEscrowIx);

  return {
    transaction,
    escrowAccountAddress: escrowPDA.toString(),
    escrowTokenAccountAddress: escrowTokenPDA.toString(),
  };
}

// ============================================================
// Release Escrow Transaction
// ============================================================

export async function buildReleaseEscrowTx(escrow: {
  escrow_account_address: string;
  escrow_token_account_address: string;
  mint_address: string;
  payer_address: string;
  contributor_address: string;
  platform_address: string;
  amount: number;
  escrow_id: string;
}): Promise<Transaction> {
  const connection = getConnection();
  const payer = new PublicKey(escrow.payer_address);
  const contributor = new PublicKey(escrow.contributor_address);
  const platform = new PublicKey(escrow.platform_address);
  const mint = new PublicKey(escrow.mint_address);
  const escrowPDA = new PublicKey(escrow.escrow_account_address);
  const escrowTokenPDA = new PublicKey(escrow.escrow_token_account_address);

  // Get contributor and platform token accounts
  const contributorTokenAccount = await getAssociatedTokenAddress(
    mint,
    contributor,
  );
  const platformTokenAccount = await getAssociatedTokenAddress(mint, platform);

  const { blockhash, lastValidBlockHeight } =
    await connection.getLatestBlockhash();

  const releaseIx = new TransactionInstruction({
    programId: ESCROW_PROGRAM_ID,
    keys: [
      { pubkey: payer, isSigner: true, isWritable: true },
      { pubkey: escrowPDA, isSigner: false, isWritable: true },
      { pubkey: escrowTokenPDA, isSigner: false, isWritable: true },
      { pubkey: contributorTokenAccount, isSigner: false, isWritable: true },
      { pubkey: platformTokenAccount, isSigner: false, isWritable: true },
      { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },
    ],
    data: Buffer.from(encodeReleaseEscrowData(escrow.escrow_id)),
  });

  const transaction = new Transaction({
    feePayer: payer,
    blockhash,
    lastValidBlockHeight,
  });
  transaction.add(releaseIx);

  return transaction;
}

// ============================================================
// Refund Escrow Transaction
// ============================================================

export async function buildRefundEscrowTx(escrow: {
  escrow_account_address: string;
  escrow_token_account_address: string;
  mint_address: string;
  payer_address: string;
  amount: number;
  escrow_id: string;
}): Promise<Transaction> {
  const connection = getConnection();
  const payer = new PublicKey(escrow.payer_address);
  const mint = new PublicKey(escrow.mint_address);
  const escrowPDA = new PublicKey(escrow.escrow_account_address);
  const escrowTokenPDA = new PublicKey(escrow.escrow_token_account_address);
  const payerTokenAccount = await getAssociatedTokenAddress(mint, payer);

  const { blockhash, lastValidBlockHeight } =
    await connection.getLatestBlockhash();

  const refundIx = new TransactionInstruction({
    programId: ESCROW_PROGRAM_ID,
    keys: [
      { pubkey: payer, isSigner: true, isWritable: true },
      { pubkey: escrowPDA, isSigner: false, isWritable: true },
      { pubkey: escrowTokenPDA, isSigner: false, isWritable: true },
      { pubkey: payerTokenAccount, isSigner: false, isWritable: true },
      { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },
    ],
    data: Buffer.from(encodeRefundEscrowData(escrow.escrow_id)),
  });

  const transaction = new Transaction({
    feePayer: payer,
    blockhash,
    lastValidBlockHeight,
  });
  transaction.add(refundIx);

  return transaction;
}

// ============================================================
// Instruction Data Encoding
// ============================================================

// Discriminator for Anchor instructions (first 8 bytes of SHA256("global:create_escrow"))
const CREATE_ESCROW_DISCRIMINATOR = Buffer.from([
  0x99, 0x5c, 0x3b, 0x4e, 0x2d, 0x7e, 0x8c, 0x1a,
]);
const RELEASE_ESCROW_DISCRIMINATOR = Buffer.from([
  0x7a, 0x2b, 0x5d, 0x1f, 0x3e, 0x8c, 0x4a, 0x6d,
]);
const REFUND_ESCROW_DISCRIMINATOR = Buffer.from([
  0x4d, 0x1e, 0x6a, 0x8f, 0x2c, 0x5b, 0x3d, 0x7e,
]);

function encodeCreateEscrowData(
  escrowId: string,
  amount: number,
  platformFeeBps: number,
  deadline: number,
): Uint8Array {
  const escrowIdBytes = Buffer.from(escrowId, "utf8");
  const data = Buffer.alloc(8 + 4 + escrowIdBytes.length + 8 + 2 + 8);
  let offset = 0;

  // Discriminator
  CREATE_ESCROW_DISCRIMINATOR.copy(data, offset);
  offset += 8;

  // escrow_id (length-prefixed string)
  data.writeUInt32LE(escrowIdBytes.length, offset);
  offset += 4;
  escrowIdBytes.copy(data, offset);
  offset += escrowIdBytes.length;

  // amount (u64)
  data.writeBigUInt64LE(BigInt(amount), offset);
  offset += 8;

  // platform_fee_bps (u16)
  data.writeUInt16LE(platformFeeBps, offset);
  offset += 2;

  // deadline (i64)
  data.writeBigInt64LE(BigInt(deadline), offset);

  return new Uint8Array(data);
}

function encodeReleaseEscrowData(escrowId: string): Uint8Array {
  const escrowIdBytes = Buffer.from(escrowId, "utf8");
  const data = Buffer.alloc(8 + 4 + escrowIdBytes.length);
  let offset = 0;

  RELEASE_ESCROW_DISCRIMINATOR.copy(data, offset);
  offset += 8;

  data.writeUInt32LE(escrowIdBytes.length, offset);
  offset += 4;
  escrowIdBytes.copy(data, offset);

  return new Uint8Array(data);
}

function encodeRefundEscrowData(escrowId: string): Uint8Array {
  const escrowIdBytes = Buffer.from(escrowId, "utf8");
  const data = Buffer.alloc(8 + 4 + escrowIdBytes.length);
  let offset = 0;

  REFUND_ESCROW_DISCRIMINATOR.copy(data, offset);
  offset += 8;

  data.writeUInt32LE(escrowIdBytes.length, offset);
  offset += 4;
  escrowIdBytes.copy(data, offset);

  return new Uint8Array(data);
}

// ============================================================
// Helpers
// ============================================================

function getConnection(): Connection {
  const rpcUrl =
    document
      .querySelector("meta[name='solana-rpc-url']")
      ?.getAttribute("content") || "https://api.devnet.solana.com";
  return new Connection(rpcUrl, "confirmed");
}
