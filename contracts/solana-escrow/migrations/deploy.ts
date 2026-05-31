// Migrations script for deploying the Solana Escrow program
import * as anchor from "@coral-xyz/anchor";

module.exports = async function (provider: anchor.Provider) {
  anchor.setProvider(provider);

  console.log("Deploying Solana Escrow program...");
  console.log(`Provider cluster: ${provider.connection.rpcEndpoint}`);
  console.log(`Deployer: ${provider.wallet.publicKey.toBase58()}`);

  // The program is deployed via `anchor deploy` which reads from Anchor.toml.
  // This script can be used for post-deployment setup or verification.

  const programId = new anchor.web3.PublicKey(
    "Escrow11111111111111111111111111111111111111"
  );

  console.log(`Program ID: ${programId.toBase58()}`);
  console.log("Deployment complete. Verify with: anchor verify <program-id>");
};
