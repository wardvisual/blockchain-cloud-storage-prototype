# Quick Reference Guide

## 📂 Project Structure Overview

```
prototype/
├── 📄 README.md                    ← Start here
├── 📄 SETUP.md                     ← Detailed setup guide
├── 📄 CHECKLIST.md                 ← Implementation & testing checklist
├── 📄 hyperledger_fabric_min_io_prototype_readme.md  ← Original spec
│
├── ⚙️ Configuration Files
│   ├── .env.example                ← Environment variables template
│   ├── .gitignore                  ← Git ignore rules
│   ├── docker-compose.yml          ← MinIO container setup
│   ├── package.json                ← Root scripts
│   └── start.sh                    ← Quick start helper
│
├── 📁 chaincode/                   ← Hyperledger Fabric Smart Contract
│   └── hash-chaincode/
│       ├── package.json            ← Chaincode dependencies
│       ├── index.js                ← Chaincode entry point
│       └── lib/
│           └── chaincode.js        ← Smart contract logic
│
├── 📁 backend/                     ← Node.js REST API Server
│   ├── package.json                ← Backend dependencies
│   ├── .env                        ← Backend configuration
│   ├── src/
│   │   ├── app.js                  ← Express server & API routes
│   │   ├── fabricClient.js         ← Fabric SDK integration
│   │   ├── minioClient.js          ← MinIO SDK integration
│   │   └── utils.js                ← Utility functions
│   └── scripts/
│       ├── benchmark.sh            ← Performance testing
│       └── enrollUser.js           ← User enrollment helper
│
├── 📁 tests/                       ← Testing Scripts
│   ├── api-test.sh                 ← API endpoint tests
│   ├── tamper-test.sh              ← Tamper detection test
│   └── sample-files/
│       ├── hello.txt               ← Small test file
│       ├── medium.txt              ← Medium test file
│       └── test.json               ← JSON test file
│
├── 📁 docs/                        ← Documentation
│   └── evaluation-plan.md          ← Testing methodology
│
└── 📁 fabric/                      ← Fabric Setup Instructions
    └── README-FABRIC.md            ← Network setup guide
```

---

## 🎯 Quick Start Commands

### Setup

```bash
# 1. Start MinIO
docker-compose up -d

# 2. Install dependencies
cd backend && npm install
cd ../chaincode/hash-chaincode && npm install

# 3. Set up Fabric (see fabric/README-FABRIC.md)
# Follow Fabric setup instructions...

# 4. Enroll user
cd backend/scripts
node enrollUser.js /path/to/fabric-samples/test-network

# 5. Start backend
cd ..
npm start
```

### Testing

```bash
# Health check
curl http://localhost:3000/health

# Upload file
curl -F "file=@tests/sample-files/hello.txt" http://localhost:3000/upload

# Verify file (replace FILE_ID)
curl http://localhost:3000/verify/FILE_ID

# List all files
curl http://localhost:3000/files

# Run full API test
bash tests/api-test.sh

# Run tamper test
bash tests/tamper-test.sh

# Run benchmark
bash backend/scripts/benchmark.sh 10
```

---

## 🔌 API Endpoints

| Method | Endpoint          | Description      | Request               | Response                  |
| ------ | ----------------- | ---------------- | --------------------- | ------------------------- |
| GET    | `/health`         | Health check     | -                     | `{ status, timestamp }`   |
| POST   | `/upload`         | Upload file      | `multipart/form-data` | `{ fileID, sha256, ... }` |
| GET    | `/verify/:fileID` | Verify integrity | -                     | `{ ok, match, ... }`      |
| GET    | `/files`          | List all files   | -                     | `{ count, files[] }`      |
| GET    | `/file/:fileID`   | Get metadata     | -                     | `{ fileID, record }`      |

---

## 🏗️ System Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP/REST
       ↓
┌─────────────────────────────────────────┐
│         Backend API (Express)            │
│  ┌──────────────┐  ┌─────────────────┐  │
│  │ Upload File  │  │  Verify File    │  │
│  │  Compute     │  │  Retrieve from  │  │
│  │  SHA-256     │  │  MinIO & check  │  │
│  └──────┬───────┘  └─────────┬───────┘  │
└─────────┼──────────────────┬─┼──────────┘
          │                  │ │
          │                  │ │
    ┌─────↓─────┐      ┌────↓─↓─────┐
    │   MinIO   │      │  Hyperledger │
    │  Object   │      │    Fabric    │
    │  Storage  │      │  Blockchain  │
    │           │      │              │
    │  Stores:  │      │   Stores:    │
    │  - Files  │      │   - Hashes   │
    │  - Binary │      │   - Metadata │
    └───────────┘      └──────────────┘
