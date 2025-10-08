import { Gateway, Wallets } from "fabric-network";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";

dotenv.config();

/**
 * Connect to Hyperledger Fabric gateway and return contract instance
 * @returns {Object} { gateway, contract } - Gateway and contract instances
 */
export async function connectGateway() {
  try {
    const ccpPath = path.resolve(
      process.cwd(),
      process.env.FABRIC_CONNECTION || "./connection-org1.json"
    );

    if (!fs.existsSync(ccpPath)) {
      throw new Error(
        `Connection profile not found at ${ccpPath}. Please ensure Fabric network is set up.`
      );
    }

    const ccp = JSON.parse(fs.readFileSync(ccpPath, "utf8"));
    const walletPath = path.resolve(
      process.cwd(),
      process.env.WALLET_PATH || "./wallet"
    );
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    const identity = process.env.FABRIC_USER || "appUser";
    const identityExists = await wallet.get(identity);

    if (!identityExists) {
      throw new Error(
        `Identity ${identity} does not exist in wallet. Please enroll the user first.`
      );
    }

    const gateway = new Gateway();
    await gateway.connect(ccp, {
      wallet,
      identity: identity,
      discovery: { enabled: true, asLocalhost: true },
    });

    const network = await gateway.getNetwork(
      process.env.CHANNEL_NAME || "mychannel"
    );
    const contract = network.getContract(
      process.env.CHAINCODE_NAME || "hashcc"
    );

    console.log("Successfully connected to Fabric network");
    return { gateway, contract };
  } catch (err) {
    console.error("Error connecting to Fabric gateway:", err);
    throw err;
  }
}

/**
 * Submit a transaction to the blockchain
 * @param {string} functionName - Chaincode function name
 * @param  {...any} args - Function arguments
 */
export async function submitTransaction(functionName, ...args) {
  const { gateway, contract } = await connectGateway();
  try {
    const result = await contract.submitTransaction(functionName, ...args);
    return result.toString();
  } finally {
    await gateway.disconnect();
  }
}

/**
 * Evaluate a transaction (query) on the blockchain
 * @param {string} functionName - Chaincode function name
 * @param  {...any} args - Function arguments
 */
export async function evaluateTransaction(functionName, ...args) {
  const { gateway, contract } = await connectGateway();
  try {
    const result = await contract.evaluateTransaction(functionName, ...args);
    return result.toString();
  } finally {
    await gateway.disconnect();
  }
}
