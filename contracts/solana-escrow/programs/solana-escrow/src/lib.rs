//! # Algora Solana Escrow Smart Contract
//!
//! A non-custodial escrow contract for USDC bounty payments on Solana.
//! Built with the Anchor framework.
//!
//! ## Features
//! - USDC (SPL Token) escrow with PDA-based security
//! - 5% platform fee (configurable in basis points)
//! - Deadline-based refund mechanism
//! - Nonce-based replay protection
//! - Comprehensive event logging
//!
//! ## Instructions
//! - `create_escrow` - Deposit USDC into escrow
//! - `release_escrow` - Release funds to contributor (minus platform fee)
//! - `refund_escrow` - Refund payer after deadline passes

use anchor_lang::prelude::*;

pub mod errors;
pub mod instructions;
pub mod state;

use instructions::*;

declare_id!("Escrow11111111111111111111111111111111111111");

#[program]
pub mod solana_escrow {
    use super::*;

    /// Creates a new escrow by depositing USDC from the payer into an escrow PDA.
    ///
    /// # Arguments
    /// * `escrow_id` - Unique identifier for the escrow (matches Algora DB group_id)
    /// * `amount` - Amount of USDC to deposit (in smallest unit, e.g. micro-USDC)
    /// * `platform_fee_bps` - Platform fee in basis points (500 = 5%)
    /// * `deadline` - Unix timestamp after which the escrow can be refunded
    ///
    /// # Errors
    /// Returns `EscrowError` if validation fails.
    pub fn create_escrow(
        ctx: Context<CreateEscrow>,
        escrow_id: String,
        amount: u64,
        platform_fee_bps: u16,
        deadline: i64,
    ) -> Result<()> {
        instructions::create::handler(ctx, escrow_id, amount, platform_fee_bps, deadline)
    }

    /// Releases escrowed funds to the contributor, deducting the platform fee.
    ///
    /// Only the escrow creator (payer) can call this instruction.
    /// The deadline must not have passed.
    /// Splits: (100 - platform_fee_bps)% to contributor, platform_fee_bps% to platform_wallet.
    ///
    /// # Arguments
    /// * `escrow_id` - Unique identifier for the escrow to release
    ///
    /// # Errors
    /// Returns `EscrowError` if validation fails or unauthorized.
    pub fn release_escrow(ctx: Context<ReleaseEscrow>, escrow_id: String) -> Result<()> {
        instructions::release::handler(ctx, escrow_id)
    }

    /// Refunds the escrowed USDC back to the payer.
    ///
    /// Only the original payer can request a refund.
    /// The deadline must have passed before a refund is allowed.
    /// The full amount is returned (no fee deducted on refund).
    ///
    /// # Arguments
    /// * `escrow_id` - Unique identifier for the escrow to refund
    ///
    /// # Errors
    /// Returns `EscrowError` if validation fails or deadline not passed.
    pub fn refund_escrow(ctx: Context<RefundEscrow>, escrow_id: String) -> Result<()> {
        instructions::refund::handler(ctx, escrow_id)
    }
}
