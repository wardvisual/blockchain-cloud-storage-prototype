# Blockchain-Based Cloud Storage

A proof-of-concept demonstrating blockchain integration with cloud object storage for file integrity verification.

## 🎯 What This Does

- Upload files via REST API
- Store files in MinIO object storage
- Record cryptographic hashes on Hyperledger Fabric blockchain
- Verify file integrity by comparing stored vs current hash

## 🏗️ Tech Stack

- **Blockchain**: Hyperledger Fabric
- **Storage**: MinIO
- **Backend**: Node.js + Express
- **Smart Contract**: JavaScript (Fabric Contract API)

## 📁 Structure

```
├── chaincode/          # Fabric smart contracts
├── backend/            # REST API server
├── tests/              # Test scripts
└── docs/               # Documentation (private)
```

## 🚀 Quick Start

1. **Prerequisites**: Docker, Node.js 18+, Fabric binaries

2. **Setup Hyperledger Fabric**

```bash
# Download fabric-samples and start test network
# See fabric/README-FABRIC.md for details
```

3. **Start MinIO**

```bash
docker-compose up -d
```

4. **Install & Run Backend**

```bash
cd backend
npm install
npm start
```

## 📡 API

| Endpoint      | Method | Description      |
| ------------- | ------ | ---------------- |
| `/health`     | GET    | Health check     |
| `/upload`     | POST   | Upload file      |
| `/verify/:id` | GET    | Verify integrity |
| `/files`      | GET    | List files       |

## 🧪 Testing

```bash
# Upload test file
curl -F "file=@test.txt" http://localhost:3000/upload

# Verify integrity
curl http://localhost:3000/verify/{fileID}
```

## 🔐 Security Features

- SHA-256 hashing
- Immutable blockchain records
- Tamper detection

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 👤 Author

[wardvisual](https://github.com/wardvisual)

---

**Note**: This is an exploratory project demonstrating blockchain concepts. Not production-ready.
