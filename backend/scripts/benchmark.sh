#!/usr/bin/env bash

# Benchmark script for testing upload and verify endpoints
# Usage: ./benchmark.sh [number_of_iterations]

ITERATIONS=${1:-10}
TEST_FILE="../tests/sample-files/hello.txt"
SERVER_URL="http://localhost:3000"

echo "====================================="
echo "Benchmark Test - Hyperledger + MinIO"
echo "====================================="
echo "Iterations: $ITERATIONS"
echo "Test File: $TEST_FILE"
echo "Server: $SERVER_URL"
echo "====================================="

if [ ! -f "$TEST_FILE" ]; then
  echo "Error: Test file not found at $TEST_FILE"
  echo "Creating sample test file..."
  mkdir -p ../tests/sample-files
  echo "Hello, this is a test file for benchmarking." > "$TEST_FILE"
fi

# Check if server is running
echo "Checking server health..."
curl -s "$SERVER_URL/health" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Server is not running at $SERVER_URL"
  exit 1
fi
echo "Server is running ✓"
echo ""

# Upload benchmark
echo "=== Upload Benchmark ==="
echo "Testing upload latency ($ITERATIONS iterations)..."
UPLOAD_TIMES=()
LAST_FILE_ID=""

for i in $(seq 1 $ITERATIONS); do
  echo -n "Upload $i/$ITERATIONS: "
  
  START=$(date +%s%N)
  RESPONSE=$(curl -s -F "file=@$TEST_FILE" -F "uploader=benchmark-user" "$SERVER_URL/upload")
  END=$(date +%s%N)
  
  # Calculate latency in milliseconds
  LATENCY=$(( (END - START) / 1000000 ))
  UPLOAD_TIMES+=($LATENCY)
  
  # Extract fileID for verify test
  if [ $i -eq 1 ]; then
    LAST_FILE_ID=$(echo $RESPONSE | grep -o '"fileID":"[^"]*"' | cut -d'"' -f4)
  fi
  
  echo "${LATENCY}ms"
  sleep 0.5
done

# Calculate upload statistics
UPLOAD_TOTAL=0
UPLOAD_MIN=${UPLOAD_TIMES[0]}
UPLOAD_MAX=${UPLOAD_TIMES[0]}

for time in "${UPLOAD_TIMES[@]}"; do
  UPLOAD_TOTAL=$((UPLOAD_TOTAL + time))
  if [ $time -lt $UPLOAD_MIN ]; then UPLOAD_MIN=$time; fi
  if [ $time -gt $UPLOAD_MAX ]; then UPLOAD_MAX=$time; fi
done

UPLOAD_AVG=$((UPLOAD_TOTAL / ITERATIONS))

echo ""
echo "Upload Statistics:"
echo "  Average: ${UPLOAD_AVG}ms"
echo "  Min: ${UPLOAD_MIN}ms"
echo "  Max: ${UPLOAD_MAX}ms"
echo ""

# Verify benchmark
if [ ! -z "$LAST_FILE_ID" ]; then
  echo "=== Verify Benchmark ==="
  echo "Testing verify latency ($ITERATIONS iterations)..."
  VERIFY_TIMES=()
  
  for i in $(seq 1 $ITERATIONS); do
    echo -n "Verify $i/$ITERATIONS: "
    
    START=$(date +%s%N)
    curl -s "$SERVER_URL/verify/$LAST_FILE_ID" > /dev/null
    END=$(date +%s%N)
    
    # Calculate latency in milliseconds
    LATENCY=$(( (END - START) / 1000000 ))
    VERIFY_TIMES+=($LATENCY)
    
    echo "${LATENCY}ms"
    sleep 0.5
  done
  
  # Calculate verify statistics
  VERIFY_TOTAL=0
  VERIFY_MIN=${VERIFY_TIMES[0]}
  VERIFY_MAX=${VERIFY_TIMES[0]}
  
  for time in "${VERIFY_TIMES[@]}"; do
    VERIFY_TOTAL=$((VERIFY_TOTAL + time))
    if [ $time -lt $VERIFY_MIN ]; then VERIFY_MIN=$time; fi
    if [ $time -gt $VERIFY_MAX ]; then VERIFY_MAX=$time; fi
  done
  
  VERIFY_AVG=$((VERIFY_TOTAL / ITERATIONS))
  
  echo ""
  echo "Verify Statistics:"
  echo "  Average: ${VERIFY_AVG}ms"
  echo "  Min: ${VERIFY_MIN}ms"
  echo "  Max: ${VERIFY_MAX}ms"
fi

echo ""
echo "====================================="
echo "Benchmark Complete!"
echo "====================================="
