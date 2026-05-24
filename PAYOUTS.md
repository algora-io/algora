# Payouts - International Options

## Current Payment Setup

Algora primarily uses **Stripe** for automated bounty payouts to contributors. When a PR is merged:
- Algora's payment processor handles the transfer
- Contributors receive funds via their registered Stripe account
- This works seamlessly in most regions

## Regions Where Stripe is Limited

Some regions (e.g., mainland China) have limited Stripe support. Contributors there cannot complete Stripe onboarding.

## Available Options for Unsupported Regions

### 1. PayPal (Manual Payouts)

For contributors who cannot use Stripe:
- **Sponsors can manually pay** via PayPal after bounty approval
- Contributor provides: PayPal email (e.g., `hoolqee@126.com`)
- Sponsor sends payment outside Algora's automated system
- Contributor confirms receipt in the issue/PR

**Process:**
1. Contributor comments with PayPal email:  
   `@sponsor I'm in mainland China, cannot use Stripe. PayPal: user@example.com`
2. Sponsor reviews and sends payment manually
3. Contributor confirms: `@sponsor Received $40 via PayPal, thank you!`
4. Sponsor closes the bounty

### 2. USDC on Arbitrum One (Crypto)

As mentioned in issue #395 (Algora app), preferred crypto payout:
- **USDC on Arbitrum One** (low fees, fast settlement)
- Contributor provides ERC-20 wallet address
- Sponsor sends USDC via Arbitrum One network

### 3. Other Options

- **Wire Transfer**: For larger amounts, sponsors may arrange international wire
- **Wise (formerly TransferWise)**: Available in many regions where Stripe is limited
- **Algora Escrow**: Sponsors can deposit funds with Algora for manual distribution

## Security Notes

- ⚠️ **Never post wallet addresses or PayPal emails in public comments** (risk of impersonation spam like issue #1724)
- Use **private issue comments** or **direct message** for sensitive payment details
- Verify contributor identity before manual payouts

## For Maintainers

When handling bounties with international contributors:
1. Check if contributor can use Stripe (`/claim` will fail if not)
2. If Stripe fails, ask contributor to provide alternative payment method
3. Choose PayPal, USDC (Arbitrum), or other agreed method
4. Process payment manually after PR merge
5. Close bounty with note: `Manually paid via PayPal/USDC`

## Questions?

Open an issue with label `payouts` or contact @algora-io/maintainers.

---

**Note**: Algora's automated Stripe payouts remain the recommended path for supported regions. Manual payouts are exceptions for unsupported territories.
