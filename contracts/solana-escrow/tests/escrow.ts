import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import {
  createMint,
  createAccount,
  mintTo,
  getAccount,
  TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import {
  Keypair,
  LAMPORTS_PER_SOL,
  PublicKey,
  SystemProgram,
  SYSVAR_RENT_PUBKEY,
} from "@solana/web3.js";
import { assert, expect } from "chai";
import { SolanaEscrow } from "../target/types/solana_escrow";

describe("solana-escrow", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.SolanaEscrow as Program<SolanaEscrow>;

  // Test keypairs
  let payer: Keypair;
  let contributor: Keypair;
  let platformWallet: Keypair;
  let usdcMint: PublicKey;
  let payerTokenAccount: PublicKey;
  let contributorTokenAccount: PublicKey;
  let platformTokenAccount: PublicKey;

  const ESCROW_AMOUNT = 100_000_000; // 100 USDC (6 decimals)
  const PLATFORM_FEE_BPS = 500; // 5%
  const ESCROW_ID = "algora-bounty-001";

  // Helper: derive escrow PDA
  function deriveEscrowPda(escrowId: string): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("escrow"), Buffer.from(escrowId)],
      program.programId
    );
  }

  // Helper: derive escrow token account PDA
  function deriveEscrowTokenPda(escrowId: string): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("escrow_token"), Buffer.from(escrowId)],
      program.programId
    );
  }

  // Helper: airdrop SOL to a keypair
  async function airdrop(keypair: Keypair, amount: number = 10 * LAMPORTS_PER_SOL) {
    const sig = await provider.connection.requestAirdrop(
      keypair.publicKey,
      amount
    );
    await provider.connection.confirmTransaction(sig, "confirmed");
  }

  // Helper: get token balance
  async function getTokenBalance(tokenAccount: PublicKey): Promise<number> {
    const account = await getAccount(provider.connection, tokenAccount);
    return Number(account.amount);
  }

  before(async () => {
    // Create and fund keypairs
    payer = Keypair.generate();
    contributor = Keypair.generate();
    platformWallet = Keypair.generate();

    await airdrop(payer);
    await airdrop(contributor);
    await airdrop(platformWallet);

    // Create USDC mint (6 decimals like real USDC)
    usdcMint = await createMint(
      provider.connection,
      payer,
      payer.publicKey,
      null,
      6
    );

    // Create token accounts
    payerTokenAccount = await createAccount(
      provider.connection,
      payer,
      usdcMint,
      payer.publicKey
    );

    contributorTokenAccount = await createAccount(
      provider.connection,
      contributor,
      usdcMint,
      contributor.publicKey
    );

    platformTokenAccount = await createAccount(
      provider.connection,
      platformWallet,
      usdcMint,
      platformWallet.publicKey
    );

    // Mint USDC to payer
    await mintTo(
      provider.connection,
      payer,
      usdcMint,
      payerTokenAccount,
      payer.publicKey,
      1_000_000_000 // 1000 USDC
    );
  });

  describe("create_escrow", () => {
    it("creates an escrow and deposits USDC", async () => {
      const deadline = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now

      const [escrowPda] = deriveEscrowPda(ESCROW_ID);
      const [escrowTokenPda] = deriveEscrowTokenPda(ESCROW_ID);

      const payerBalanceBefore = await getTokenBalance(payerTokenAccount);

      await program.methods
        .createEscrow(
          ESCROW_ID,
          new anchor.BN(ESCROW_AMOUNT),
          PLATFORM_FEE_BPS,
          new anchor.BN(deadline)
        )
        .accounts({
          escrowAccount: escrowPda,
          escrowTokenAccount: escrowTokenPda,
          payerTokenAccount: payerTokenAccount,
          contributor: contributor.publicKey,
          platformWallet: platformWallet.publicKey,
          mint: usdcMint,
          payer: payer.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
          rent: SYSVAR_RENT_PUBKEY,
        })
        .signers([payer])
        .rpc();

      // Verify escrow account data
      const escrowAccount = await program.account.escrowAccount.fetch(escrowPda);
      assert.equal(escrowAccount.escrowId, ESCROW_ID);
      assert.equal(
        escrowAccount.payer.toBase58(),
        payer.publicKey.toBase58()
      );
      assert.equal(
        escrowAccount.contributor.toBase58(),
        contributor.publicKey.toBase58()
      );
      assert.equal(
        escrowAccount.platformWallet.toBase58(),
        platformWallet.publicKey.toBase58()
      );
      assert.equal(escrowAccount.amount.toNumber(), ESCROW_AMOUNT);
      assert.equal(escrowAccount.platformFeeBps, PLATFORM_FEE_BPS);
      assert.equal(escrowAccount.deadline.toNumber(), deadline);
      assert.equal(escrowAccount.nonce.toNumber(), 0);
      assert.deepEqual(escrowAccount.state, { created: {} });

      // Verify token transfer
      const escrowTokenBalance = await getTokenBalance(escrowTokenPda);
      assert.equal(escrowTokenBalance, ESCROW_AMOUNT);

      const payerBalanceAfter = await getTokenBalance(payerTokenAccount);
      assert.equal(payerBalanceBefore - payerBalanceAfter, ESCROW_AMOUNT);
    });

    it("fails to create escrow with duplicate escrow_id", async () => {
      const deadline = Math.floor(Date.now() / 1000) + 86400;

      const [escrowPda] = deriveEscrowPda(ESCROW_ID);
      const [escrowTokenPda] = deriveEscrowTokenPda(ESCROW_ID);

      try {
        await program.methods
          .createEscrow(
            ESCROW_ID,
            new anchor.BN(ESCROW_AMOUNT),
            PLATFORM_FEE_BPS,
            new anchor.BN(deadline)
          )
          .accounts({
            escrowAccount: escrowPda,
            escrowTokenAccount: escrowTokenPda,
            payerTokenAccount: payerTokenAccount,
            contributor: contributor.publicKey,
            platformWallet: platformWallet.publicKey,
            mint: usdcMint,
            payer: payer.publicKey,
            tokenProgram: TOKEN_PROGRAM_ID,
            systemProgram: SystemProgram.programId,
            rent: SYSVAR_RENT_PUBKEY,
          })
          .signers([payer])
          .rpc();
        assert.fail("Should have thrown error");
      } catch (err: any) {
        // Account already in use (PDA already initialized)
        assert.include(err.message, "already in use");
      }
    });

    it("fails to create escrow with zero amount", async () => {
      const escrowId2 = "zero-amount-test";
      const deadline = Math.floor(Date.now() / 1000) + 86400;

      const [escrowPda] = deriveEscrowPda(escrowId2);
      const [escrowTokenPda] = deriveEscrowTokenPda(escrowId2);

      try {
        await program.methods
          .createEscrow(
            escrowId2,
            new anchor.BN(0),
            PLATFORM_FEE_BPS,
            new anchor.BN(deadline)
          )
          .accounts({
            escrowAccount: escrowPda,
            escrowTokenAccount: escrowTokenPda,
            payerTokenAccount: payerTokenAccount,
            contributor: contributor.publicKey,
            platformWallet: platformWallet.publicKey,
            mint: usdcMint,
            payer: payer.publicKey,
            tokenProgram: TOKEN_PROGRAM_ID,
            systemProgram: SystemProgram.programId,
            rent: SYSVAR_RENT_PUBKEY,
          })
          .signers([payer])
          .rpc();
        assert.fail("Should have thrown error");
      } catch (err: any) {
        assert.include(err.error.errorCode.number.toString(), "6007");
      }
    });
  });

  describe("release_escrow", () => {
    it("releases escrow to contributor with platform fee deduction", async () => {
      const [escrowPda] = deriveEscrowPda(ESCROW_ID);
      const [escrowTokenPda] = deriveEscrowTokenPda(ESCROW_ID);

      const contributorBalanceBefore = await getTokenBalance(
        contributorTokenAccount
      );
      const platformBalanceBefore = await getTokenBalance(
        platformTokenAccount
      );

      await program.methods
        .releaseEscrow(ESCROW_ID)
        .accounts({
          escrowAccount: escrowPda,
          escrowTokenAccount: escrowTokenPda,
          contributorTokenAccount: contributorTokenAccount,
          platformTokenAccount: platformTokenAccount,
          authority: payer.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
        })
        .signers([payer])
        .rpc();

      // Verify escrow state
      const escrowAccount = await program.account.escrowAccount.fetch(escrowPda);
      assert.deepEqual(escrowAccount.state, { released: {} });
      assert.equal(escrowAccount.nonce.toNumber(), 1);

      // Verify contributor received 95%
      const expectedContributorAmount =
        ESCROW_AMOUNT - (ESCROW_AMOUNT * PLATFORM_FEE_BPS) / 10000;
      const contributorBalanceAfter = await getTokenBalance(
        contributorTokenAccount
      );
      assert.equal(
        contributorBalanceAfter - contributorBalanceBefore,
        expectedContributorAmount
      );

      // Verify platform received 5%
      const expectedPlatformFee =
        (ESCROW_AMOUNT * PLATFORM_FEE_BPS) / 10000;
      const platformBalanceAfter = await getTokenBalance(
        platformTokenAccount
      );
      assert.equal(
        platformBalanceAfter - platformBalanceBefore,
        expectedPlatformFee
      );

      // Verify escrow token account is empty
      const escrowTokenBalance = await getTokenBalance(escrowTokenPda);
      assert.equal(escrowTokenBalance, 0);
    });

    it("fails to release already released escrow", async () => {
      const [escrowPda] = deriveEscrowPda(ESCROW_ID);
      const [escrowTokenPda] = deriveEscrowTokenPda(ESCROW_ID);

      try {
        await program.methods
          .releaseEscrow(ESCROW_ID)
          .accounts({
            escrowAccount: escrowPda,
            escrowTokenAccount: escrowTokenPda,
            contributorTokenAccount: contributorTokenAccount,
            platformTokenAccount: platformTokenAccount,
            authority: payer.publicKey,
            tokenProgram: TOKEN_PROGRAM_ID,
          })
          .signers([payer])
          .rpc();
        assert.fail("Should have thrown error");
      } catch (err: any) {
        // EscrowAlreadyReleased
        assert.include(err.error.errorCode.number.toString(), "6005");
      }
    });
  });

  describe("refund_escrow", () => {
    const refundEscrowId = "refund-test-escrow";

    before(async () => {
      // Create an escrow with a very short deadline for refund testing
      const deadline = Math.floor(Date.now() / 1000) + 2; // 2 seconds from now

      const [escrowPda] = deriveEscrowPda(refundEscrowId);
      const [escrowTokenPda] = deriveEscrowTokenPda(refundEscrowId);

      await program.methods
        .createEscrow(
          refundEscrowId,
          new anchor.BN(ESCROW_AMOUNT),
          PLATFORM_FEE_BPS,
          new anchor.BN(deadline)
        )
        .accounts({
          escrowAccount: escrowPda,
          escrowTokenAccount: escrowTokenPda,
          payerTokenAccount: payerTokenAccount,
          contributor: contributor.publicKey,
          platformWallet: platformWallet.publicKey,
          mint: usdcMint,
          payer: payer.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
          rent: SYSVAR_RENT_PUBKEY,
        })
        .signers([payer])
        .rpc();

      // Wait for the deadline to pass
      await new Promise((resolve) => setTimeout(resolve, 3000));
    });

    it("refunds the payer after the deadline has passed", async () => {
      const [escrowPda] = deriveEscrowPda(refundEscrowId);
      const [escrowTokenPda] = deriveEscrowTokenPda(refundEscrowId);

      const payerBalanceBefore = await getTokenBalance(payerTokenAccount);

      await program.methods
        .refundEscrow(refundEscrowId)
        .accounts({
          escrowAccount: escrowPda,
          escrowTokenAccount: escrowTokenPda,
          payerTokenAccount: payerTokenAccount,
          authority: payer.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
        })
        .signers([payer])
        .rpc();

      // Verify escrow state
      const escrowAccount = await program.account.escrowAccount.fetch(escrowPda);
      assert.deepEqual(escrowAccount.state, { refunded: {} });
      assert.equal(escrowAccount.nonce.toNumber(), 1);

      // Verify full amount refunded
      const payerBalanceAfter = await getTokenBalance(payerTokenAccount);
      assert.equal(payerBalanceAfter - payerBalanceBefore, ESCROW_AMOUNT);

      // Verify escrow token account is empty
      const escrowTokenBalance = await getTokenBalance(escrowTokenPda);
      assert.equal(escrowTokenBalance, 0);
    });

    it("fails to refund before the deadline has passed", async () => {
      // Create a new escrow with a far future deadline
      const earlyEscrowId = "early-refund-test";
      const deadline = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now

      const [escrowPda] = deriveEscrowPda(earlyEscrowId);
      const [escrowTokenPda] = deriveEscrowTokenPda(earlyEscrowId);

      await program.methods
        .createEscrow(
          earlyEscrowId,
          new anchor.BN(ESCROW_AMOUNT),
          PLATFORM_FEE_BPS,
          new anchor.BN(deadline)
        )
        .accounts({
          escrowAccount: escrowPda,
          escrowTokenAccount: escrowTokenPda,
          payerTokenAccount: payerTokenAccount,
          contributor: contributor.publicKey,
          platformWallet: platformWallet.publicKey,
          mint: usdcMint,
          payer: payer.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
          rent: SYSVAR_RENT_PUBKEY,
        })
        .signers([payer])
        .rpc();

      try {
        await program.methods
          .refundEscrow(earlyEscrowId)
          .accounts({
            escrowAccount: escrowPda,
            escrowTokenAccount: escrowTokenPda,
            payerTokenAccount: payerTokenAccount,
            authority: payer.publicKey,
            tokenProgram: TOKEN_PROGRAM_ID,
          })
          .signers([payer])
          .rpc();
        assert.fail("Should have thrown error");
      } catch (err: any) {
        // DeadlineNotPassed
        assert.include(err.error.errorCode.number.toString(), "6009");
      }
    });

    it("fails to refund by unauthorized caller", async () => {
      const earlyEscrowId = "unauthorized-refund-test";
      const deadline = Math.floor(Date.now() / 1000) + 86400;

      const [escrowPda] = deriveEscrowPda(earlyEscrowId);
      const [escrowTokenPda] = deriveEscrowTokenPda(earlyEscrowId);

      await program.methods
        .createEscrow(
          earlyEscrowId,
          new anchor.BN(ESCROW_AMOUNT),
          PLATFORM_FEE_BPS,
          new anchor.BN(deadline)
        )
        .accounts({
          escrowAccount: escrowPda,
          escrowTokenAccount: escrowTokenPda,
          payerTokenAccount: payerTokenAccount,
          contributor: contributor.publicKey,
          platformWallet: platformWallet.publicKey,
          mint: usdcMint,
          payer: payer.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
          rent: SYSVAR_RENT_PUBKEY,
        })
        .signers([payer])
        .rpc();

      try {
        await program.methods
          .refundEscrow(earlyEscrowId)
          .accounts({
            escrowAccount: escrowPda,
            escrowTokenAccount: escrowTokenPda,
            payerTokenAccount: payerTokenAccount,
            authority: contributor.publicKey, // Not the payer!
            tokenProgram: TOKEN_PROGRAM_ID,
          })
          .signers([contributor])
          .rpc();
        assert.fail("Should have thrown error");
      } catch (err: any) {
        // Unauthorized
        assert.include(err.error.errorCode.number.toString(), "6002");
      }
    });
  });
});
