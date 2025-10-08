# Fabric Bootstrap Instructions

**NOTE**: Follow official Hyperledger Fabric docs for downloading binaries and `fabric-samples` repo. This README shows commands to start a local test network used by this prototype.

## Steps

### 1. Download fabric-samples and binaries (official):

```bash
# from fabric docs (example)
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
# checkout a stable tag that matches binaries, e.g., v2.5.0 (check docs)
# then run the bootstrap script to download binaries & docker images
curl -sSL https://bit.ly/2ysbOFE | bash -s
```

### 2. Start the test network and create channel `mychannel`:

```bash
cd fabric-samples/test-network
./network.sh up createChannel -c mychannel -ca
```

### 3. Deploy chaincode

Deploy our chaincode `hashcc` located at `chaincode/hash-chaincode`:

```bash
# from fabric-samples/test-network
./network.sh deployCC -ccn hashcc -ccp ../../hyperledger-minio-prototype/chaincode/hash-chaincode -ccl javascript
```

### 4. Copy connection profile and wallet

After deploy, copy the generated connection profile(s) and wallets to `backend/` folder so the backend can connect. You can copy `organizations/peerOrganizations/org1.example.com/connection-org1.json` to `backend/connection-org1.json` and relevant certs or use the fabric-samples `test-network` wallet sample.

```bash
# Example commands to copy connection profile
cp organizations/peerOrganizations/org1.example.com/connection-org1.json ../../hyperledger-minio-prototype/backend/
```

## Important Notes

- Ensure your `connection-org1.json` path in `.env` is correct and wallet contains `appUser` identity (use test-network scripts to create enroll/admin and appUser).
- Use `asLocalhost: true` in gateway connect when running Fabric locally. Set to false for real remote setups.
- If Fabric deploy fails for chaincode, check Node.js versions and fabric chaincode compatibility.
