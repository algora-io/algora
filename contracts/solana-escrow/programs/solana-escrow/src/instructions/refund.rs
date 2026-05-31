use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer};

use crate::errors::EscrowError;
use crate::state::{EscrowAccount, EscrowState};

/// Event emitted when an escrow is refunded to the payer.
#[event]
pub struct EscrowRefunded {
    pub escrow_id: String,
    pub payer: Pubkey,
    pub amount: u64,
    pub nonce: u64,
    pub refunded_at: i64,
}

/// Accounts required for the `refund_escrow` instruction.
#[derive(Accounts)]
#[instruction(escrow_id: String)]
pub struct RefundEscrow<'info> {
    /// The escrow state account (PDA).
    #[account(
        mut,
        seeds = [b"escrow", escrow_id.as_bytes()],
        bump = escrow_account.bump,
        constraint = escrow_account.state == EscrowState::Created @ EscrowError::EscrowAlreadyRefunded,
    )]
    pub escrow_account: Account<'info, EscrowAccount>,

    /// The escrow token account (PDA) holding the locked USDC.
    #[account(
        mut,
        seeds = [b"escrow_token", escrow_id.as_bytes()],
        bump = escrow_account.token_bump,
        constraint = escrow_token_account.mint == escrow_account.mint @ EscrowError::Unauthorized,
    )]
    pub escrow_token_account: Account<'info, TokenAccount>,

    /// The payer's USDC token account (receives the full refund).
    #[account(
        mut,
        constraint = payer_token_account.owner == escrow_account.payer @ EscrowError::Unauthorized,
        constraint = payer_token_account.mint == escrow_account.mint @ EscrowError::Unauthorized,
    )]
    pub payer_token_account: Account<'info, TokenAccount>,

    /// The authority requesting the refund. Must be the original payer.
    #[account(
        constraint = authority.key() == escrow_account.payer @ EscrowError::Unauthorized,
    )]
    pub authority: Signer<'info>,

    pub token_program: Program<'info, Token>,
}

/// Refunds the escrowed USDC back to the payer.
///
/// Only the original payer can request a refund.
/// The deadline must have passed before a refund is allowed.
/// The full amount is returned to the payer (no fee deducted on refund).
///
/// # Arguments
/// * `escrow_id` - Unique identifier for the escrow to refund
pub fn handler(ctx: Context<RefundEscrow>, escrow_id: String) -> Result<()> {
    let escrow = &mut ctx.accounts.escrow_account;
    let clock = Clock::get()?;

    // --- Validations ---
    // Deadline must have passed
    require!(
        clock.unix_timestamp > escrow.deadline,
        EscrowError::DeadlineNotPassed
    );

    // Escrow must be in Created state (enforced by constraint, but double-check)
    require!(
        escrow.state == EscrowState::Created,
        EscrowError::EscrowAlreadyRefunded
    );

    // --- Transfer full amount back to payer ---
    let escrow_seeds = &[
        b"escrow",
        escrow.escrow_id.as_bytes(),
        &[escrow.bump],
    ];
    let signer_seeds = &[&escrow_seeds[..]];

    let refund_transfer = Transfer {
        from: ctx.accounts.escrow_token_account.to_account_info(),
        to: ctx.accounts.payer_token_account.to_account_info(),
        authority: ctx.accounts.escrow_account.to_account_info(),
    };
    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            refund_transfer,
            signer_seeds,
        ),
        escrow.amount,
    )?;

    // --- Update escrow state ---
    escrow.state = EscrowState::Refunded;
    escrow.nonce = escrow
        .nonce
        .checked_add(1)
        .ok_or(EscrowError::MathOverflow)?;

    // --- Emit Event ---
    emit!(EscrowRefunded {
        escrow_id: escrow.escrow_id.clone(),
        payer: escrow.payer,
        amount: escrow.amount,
        nonce: escrow.nonce,
        refunded_at: clock.unix_timestamp,
    });

    Ok(())
}
