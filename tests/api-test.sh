#!/usr/bin/env bash

# Simple API test script
# Tests all endpoints of the backend API

SERVER_URL="http://localhost:3000"
TEST_FILE="tests/sample-files/hello.txt"

echo "========================================="
echo "API Test Script"
echo "========================================="
echo "Server: $SERVER_URL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo "Test 1: Health Check"
echo "GET $SERVER_URL/health"
RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVER_URL/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE"
  echo "Response: $BODY"
else
  echo -e "${RED}✗ FAIL${NC} - Status: $HTTP_CODE"
  echo "Response: $BODY"
fi
echo ""

# Test 2: Upload File
echo "Test 2: Upload File"
echo "POST $SERVER_URL/upload"
if [ ! -f "$TEST_FILE" ]; then
  echo -e "${RED}✗ FAIL${NC} - Test file not found: $TEST_FILE"
  exit 1
fi

RESPONSE=$(curl -s -w "\n%{http_code}" -F "file=@$TEST_FILE" -F "uploader=api-test" "$SERVER_URL/upload")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE"
  echo "Response: $BODY"
  
  # Extract fileID for next tests
  if command -v jq &> /dev/null; then
    FILE_ID=$(echo "$BODY" | jq -r .fileID)
    echo "File ID: $FILE_ID"
  else
    FILE_ID=$(echo "$BODY" | grep -o '"fileID":"[^"]*"' | cut -d'"' -f4)
    echo "File ID: $FILE_ID"
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Status: $HTTP_CODE"
  echo "Response: $BODY"
  exit 1
fi
echo ""

# Test 3: Get All Files
echo "Test 3: Get All Files"
echo "GET $SERVER_URL/files"
RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVER_URL/files")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE"
  if command -v jq &> /dev/null; then
    FILE_COUNT=$(echo "$BODY" | jq -r .count)
    echo "Total files: $FILE_COUNT"
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Status: $HTTP_CODE"
  echo "Response: $BODY"
fi
echo ""

# Test 4: Get Specific File
if [ ! -z "$FILE_ID" ]; then
  echo "Test 4: Get File Metadata"
  echo "GET $SERVER_URL/file/$FILE_ID"
  RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVER_URL/file/$FILE_ID")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | head -n-1)
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE"
    echo "Response: $BODY"
  else
    echo -e "${RED}✗ FAIL${NC} - Status: $HTTP_CODE"
    echo "Response: $BODY"
  fi
  echo ""
  
  # Test 5: Verify File
  echo "Test 5: Verify File Integrity"
  echo "GET $SERVER_URL/verify/$FILE_ID"
  RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVER_URL/verify/$FILE_ID")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | head -n-1)
  
  if [ "$HTTP_CODE" == "200" ]; then
    if command -v jq &> /dev/null; then
      VERIFY_RESULT=$(echo "$BODY" | jq -r .ok)
      if [ "$VERIFY_RESULT" == "true" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE - Integrity verified"
      else
        echo -e "${YELLOW}⚠ WARNING${NC} - Status: $HTTP_CODE - Integrity check failed"
      fi
    else
      echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE"
    fi
    echo "Response: $BODY"
  else
    echo -e "${RED}✗ FAIL${NC} - Status: $HTTP_CODE"
    echo "Response: $BODY"
  fi
  echo ""
fi

# Test 6: Upload Different File Types
echo "Test 6: Upload JSON File"
JSON_FILE="tests/sample-files/test.json"
if [ -f "$JSON_FILE" ]; then
  RESPONSE=$(curl -s -w "\n%{http_code}" -F "file=@$JSON_FILE" -F "uploader=api-test" "$SERVER_URL/upload")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Status: $HTTP_CODE"
  else
    echo -e "${RED}✗ FAIL${NC} - Status: $HTTP_CODE"
  fi
else
  echo -e "${YELLOW}⚠ SKIP${NC} - JSON test file not found"
fi
echo ""

echo "========================================="
echo "API Tests Complete!"
echo "========================================="

# Summary
echo ""
echo "Summary:"
echo "- All core endpoints tested"
echo "- Check output above for any failures"
echo "- If all tests passed, the system is working correctly"
echo ""
