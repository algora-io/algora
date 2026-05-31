use anchor_lang::prelude::*;

#[error_code]
pub enum EscrowError {
    #[msg("The specified escrow was not found.")]
    EscrowNotFound,

    #[msg("An escrow with this ID already exists.")]
    EscrowAlreadyExists,

    #[msg("You are not authorized to perform this action.")]
    Unauthorized,

    #[msg("The escrow has expired.")]
    EscrowExpired,

    #[msg("The escrow has not yet expired.")]
    EscrowNotExpired,

    #[msg("The escrow has already been released.")]
    EscrowAlreadyReleased,

    #[msg("The escrow has already been refunded.")]
    EscrowAlreadyRefunded,

    #[msg("The amount must be greater than zero.")]
    InvalidAmount,

    #[msg("The deadline has passed and the escrow is no longer valid.")]
    DeadlinePassed,

    #[msg("The deadline has not yet passed. Refunds are only available after the deadline.")]
    DeadlineNotPassed,

    #[msg("The platform fee basis points cannot exceed 10000 (100%).")]
    InvalidPlatformFeeBps,

    #[msg("The escrow ID is invalid. Must be non-empty and at most 64 characters.")]
    InvalidEscrowId,

    #[msg("Insufficient token balance for the requested operation.")]
    InsufficientBalance,

    #[msg("Math overflow occurred during fee calculation.")]
    MathOverflow,
}
