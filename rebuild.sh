#!/bin/bash
echo "=== Rebuilding Homepage Container ==="
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

echo "Building..."
if ! docker build -t homepage .; then
    echo "BUILD FAILED!"
    exit 1
fi

echo "Starting..."
# Create data directory if it doesn't exist
mkdir -p "$(pwd)/data"
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  -v "$(pwd)/data:/var/www/site/data" \
  homepage

echo "Status:"
docker ps -f name=homepage
echo
echo "Logs:"
docker logs homepage
echo
echo "Testing debug endpoint..."
sleep 3
curl -s http://localhost/debug.php || echo "Debug endpoint not ready yet"
