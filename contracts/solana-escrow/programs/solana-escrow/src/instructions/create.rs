use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer};

use crate::errors::EscrowError;
use crate::state::{EscrowAccount, EscrowState};

/// Event emitted when a new escrow is created.
#[event]
pub struct EscrowCreated {
    pub escrow_id: String,
    pub payer: Pubkey,
    pub contributor: Pubkey,
    pub platform_wallet: Pubkey,
    pub mint: Pubkey,
    pub amount: u64,
    pub platform_fee_bps: u16,
    pub deadline: i64,
    pub nonce: u64,
    pub created_at: i64,
}

/// Accounts required for the `create_escrow` instruction.
#[derive(Accounts)]
#[instruction(escrow_id: String, amount: u64, platform_fee_bps: u16, deadline: i64)]
pub struct CreateEscrow<'info> {
    /// The escrow state account (PDA). Initialized on creation.
    #[account(
        init,
        payer = payer,
        space = EscrowAccount::SPACE,
        seeds = [b"escrow", escrow_id.as_bytes()],
        bump,
    )]
    pub escrow_account: Account<'info, EscrowAccount>,

    /// The token account (PDA) that holds the escrowed USDC.
    #[account(
        init,
        payer = payer,
        token::mint = mint,
        token::authority = escrow_account,
        seeds = [b"escrow_token", escrow_id.as_bytes()],
        bump,
    )]
    pub escrow_token_account: Account<'info, TokenAccount>,

    /// The payer's USDC token account (source of deposit).
    #[account(
        mut,
        constraint = payer_token_account.owner == payer.key() @ EscrowError::Unauthorized,
        constraint = payer_token_account.mint == mint.key() @ EscrowError::Unauthorized,
    )]
    pub payer_token_account: Account<'info, TokenAccount>,

    /// CHECK: The contributor wallet address. Validated by being stored and used only on release.
    /// This is the wallet that will receive the bounty funds upon release.
    pub contributor: SystemAccount<'info>,

    /// CHECK: The platform wallet address. Receives the platform fee on release.
    /// Stored in the escrow account and used only for fee distribution.
    pub platform_wallet: SystemAccount<'info>,

    /// The USDC mint.
    pub mint: Account<'info, Mint>,

    /// The payer who creates the escrow and deposits USDC.
    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

/// Creates a new escrow: deposits USDC from the payer into an escrow PDA token account.
///
/// # Arguments
/// * `escrow_id` - Unique identifier for the escrow (matches Algora DB group_id)
/// * `amount` - Amount of USDC to deposit (in smallest unit)
/// * `platform_fee_bps` - Platform fee in basis points (500 = 5%)
/// * `deadline` - Unix timestamp after which the escrow can be refunded
pub fn handler(
    ctx: Context<CreateEscrow>,
    escrow_id: String,
    amount: u64,
    platform_fee_bps: u16,
    deadline: i64,
) -> Result<()> {
    // --- Validations ---
    require!(amount > 0, EscrowError::InvalidAmount);
    require!(
        platform_fee_bps <= 10000,
        EscrowError::InvalidPlatformFeeBps
    );

    let clock = Clock::get()?;
    require!(
        deadline > clock.unix_timestamp,
        EscrowError::DeadlinePassed
    );

    // Validate escrow_id: must be non-empty and within length limit
    require!(!escrow_id.is_empty(), EscrowError::InvalidEscrowId);
    require!(
        escrow_id.len() <= EscrowAccount::MAX_ESCROW_ID_LEN,
        EscrowError::InvalidEscrowId
    );

    // Verify payer has sufficient token balance
    require!(
        ctx.accounts.payer_token_account.amount >= amount,
        EscrowError::InsufficientBalance
    );

    // --- Transfer USDC from payer to escrow token account ---
    let cpi_accounts = Transfer {
        from: ctx.accounts.payer_token_account.to_account_info(),
        to: ctx.accounts.escrow_token_account.to_account_info(),
        authority: ctx.accounts.payer.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    token::transfer(CpiContext::new(cpi_program, cpi_accounts), amount)?;

    // --- Initialize EscrowAccount ---
    let escrow = &mut ctx.accounts.escrow_account;
    let bump = ctx.bumps.escrow_account;
    let token_bump = ctx.bumps.escrow_token_account;

    escrow.escrow_id = escrow_id.clone();
    escrow.payer = ctx.accounts.payer.key();
    escrow.contributor = ctx.accounts.contributor.key();
    escrow.platform_wallet = ctx.accounts.platform_wallet.key();
    escrow.mint = ctx.accounts.mint.key();
    escrow.amount = amount;
    escrow.platform_fee_bps = platform_fee_bps;
    escrow.deadline = deadline;
    escrow.nonce = 0;
    escrow.state = EscrowState::Created;
    escrow.created_at = clock.unix_timestamp;
    escrow.bump = bump;
    escrow.token_bump = token_bump;

    // --- Emit Event ---
    emit!(EscrowCreated {
        escrow_id,
        payer: ctx.accounts.payer.key(),
        contributor: ctx.accounts.contributor.key(),
        platform_wallet: ctx.accounts.platform_wallet.key(),
        mint: ctx.accounts.mint.key(),
        amount,
        platform_fee_bps,
        deadline,
        nonce: 0,
        created_at: clock.unix_timestamp,
    });

    Ok(())
}
