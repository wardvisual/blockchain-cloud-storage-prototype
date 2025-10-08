#!/usr/bin/env bash

# Tamper detection test script
# This script uploads a file, verifies it, tampers with it, and verifies again

SERVER_URL="http://localhost:3000"
TEST_FILE="sample-files/hello.txt"
MINIO_ENDPOINT="http://127.0.0.1:9000"
BUCKET="files"

echo "====================================="
echo "Tamper Detection Test"
echo "====================================="

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Warning: jq is not installed. Install it for better JSON parsing."
  echo "On Ubuntu/Debian: sudo apt-get install jq"
  echo "On macOS: brew install jq"
  echo ""
fi

# Create sample file if it doesn't exist
if [ ! -f "$TEST_FILE" ]; then
  echo "Creating sample test file..."
  mkdir -p sample-files
  echo "Hello, World! This is the original content." > "$TEST_FILE"
fi

# Step 1: Upload file
echo "Step 1: Uploading file..."
UPLOAD_RESPONSE=$(curl -s -F "file=@$TEST_FILE" -F "uploader=test-user" "$SERVER_URL/upload")
echo "Upload response: $UPLOAD_RESPONSE"
echo ""

# Extract file details
if command -v jq &> /dev/null; then
  FILE_ID=$(echo $UPLOAD_RESPONSE | jq -r .fileID)
  OBJECT_NAME=$(echo $UPLOAD_RESPONSE | jq -r .objectName)
  ORIGINAL_HASH=$(echo $UPLOAD_RESPONSE | jq -r .sha256)
else
  FILE_ID=$(echo $UPLOAD_RESPONSE | grep -o '"fileID":"[^"]*"' | cut -d'"' -f4)
  OBJECT_NAME=$(echo $UPLOAD_RESPONSE | grep -o '"objectName":"[^"]*"' | cut -d'"' -f4)
  ORIGINAL_HASH=$(echo $UPLOAD_RESPONSE | grep -o '"sha256":"[^"]*"' | cut -d'"' -f4)
fi

echo "File ID: $FILE_ID"
echo "Object Name: $OBJECT_NAME"
echo "Original Hash: $ORIGINAL_HASH"
echo ""

# Step 2: Verify (should pass)
echo "Step 2: Verifying file integrity (should PASS)..."
VERIFY_RESPONSE=$(curl -s "$SERVER_URL/verify/$FILE_ID")
echo "Verify response: $VERIFY_RESPONSE"
echo ""

if command -v jq &> /dev/null; then
  VERIFY_RESULT=$(echo $VERIFY_RESPONSE | jq -r .ok)
else
  VERIFY_RESULT=$(echo $VERIFY_RESPONSE | grep -o '"ok":[^,]*' | cut -d':' -f2)
fi

if [ "$VERIFY_RESULT" == "true" ]; then
  echo "✓ Verification PASSED (as expected)"
else
  echo "✗ Verification FAILED (unexpected!)"
fi
echo ""

# Step 3: Tamper with file in MinIO
echo "Step 3: Tampering with file in MinIO..."
echo "NOTE: To actually tamper with the file, you need to:"
echo "1. Install MinIO client (mc): https://min.io/docs/minio/linux/reference/minio-mc.html"
echo "2. Configure mc alias: mc alias set local http://127.0.0.1:9000 minioadmin minioadmin"
echo "3. Replace the object with tampered content"
echo ""
echo "Example commands to tamper:"
echo "  echo 'TAMPERED CONTENT' > /tmp/tampered.txt"
echo "  mc cp /tmp/tampered.txt local/$BUCKET/$OBJECT_NAME"
echo ""

# Check if mc is available
if command -v mc &> /dev/null; then
  echo "MinIO client (mc) detected. Attempting to tamper with file..."
  
  # Create tampered file
  TAMPERED_FILE="/tmp/tampered-${FILE_ID}.txt"
  echo "TAMPERED CONTENT - This file has been modified!" > "$TAMPERED_FILE"
  
  # Configure mc alias (if not already configured)
  mc alias set local "$MINIO_ENDPOINT" minioadmin minioadmin 2>/dev/null
  
  # Replace file in MinIO
  mc cp "$TAMPERED_FILE" "local/$BUCKET/$OBJECT_NAME" 2>/dev/null
  
  if [ $? -eq 0 ]; then
    echo "✓ File tampered successfully"
    echo ""
    
    # Step 4: Verify again (should fail)
    echo "Step 4: Verifying file integrity after tampering (should FAIL)..."
    sleep 2  # Wait a moment for MinIO to update
    
    VERIFY_RESPONSE_2=$(curl -s "$SERVER_URL/verify/$FILE_ID")
    echo "Verify response: $VERIFY_RESPONSE_2"
    echo ""
    
    if command -v jq &> /dev/null; then
      VERIFY_RESULT_2=$(echo $VERIFY_RESPONSE_2 | jq -r .ok)
      COMPUTED_HASH=$(echo $VERIFY_RESPONSE_2 | jq -r .computed)
    else
      VERIFY_RESULT_2=$(echo $VERIFY_RESPONSE_2 | grep -o '"ok":[^,]*' | cut -d':' -f2)
      COMPUTED_HASH=$(echo $VERIFY_RESPONSE_2 | grep -o '"computed":"[^"]*"' | cut -d'"' -f4)
    fi
    
    echo "Original Hash:  $ORIGINAL_HASH"
    echo "Computed Hash:  $COMPUTED_HASH"
    echo ""
    
    if [ "$VERIFY_RESULT_2" == "false" ]; then
      echo "✓ Verification FAILED (as expected - tampering detected!)"
      echo "✓ TEST PASSED: System successfully detected tampering"
    else
      echo "✗ Verification PASSED (unexpected - tampering not detected!)"
      echo "✗ TEST FAILED: System did not detect tampering"
    fi
  else
    echo "✗ Failed to tamper with file. Check MinIO connection."
  fi
else
  echo "MinIO client (mc) not installed. Skipping automated tampering."
  echo "Install mc to enable automated tampering tests:"
  echo "  wget https://dl.min.io/client/mc/release/linux-amd64/mc"
  echo "  chmod +x mc"
  echo "  sudo mv mc /usr/local/bin/"
fi

echo ""
echo "====================================="
echo "Tamper Detection Test Complete"
echo "====================================="
