#!/bin/bash
echo "=== Rebuilding Homepage Container ==="
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

echo "Building..."
if ! docker build -t homepage .; then
    echo "BUILD FAILED!"
    exit 1
fi

echo "Setting up persistent data directory..."
# Create data directory with proper permissions
mkdir -p "$(pwd)/data/scan"
mkdir -p "$(pwd)/data"
# Set permissions for nginx user (82:82 in Alpine)
sudo chown -R 82:82 "$(pwd)/data" 2>/dev/null || chown -R www-data:www-data "$(pwd)/data" 2>/dev/null || true
sudo chmod -R 755 "$(pwd)/data"

echo "Starting..."
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
