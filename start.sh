#!/usr/bin/env bash

# Quick start script for the prototype
# This script helps set up the environment

echo "========================================="
echo "Hyperledger Fabric + MinIO Prototype"
echo "Quick Start Script"
echo "========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
  echo "✗ Docker not found. Please install Docker first."
  exit 1
fi
echo "✓ Docker found"

# Check Node.js
if ! command -v node &> /dev/null; then
  echo "✗ Node.js not found. Please install Node.js v18+ first."
  exit 1
fi
NODE_VERSION=$(node --version)
echo "✓ Node.js found: $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
  echo "✗ npm not found. Please install npm first."
  exit 1
fi
NPM_VERSION=$(npm --version)
echo "✓ npm found: $NPM_VERSION"

echo ""
echo "========================================="
echo "Step 1: Starting MinIO"
echo "========================================="

# Check if MinIO is already running
if docker ps | grep -q minio; then
  echo "✓ MinIO is already running"
else
  echo "Starting MinIO container..."
  docker run -d \
    -p 9000:9000 \
    -p 9001:9001 \
    --name minio \
    -e "MINIO_ROOT_USER=minioadmin" \
    -e "MINIO_ROOT_PASSWORD=minioadmin" \
    minio/minio server /data --console-address ":9001"
  
  if [ $? -eq 0 ]; then
    echo "✓ MinIO started successfully"
    echo "  - API: http://localhost:9000"
    echo "  - Console: http://localhost:9001"
    echo "  - Login: minioadmin / minioadmin"
  else
    echo "✗ Failed to start MinIO"
  fi
fi

echo ""
echo "========================================="
echo "Step 2: Installing Backend Dependencies"
echo "========================================="

cd backend

if [ ! -d "node_modules" ]; then
  echo "Installing npm packages..."
  npm install
  echo "✓ Dependencies installed"
else
  echo "✓ Dependencies already installed"
fi

# Check .env file
if [ ! -f ".env" ]; then
  echo "Creating .env file from template..."
  cp ../.env.example .env
  echo "✓ .env file created"
  echo "⚠ Please edit .env file with your Fabric network configuration"
else
  echo "✓ .env file exists"
fi

cd ..

echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Set up Hyperledger Fabric test network:"
echo "   See fabric/README-FABRIC.md for instructions"
echo ""
echo "2. Deploy the chaincode:"
echo "   ./network.sh deployCC -ccn hashcc -ccp /path/to/chaincode -ccl javascript"
echo ""
echo "3. Create user identity:"
echo "   cd backend/scripts"
echo "   node enrollUser.js /path/to/fabric-samples/test-network"
echo ""
echo "4. Start the backend server:"
echo "   cd backend"
echo "   npm start"
echo ""
echo "5. Test the system:"
echo "   curl http://localhost:3000/health"
echo "   curl -F 'file=@tests/sample-files/hello.txt' http://localhost:3000/upload"
echo ""
echo "For detailed setup instructions, see SETUP.md"
echo ""
echo "========================================="
