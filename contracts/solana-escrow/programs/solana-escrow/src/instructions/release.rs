use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer};

use crate::errors::EscrowError;
use crate::state::{EscrowAccount, EscrowState};

/// Event emitted when an escrow is released to the contributor.
#[event]
pub struct EscrowReleased {
    pub escrow_id: String,
    pub payer: Pubkey,
    pub contributor: Pubkey,
    pub platform_wallet: Pubkey,
    pub amount: u64,
    pub contributor_amount: u64,
    pub platform_fee: u64,
    pub nonce: u64,
    pub released_at: i64,
}

/// Accounts required for the `release_escrow` instruction.
#[derive(Accounts)]
#[instruction(escrow_id: String)]
pub struct ReleaseEscrow<'info> {
    /// The escrow state account (PDA).
    #[account(
        mut,
        seeds = [b"escrow", escrow_id.as_bytes()],
        bump = escrow_account.bump,
        constraint = escrow_account.state == EscrowState::Created @ EscrowError::EscrowAlreadyReleased,
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

    /// The contributor's USDC token account (receives 95% of funds).
    #[account(
        mut,
        constraint = contributor_token_account.owner == escrow_account.contributor @ EscrowError::Unauthorized,
        constraint = contributor_token_account.mint == escrow_account.mint @ EscrowError::Unauthorized,
    )]
    pub contributor_token_account: Account<'info, TokenAccount>,

    /// The platform's USDC token account (receives 5% fee).
    #[account(
        mut,
        constraint = platform_token_account.owner == escrow_account.platform_wallet @ EscrowError::Unauthorized,
        constraint = platform_token_account.mint == escrow_account.mint @ EscrowError::Unauthorized,
    )]
    pub platform_token_account: Account<'info, TokenAccount>,

    /// The authority (payer/creator) of the escrow. Must sign to release.
    #[account(
        constraint = authority.key() == escrow_account.payer @ EscrowError::Unauthorized,
    )]
    pub authority: Signer<'info>,

    pub token_program: Program<'info, Token>,
}

/// Releases escrowed funds to the contributor, deducting the platform fee.
///
/// Only the escrow creator (payer) can release the funds.
/// The deadline must not have passed.
/// Splits: (100 - platform_fee_bps)% to contributor, platform_fee_bps% to platform_wallet.
///
/// # Arguments
/// * `escrow_id` - Unique identifier for the escrow to release
pub fn handler(ctx: Context<ReleaseEscrow>, escrow_id: String) -> Result<()> {
    let escrow = &mut ctx.accounts.escrow_account;
    let clock = Clock::get()?;

    // --- Validations ---
    // Check that the escrow has not expired
    require!(
        clock.unix_timestamp <= escrow.deadline,
        EscrowError::EscrowExpired
    );

    // Verify escrow is in Created state (already enforced by constraint, but double-check)
    require!(
        escrow.state == EscrowState::Created,
        EscrowError::EscrowAlreadyReleased
    );

    // --- Calculate splits ---
    let contributor_amount = escrow.contributor_amount()?;
    let platform_fee = escrow.platform_fee()?;

    // Safety check: total payout should not exceed escrow amount
    require!(
        contributor_amount
            .checked_add(platform_fee)
            .ok_or(EscrowError::MathOverflow)?
            <= escrow.amount,
        EscrowError::MathOverflow
    );

    // --- Transfer contributor's share from escrow token account ---
    let escrow_seeds = &[
        b"escrow",
        escrow.escrow_id.as_bytes(),
        &[escrow.bump],
    ];
    let signer_seeds = &[&escrow_seeds[..]];

    // Transfer to contributor
    let contributor_transfer = Transfer {
        from: ctx.accounts.escrow_token_account.to_account_info(),
        to: ctx.accounts.contributor_token_account.to_account_info(),
        authority: ctx.accounts.escrow_account.to_account_info(),
    };
    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            contributor_transfer,
            signer_seeds,
        ),
        contributor_amount,
    )?;

    // Transfer platform fee (only if fee > 0)
    if platform_fee > 0 {
        let platform_transfer = Transfer {
            from: ctx.accounts.escrow_token_account.to_account_info(),
            to: ctx.accounts.platform_token_account.to_account_info(),
            authority: ctx.accounts.escrow_account.to_account_info(),
        };
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                platform_transfer,
                signer_seeds,
            ),
            platform_fee,
        )?;
    }

    // --- Update escrow state ---
    escrow.state = EscrowState::Released;
    escrow.nonce = escrow
        .nonce
        .checked_add(1)
        .ok_or(EscrowError::MathOverflow)?;

    // --- Emit Event ---
    emit!(EscrowReleased {
        escrow_id: escrow.escrow_id.clone(),
        payer: escrow.payer,
        contributor: escrow.contributor,
        platform_wallet: escrow.platform_wallet,
        amount: escrow.amount,
        contributor_amount,
        platform_fee,
        nonce: escrow.nonce,
        released_at: clock.unix_timestamp,
    });

    Ok(())
}
