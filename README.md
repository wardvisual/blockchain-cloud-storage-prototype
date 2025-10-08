# Blockchain-Based Cloud Storage System

A distributed cloud storage solution combining **Hyperledger Fabric** blockchain technology with **MinIO** object storage for enhanced data integrity verification and auditability.

## 🎯 Overview

This project demonstrates a decentralized storage architecture where:

1. Files are uploaded via REST API
2. SHA-256 cryptographic hashes are computed
3. Files are stored in MinIO object storage
4. Hashes and metadata are immutably recorded on Hyperledger Fabric blockchain
5. File integrity can be verified at any time by comparing hashes

## ✨ Key Features

- **🔐 Data Integrity**: Cryptographic hash verification ensures files haven't been tampered with
- **📜 Immutable Audit Trail**: All file operations recorded on blockchain
- **🗄️ Decentralized Storage**: Combines blockchain ledger with object storage
- **🔍 Tamper Detection**: Automatic detection of unauthorized file modifications
- **📊 Transparent History**: Complete audit log of all file operations
- **🚀 RESTful API**: Easy integration with existing applications

## 📁 Project Structure

```
prototype/
├── README.md                           # Project documentation
├── LICENSE                             # MIT License
├── .env.example                        # Environment configuration template
├── fabric/                             # Hyperledger Fabric setup
│   └── README-FABRIC.md
├── chaincode/                          # Smart contracts
│   └── hash-chaincode/
│       ├── package.json
│       ├── index.js
│       └── lib/chaincode.js
├── backend/                            # Node.js API server
│   ├── package.json
│   ├── .env
│   ├── src/
│   │   ├── app.js                      # Express application
│   │   ├── fabricClient.js             # Blockchain integration
│   │   ├── minioClient.js              # Storage integration
│   │   └── utils.js                    # Utilities
│   └── scripts/
│       ├── benchmark.sh                # Performance testing
│       └── enrollUser.js               # User enrollment
├── tests/                              # Test suite
│   ├── api-test.sh                     # API endpoint tests
│   ├── tamper-test.sh                  # Integrity tests
│   └── sample-files/
└── docs/                               # Documentation
    └── evaluation-plan.md
```

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** - Container runtime
- **Node.js v18+** - JavaScript runtime
- **Git** - Version control
- **cURL** - HTTP client for testing
- **Linux/macOS/Windows WSL** - Development environment

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/wardvisual/blockchain-cloud-storage-prototype.git
cd blockchain-cloud-storage-prototype
```

2. **Set up Hyperledger Fabric**

Follow instructions in [`fabric/README-FABRIC.md`](fabric/README-FABRIC.md):

```bash
# Download Fabric samples and binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s

# Start test network
cd fabric-samples/test-network
./network.sh up createChannel -c mychannel -ca

# Deploy chaincode
./network.sh deployCC -ccn hashcc -ccp ../../chaincode/hash-chaincode -ccl javascript
```

3. **Start MinIO**

```bash
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  minio/minio server /data --console-address ":9001"
```

4. **Configure and start backend**

```bash
cd backend
cp ../.env.example .env
# Edit .env with your Fabric connection details
npm install
npm start
```

Server will be available at `http://localhost:3000`

## 📡 API Reference

### Health Check

```bash
GET /health
```

### Upload File

```bash
POST /upload
Content-Type: multipart/form-data

curl -X POST -F "file=@document.pdf" -F "uploader=user1" \
  http://localhost:3000/upload
```

**Response:**

```json
{
  "ok": true,
  "fileID": "550e8400-e29b-41d4-a716-446655440000",
  "objectName": "550e8400-e29b-41d4-a716-446655440000-document.pdf",
  "sha256": "3a5c7...",
  "uploader": "user1",
  "metadata": {
    "originalName": "document.pdf",
    "mime": "application/pdf",
    "size": 2048576
  }
}
```

### Verify File Integrity

```bash
GET /verify/:fileID

curl http://localhost:3000/verify/550e8400-e29b-41d4-a716-446655440000
```

**Response:**

