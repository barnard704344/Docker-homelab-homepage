#!/bin/bash

# Universal setup script that handles all Docker homelab homepage setup
# This script can be run even without execute permissions using: bash setup.sh

echo "=== Docker Homelab Homepage Setup ==="
echo "Setting up container with persistent storage..."

# Make all scripts executable
echo "Making scripts executable..."
chmod +x rebuild.sh run.sh scan.sh parse-scan.sh start.sh 2>/dev/null || true

# Setup data directory with proper permissions
echo "Setting up persistent data directory..."
mkdir -p ./data/scan
mkdir -p ./data

# Try to set nginx permissions (works on most systems)
if command -v sudo >/dev/null 2>&1; then
    echo "Setting permissions using sudo..."
    sudo chown -R 82:82 ./data 2>/dev/null || \
    sudo chown -R 33:33 ./data 2>/dev/null || \
    sudo chown -R www-data:www-data ./data 2>/dev/null || \
    echo "Could not set user permissions, trying generic permissions..."
    sudo chmod -R 777 ./data
else
    echo "No sudo available, setting generic permissions..."
    chmod -R 777 ./data 2>/dev/null || true
fi

echo "Stopping existing container..."
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

echo "Building new image..."
if ! docker build -t homepage .; then
    echo "BUILD FAILED!"
    exit 1
fi

echo "Starting container with persistent storage..."
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  -v "$(pwd)/data:/var/www/site/data" \
  homepage

echo "Checking status..."
sleep 3
docker ps -f name=homepage

echo ""
echo "Setup complete! Your homepage should be available at:"
echo "  http://$(hostname -I | awk '{print $1}')/"
echo "  http://localhost/"
echo ""
echo "To check logs: docker logs homepage"
echo "To debug: curl http://localhost/debug.php"
