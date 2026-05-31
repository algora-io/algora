use anchor_lang::prelude::*;

/// The state of an escrow account.
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, Copy)]
pub enum EscrowState {
    /// Escrow has been created and funds are locked.
    Created,
    /// Funds have been released to the contributor (minus platform fee).
    Released,
    /// Funds have been refunded to the payer.
    Refunded,
}

/// The escrow account storing all escrow metadata and state.
#[account]
pub struct EscrowAccount {
    /// Unique identifier for the escrow (matches Algora DB group_id).
    pub escrow_id: String,

    /// The wallet that deposited the funds into escrow.
    pub payer: Pubkey,

    /// The wallet that will receive the funds upon release.
    pub contributor: Pubkey,

    /// The wallet that receives the platform fee.
    pub platform_wallet: Pubkey,

    /// The SPL token mint address (USDC).
    pub mint: Pubkey,

    /// Total amount of tokens in escrow (in smallest unit, e.g. lamports for USDC = micro-USDC).
    pub amount: u64,

    /// Platform fee in basis points (500 = 5%).
    pub platform_fee_bps: u16,

    /// Unix timestamp after which the payer can reclaim funds.
    pub deadline: i64,

    /// Incrementing nonce for replay protection.
    pub nonce: u64,

    /// Current state of the escrow.
    pub state: EscrowState,

    /// Unix timestamp when the escrow was created.
    pub created_at: i64,

    /// Bump seed for the escrow PDA.
    pub bump: u8,

    /// Bump seed for the escrow token account PDA.
    pub token_bump: u8,
}

impl EscrowAccount {
    /// Calculate the space needed for the EscrowAccount.
    /// String: 4 bytes (length prefix) + max length of escrow_id
    /// Pubkey: 32 bytes each (4 pubkeys = 128)
    /// u64: 8 bytes each (amount, nonce = 16)
    /// u16: 2 bytes (platform_fee_bps)
    /// i64: 8 bytes each (deadline, created_at = 16)
    /// EscrowState: 1 byte (enum)
    /// u8: 1 byte each (bump, token_bump = 2)
    /// Discriminator: 8 bytes
    pub const MAX_ESCROW_ID_LEN: usize = 64;
    pub const SPACE: usize = 8  // discriminator
        + 4 + Self::MAX_ESCROW_ID_LEN  // escrow_id (String with 4-byte length prefix)
        + 32  // payer
        + 32  // contributor
        + 32  // platform_wallet
        + 32  // mint
        + 8   // amount
        + 2   // platform_fee_bps
        + 8   // deadline
        + 8   // nonce
        + 1   // state (enum)
        + 8   // created_at
        + 1   // bump
        + 1;  // token_bump

    /// Calculate the platform fee amount based on basis points.
    pub fn platform_fee(&self) -> Result<u64> {
        let fee = (self.amount as u128)
            .checked_mul(self.platform_fee_bps as u128)
            .ok_or(error!(crate::errors::EscrowError::MathOverflow))?
            .checked_div(10000)
            .ok_or(error!(crate::errors::EscrowError::MathOverflow))?;
        Ok(fee as u64)
    }

    /// Calculate the contributor payout (amount minus platform fee).
    pub fn contributor_amount(&self) -> Result<u64> {
        let fee = self.platform_fee()?;
        self.amount
            .checked_sub(fee)
            .ok_or(error!(crate::errors::EscrowError::MathOverflow).into())
    }
}