```json
{
  "ok": true,
  "fileID": "550e8400-e29b-41d4-a716-446655440000",
  "match": true,
  "record": {
    "sha256": "3a5c7...",
    "timestamp": "2025-10-07T12:00:00.000Z"
  },
  "computed": "3a5c7...",
  "message": "File integrity verified"
}
```

### List All Files

```bash
GET /files
```

### Get File Metadata

```bash
GET /file/:fileID
```

## 🧪 Testing

### Run API Tests

```bash
cd tests
chmod +x api-test.sh
./api-test.sh
```

### Test Tamper Detection

```bash
chmod +x tamper-test.sh
./tamper-test.sh
```

### Performance Benchmark

```bash
cd backend/scripts
chmod +x benchmark.sh
./benchmark.sh 50  # Run 50 iterations
```

## 🏗️ Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│     REST API Server         │
│  (Express.js Backend)       │
└──────┬──────────────┬───────┘
       │              │
       ▼              ▼
┌──────────────┐  ┌──────────────┐
│   MinIO      │  │  Hyperledger │
│   Storage    │  │    Fabric    │
│              │  │  Blockchain  │
└──────────────┘  └──────────────┘
  (File Data)     (Hash Records)
```

## 🔐 Security

- **Cryptographic Hashing**: SHA-256 for file integrity
- **Immutable Records**: Blockchain prevents data tampering
- **Audit Trail**: Complete history of all operations
- **Access Control**: Fabric MSP for identity management
- **Tamper Detection**: Automatic verification of file integrity

## 📊 Performance

- **Upload Latency**: ~500-2000ms (varies by file size)
- **Verification Latency**: ~200-500ms
- **Throughput**: ~100-500 transactions/second
- **Storage Overhead**: ~250-500 bytes per file (blockchain metadata only)

## 🔧 Configuration

Edit `.env` file in `backend/` directory:

```env
# MinIO Configuration
MINIO_ENDPOINT=127.0.0.1
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=files

# Hyperledger Fabric Configuration
FABRIC_CONNECTION=./connection-org1.json
WALLET_PATH=./wallet
FABRIC_USER=appUser
CHANNEL_NAME=mychannel
CHAINCODE_NAME=hashcc

# Server Configuration
PORT=3000
```

## 🛠️ Development

### Project Status

This is an **initial setup and proof-of-concept** demonstrating the integration of blockchain technology with cloud storage. The core functionality is implemented and working, but this is an early-stage project.

### Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

### Roadmap

- [ ] Web-based UI interface
- [ ] Multi-user authentication
- [ ] File encryption at rest
- [ ] Advanced access control policies
- [ ] Performance optimizations
- [ ] Multi-node Fabric network setup
- [ ] Comprehensive test coverage

## 📚 Technology Stack

- **Blockchain**: Hyperledger Fabric 2.5+
- **Object Storage**: MinIO
- **Backend**: Node.js, Express.js
- **Smart Contracts**: JavaScript (Fabric Contract API)
- **SDKs**: Fabric Node SDK, MinIO JavaScript SDK
- **Hashing**: SHA-256 (crypto module)

## 🐛 Troubleshooting

**Connection profile not found**

- Ensure Fabric network is running
- Copy `connection-org1.json` to backend folder

**Identity does not exist**

- Run enrollment script: `node backend/scripts/enrollUser.js`
- Check wallet path in `.env`

**MinIO connection refused**

- Verify container is running: `docker ps | grep minio`
- Check endpoint and credentials in `.env`

**Chaincode not deployed**

- Check deployed chaincodes: `docker ps | grep dev-peer`
- Redeploy using test network scripts

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**wardvisual** - [GitHub Profile](https://github.com/wardvisual)

## 🌟 Acknowledgments

- Hyperledger Fabric community
- MinIO team
- Open source contributors

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/wardvisual/blockchain-cloud-storage-prototype/issues)
- **Documentation**: Check `/docs` folder
- **Community**: Hyperledger Discord/Slack

---

**Note**: This is an early-stage project demonstrating blockchain-based storage concepts. It's suitable for development, testing, and learning purposes. Production deployment would require additional security hardening, monitoring, and optimization.

⭐ **Star this repo if you find it interesting!**