```

---

## 🔐 Security Model

### Data Flow

1. **Upload**: File → Compute SHA-256 → Store in MinIO → Record hash on blockchain
2. **Verify**: Retrieve from MinIO → Recompute SHA-256 → Compare with blockchain

### Integrity Guarantees

- ✅ **Immutability**: Blockchain records cannot be altered
- ✅ **Tamper Detection**: Any file modification detected via hash mismatch
- ✅ **Audit Trail**: All uploads timestamped and traceable
- ✅ **Cryptographic Security**: SHA-256 hashing

---

## 🧪 Testing Scenarios

### 1. Normal Operation

- Upload file → Verify (should pass ✅)

### 2. Tamper Detection

- Upload file → Modify in MinIO → Verify (should fail ❌)

### 3. Performance

- Measure latency: upload & verify operations
- Measure throughput: concurrent users
- Measure storage: blockchain overhead

### 4. Scalability

- Test with increasing file sizes
- Test with increasing number of files
- Test with multiple concurrent users

---

## 📊 Key Metrics to Collect

### Performance

- **Latency**: Time for upload/verify (ms)
- **Throughput**: Transactions per second (TPS)
- **Success Rate**: % of successful operations

### Storage

- **Blockchain Size**: Growth per file
- **Overhead Ratio**: Ledger size / File size
- **MinIO Usage**: Actual storage consumption

### Security

- **Tamper Detection Rate**: Should be 100%
- **False Positive Rate**: Should be 0%

---

## 🛠️ Troubleshooting Quick Reference

| Problem                        | Solution                                          |
| ------------------------------ | ------------------------------------------------- |
| "Docker command not found"     | Install Docker Desktop                            |
| "Connection profile not found" | Copy from fabric-samples/test-network             |
| "Identity not in wallet"       | Run `enrollUser.js` script                        |
| "MinIO connection refused"     | Check `docker ps` and restart MinIO               |
| "Chaincode not found"          | Redeploy with `network.sh deployCC`               |
| "Port already in use"          | Change port in `.env` or stop conflicting service |
| Scripts won't execute          | Run `chmod +x` on .sh files                       |

---

## 📝 Environment Variables

```env
# MinIO Configuration
MINIO_ENDPOINT=127.0.0.1
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=files

# Fabric Configuration
FABRIC_CONNECTION=./connection-org1.json
WALLET_PATH=./wallet
FABRIC_USER=appUser
CHANNEL_NAME=mychannel
CHAINCODE_NAME=hashcc

# Server Configuration
PORT=3000
```

---

## 🎓 Components

### Implementation (Complete ✅)

- [x] Chaincode smart contract
- [x] Backend API server
- [x] MinIO integration
- [x] Fabric integration
- [x] Testing scripts

### Documentation (Complete ✅)

- [x] README with overview
- [x] SETUP guide
- [x] API documentation
- [x] Evaluation plan
- [x] Code comments

---

## 📚 Additional Resources

### Learn More

- [Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/)
- [MinIO Documentation](https://min.io/docs/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Blockchain Security](https://www.blockchain-council.org/blockchain/blockchain-security/)

### Tools

- [Postman](https://www.postman.com/) - API testing
- [wrk](https://github.com/wg/wrk) - HTTP benchmarking
- [Grafana](https://grafana.com/) - Monitoring
- [MinIO Client (mc)](https://min.io/docs/minio/linux/reference/minio-mc.html)

---

## 💡 Tips & Best Practices

1. **Always check prerequisites** before starting
2. **Read error messages carefully** - they usually tell you what's wrong
3. **Use Docker logs** to debug container issues: `docker logs <container>`
4. **Test incrementally** - don't wait until everything is done
5. **Document as you go** - write down what works and what doesn't
6. **Keep backups** - especially of working configurations
7. **Version control** - commit working code frequently

---

## ✅ Pre-Demo Checklist

Before demonstrating the system:

- [ ] All Docker containers running
- [ ] Backend server responsive
- [ ] Sample files ready
- [ ] Test scripts executable
- [ ] Results directories created
- [ ] Logs visible and clear
- [ ] Browser tabs ready (MinIO console, etc.)
- [ ] Presentation slides prepared
- [ ] Backup plan if something fails

---
