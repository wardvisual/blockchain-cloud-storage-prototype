import { Wallets } from "fabric-network";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Enroll appUser into the wallet using credentials from Fabric test-network
 *
 * Usage: node enrollUser.js [path-to-test-network]
 * Example: node enrollUser.js ../../../fabric-samples/test-network
 */
async function main() {
  try {
    // Get test network path from command line or use default
    const testNetworkPath =
      process.argv[2] || "../../../fabric-samples/test-network";

    console.log("Enrolling user with credentials from:", testNetworkPath);

    // Path to User1's crypto materials in the test network
    const credPath = path.resolve(
      __dirname,
      testNetworkPath,
      "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
    );

    console.log("Reading credentials from:", credPath);

    // Read the certificate
    const certPath = path.join(credPath, "signcerts", "cert.pem");
    if (!fs.existsSync(certPath)) {
      throw new Error(`Certificate not found at ${certPath}`);
    }
    const certificate = fs.readFileSync(certPath).toString();

    // Read the private key
    const keystorePath = path.join(credPath, "keystore");
    const keyFiles = fs.readdirSync(keystorePath);
    if (keyFiles.length === 0) {
      throw new Error(`No private key found in ${keystorePath}`);
    }
    const privateKey = fs
      .readFileSync(path.join(keystorePath, keyFiles[0]))
      .toString();

    // Create wallet in backend directory
    const walletPath = path.resolve(__dirname, "../wallet");
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    // Create identity object
    const identity = {
      credentials: {
        certificate,
        privateKey,
      },
      mspId: "Org1MSP",
      type: "X.509",
    };

    // Import identity into wallet
    await wallet.put("appUser", identity);

    console.log("✓ Successfully enrolled appUser and imported into wallet");
    console.log(`✓ Wallet location: ${walletPath}`);
    console.log("✓ Identity name: appUser");
    console.log("✓ MSP ID: Org1MSP");

    // Verify the identity was added
    const userIdentity = await wallet.get("appUser");
    if (userIdentity) {
      console.log("✓ Verified: Identity exists in wallet");
    } else {
      console.error("✗ Error: Identity was not added to wallet");
    }
  } catch (error) {
    console.error("Error enrolling user:", error.message);
    console.error("\nMake sure:");
    console.error("1. Fabric test network is running");
    console.error("2. Path to test-network is correct");
    console.error("3. User1 credentials exist in test-network");
    console.error("\nUsage: node enrollUser.js [path-to-test-network]");
    process.exit(1);
  }
}

main();
