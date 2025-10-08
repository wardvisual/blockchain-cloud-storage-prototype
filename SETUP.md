# Hyperledger Fabric + MinIO Prototype - Setup Guide

## Quick Setup Instructions

### 1. Install Prerequisites

#### Windows (WSL2 recommended)

```bash
# Install WSL2 if not already installed
wsl --install

# Inside WSL, install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker Desktop for Windows (includes Docker Compose)
# Download from: https://www.docker.com/products/docker-desktop
```

#### Linux/macOS

```bash
# Install Node.js (v18 LTS)
# Visit: https://nodejs.org/

# Install Docker
# Visit: https://docs.docker.com/get-docker/

# Install Docker Compose
# Visit: https://docs.docker.com/compose/install/
```

### 2. Set Up MinIO

```bash
# Run MinIO container
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  -v ~/minio/data:/data \
  minio/minio server /data --console-address ":9001"

# Verify MinIO is running
docker ps | grep minio

# Access MinIO Console at http://localhost:9001
# Login: minioadmin / minioadmin
```

### 3. Set Up Hyperledger Fabric

```bash
# Create a directory for Fabric
mkdir -p ~/fabric
cd ~/fabric

# Download Fabric samples and binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.5

# Navigate to test network
cd fabric-samples/test-network

# Start the network
./network.sh down  # Clean up any previous network
./network.sh up createChannel -c mychannel -ca

# The network should now be running
docker ps  # You should see peer, orderer, and CA containers
```

### 4. Deploy Chaincode

```bash
# From fabric-samples/test-network directory

# Deploy the hash-chaincode
# Replace the path with the actual path to your prototype
./network.sh deployCC \
  -ccn hashcc \
  -ccp /path/to/prototype/chaincode/hash-chaincode \
  -ccl javascript

# Verify deployment
docker ps | grep dev-peer
```

### 5. Create User Identity

```bash
# From fabric-samples/test-network directory

# Set environment variables
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/

# Set organization 1 environment
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Register and enroll appUser
# You can use the Fabric CA client or the test-network scripts
# For simplicity, we'll create a wallet from the existing test-network identities

# Create wallet directory in backend
cd /path/to/prototype/backend
mkdir -p wallet

# Copy the test-network identity to wallet
# This is a simplified approach for testing
# In production, you would properly enroll users
```

### 6. Copy Connection Profile

```bash
# From fabric-samples/test-network directory
cp organizations/peerOrganizations/org1.example.com/connection-org1.json \
   /path/to/prototype/backend/connection-org1.json
```

### 7. Set Up Backend

```bash
# Navigate to backend directory
cd /path/to/prototype/backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env file with correct paths
nano .env

# Make sure these paths are correct:
# FABRIC_CONNECTION=./connection-org1.json
# WALLET_PATH=./wallet
```

### 8. Create Wallet Identity (Helper Script)

Create a file `backend/scripts/enrollUser.js`:

```javascript
import { Wallets } from "fabric-network";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
  try {
    // Path to crypto materials from test-network
    const testNetworkPath =
      process.argv[2] || "../../fabric-samples/test-network";
    const credPath = path.join(
      testNetworkPath,
      "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
    );

    const certificate = fs
      .readFileSync(path.join(credPath, "signcerts/cert.pem"))
      .toString();
    const privateKey = fs
      .readFileSync(path.join(credPath, "keystore/priv_sk"))
      .toString();

    const wallet = await Wallets.newFileSystemWallet("./wallet");

    const identity = {
      credentials: {
        certificate,
        privateKey,
      },
      mspId: "Org1MSP",
      type: "X.509",
    };

    await wallet.put("appUser", identity);
    console.log("Successfully enrolled appUser and imported into wallet");
  } catch (error) {
    console.error("Error enrolling user:", error);
    process.exit(1);
  }
}

main();
```

Run it:

```bash
cd backend/scripts
node enrollUser.js /path/to/fabric-samples/test-network
```

### 9. Start the Backend Server

```bash
cd backend
npm start

# You should see:
# Server listening on port 3000
```

### 10. Test the System

```bash
# Test health endpoint
curl http://localhost:3000/health

# Upload a test file
curl -X POST -F "file=@../tests/sample-files/hello.txt" http://localhost:3000/upload

# Copy the fileID from response, then verify
curl http://localhost:3000/verify/<fileID>
```

### 11. Run Tests

```bash
# Make scripts executable (Linux/macOS/WSL)
chmod +x tests/*.sh
chmod +x backend/scripts/*.sh

# Run tamper test
cd tests
./tamper-test.sh

# Run benchmark
cd ../backend/scripts
./benchmark.sh 10
```

## Troubleshooting

### Issue: "Cannot find module 'fabric-network'"

```bash
cd backend
npm install
```

### Issue: "Connection profile not found"

- Make sure you copied `connection-org1.json` from test-network to backend directory
- Check the path in `.env` file

### Issue: "Identity does not exist in wallet"

- Run the `enrollUser.js` script
- Or manually copy identity from test-network

### Issue: "MinIO connection refused"

```bash
# Check if MinIO is running
docker ps | grep minio

# If not, start it
docker start minio

# Or run a new container
docker run -d -p 9000:9000 -p 9001:9001 --name minio \
  -e "MINIO_ROOT_USER=minioadmin" -e "MINIO_ROOT_PASSWORD=minioadmin" \
  minio/minio server /data --console-address ":9001"
```

### Issue: "Chaincode not found"

```bash
# Redeploy chaincode
cd fabric-samples/test-network
./network.sh deployCC -ccn hashcc -ccp /path/to/chaincode/hash-chaincode -ccl javascript
```

### Issue: Bash scripts don't run on Windows

- Use WSL2 or Git Bash
- Or convert scripts to PowerShell/batch files

## Verification Checklist

- [ ] Docker is installed and running
- [ ] Node.js v18+ is installed
- [ ] MinIO container is running (port 9000, 9001)
- [ ] Fabric test-network is running (peer, orderer, CA containers)
- [ ] Chaincode is deployed (dev-peer container running)
- [ ] Connection profile copied to backend
- [ ] User identity enrolled in wallet
- [ ] Backend .env file configured
- [ ] Backend dependencies installed
- [ ] Backend server starts without errors
- [ ] Health endpoint returns 200 OK
- [ ] Upload endpoint works
- [ ] Verify endpoint works

## Next Steps

1. Run performance benchmarks
2. Test tamper detection
3. Create visualizations (graphs)
4. Write evaluation report

## Useful Commands

```bash
# View Docker containers
docker ps -a

# View Docker logs
docker logs <container_name>

# Stop all containers
docker stop $(docker ps -aq)

# Clean up Fabric network
cd fabric-samples/test-network
./network.sh down

# Restart everything
./network.sh up createChannel -c mychannel -ca
./network.sh deployCC -ccn hashcc -ccp /path/to/chaincode -ccl javascript

# View backend logs
cd backend
npm start

# Test with verbose logging
DEBUG=* npm start
```

## Additional Resources

- [Hyperledger Fabric Docs](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Test Network Tutorial](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
- [MinIO Docs](https://min.io/docs/minio/)
- [Node.js Fabric SDK](https://hyperledger.github.io/fabric-sdk-node/)
