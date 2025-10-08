# Backend API - Setup Guide

## Required Files

Before starting the backend server, you need two critical files:

### 1. Connection Profile (`connection-org1.json`)

This file contains the network configuration for connecting to Hyperledger Fabric.

#### Option A: Copy from Running Fabric Network (Recommended)

If you have Hyperledger Fabric test-network running:

```bash
# From fabric-samples/test-network directory
cp organizations/peerOrganizations/org1.example.com/connection-org1.json \
   /path/to/prototype/backend/connection-org1.json
```

#### Option B: Use the Example Template

A template file `connection-org1.json.example` is provided. However, you'll need to replace the placeholder certificates with actual ones from your Fabric network.

**To get the actual certificates:**

1. Start your Fabric test network:

```bash
cd fabric-samples/test-network
./network.sh up createChannel -c mychannel -ca
```

2. Copy the generated connection profile:

```bash
cp organizations/peerOrganizations/org1.example.com/connection-org1.json \
   /path/to/your/backend/
```

### 2. Wallet Directory

The wallet stores user identities for blockchain transactions.

#### Create Wallet with User Identity

Run the enrollment script:

```bash
cd backend/scripts
node enrollUser.js /path/to/fabric-samples/test-network
```

This will:

- Create a `wallet/` directory in `backend/`
- Import the `appUser` identity from your Fabric network
- Set up credentials for blockchain transactions

## Environment Configuration

1. Copy the environment template:

```bash
cp .env.example .env
```

2. Edit `.env` to match your setup:

```env
# MinIO Configuration
MINIO_ENDPOINT=127.0.0.1
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=files

# Fabric Configuration
FABRIC_CONNECTION=./connection-org1.json    # ← Must exist
WALLET_PATH=./wallet                         # ← Must exist with appUser
FABRIC_USER=appUser
CHANNEL_NAME=mychannel
CHAINCODE_NAME=hashcc

# Server Configuration
PORT=3000
```

## Installation

Install dependencies:

```bash
npm install
```

## Starting the Server

```bash
npm start
```

The server will be available at `http://localhost:3000`

## Verification Checklist

Before starting, verify:

- [ ] `connection-org1.json` exists in `backend/` directory
- [ ] `wallet/` directory exists with `appUser` identity
- [ ] `.env` file is configured correctly
- [ ] MinIO is running (`docker ps | grep minio`)
- [ ] Fabric network is running (`docker ps` shows peer, orderer, CA containers)
- [ ] Chaincode is deployed (`docker ps | grep dev-peer`)

## Testing

Once the server is running:

```bash
# Health check
curl http://localhost:3000/health

# Upload a file
curl -F "file=@../tests/sample-files/hello.txt" http://localhost:3000/upload

# Verify file (replace FILE_ID with actual ID from upload response)
curl http://localhost:3000/verify/FILE_ID
```

## Troubleshooting

### "Connection profile not found"

- Ensure `connection-org1.json` exists in the `backend/` directory
- Check the path in your `.env` file: `FABRIC_CONNECTION=./connection-org1.json`

### "Identity does not exist in wallet"

- Run the enrollment script: `node scripts/enrollUser.js /path/to/test-network`
- Verify `wallet/appUser/` directory exists

### "Failed to connect to Fabric gateway"

- Check if Fabric network is running: `docker ps`
- Verify peer containers are healthy
- Check if the connection profile has correct URLs

### "MinIO connection refused"

- Start MinIO: `docker run -d -p 9000:9000 -p 9001:9001 --name minio ...`
- Check MinIO endpoint in `.env`

## API Endpoints

| Method | Endpoint          | Description                          |
| ------ | ----------------- | ------------------------------------ |
| GET    | `/health`         | Health check                         |
| POST   | `/upload`         | Upload file and record on blockchain |
| GET    | `/verify/:fileID` | Verify file integrity                |
| GET    | `/files`          | List all files                       |
| GET    | `/file/:fileID`   | Get file metadata                    |

## Directory Structure

```
backend/
├── package.json
├── .env                        ← Your configuration
├── connection-org1.json        ← Required: Fabric connection profile
├── wallet/                     ← Required: User identities
│   └── appUser/
├── src/
│   ├── app.js                  ← Main Express server
│   ├── fabricClient.js         ← Fabric integration
│   ├── minioClient.js          ← MinIO integration
│   └── utils.js                ← Utilities
└── scripts/
    ├── benchmark.sh            ← Performance testing
    └── enrollUser.js           ← Identity enrollment
```

## Next Steps

1. Set up Hyperledger Fabric network (see `../fabric/README-FABRIC.md`)
2. Deploy chaincode to the network
3. Copy connection profile and enroll user (as described above)
4. Start backend server
5. Run tests to verify everything works

For more details, see the main [README.md](../README.md) in the project root.
