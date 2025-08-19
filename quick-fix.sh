#!/bin/bash

# Quick fix script - bypasses persistent storage permission issues
# This creates a working scan system that saves to the container only (non-persistent)

echo "=== Quick Fix for Scan Issues ==="
echo "This will create a working scan system (non-persistent for now)"

# Stop current container
echo "Stopping current container..."
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

# Create a version that uses container-only storage (works around permission issues)
echo "Building temporary container without persistent storage..."
docker build -t homepage .

echo "Starting container without volume mount (temporary fix)..."
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e RUN_SCAN_ON_START=1 \
  -e SCAN_INTERVAL=0 \
  homepage

echo "Waiting for container to start..."
sleep 5

echo "Container status:"
docker ps -f name=homepage

echo ""
echo "Checking if scan works now..."
sleep 3
curl -s http://localhost/debug.php | jq '.scan_files'

echo ""
echo "Triggering manual scan..."
curl -s "http://localhost/run-scan.php?immediate=1" | jq '.'

echo ""
echo "Final check:"
curl -s http://localhost/debug.php | jq '.services_files'

echo ""
echo "If this works, we can then add persistent storage back with proper fixes."
