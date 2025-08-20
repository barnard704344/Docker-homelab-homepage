#!/bin/bash

# Universal setup script that handles all Docker homelab homepage setup
# This script can be run even without execute permissions using: bash setup.sh

echo "=== Docker Homelab Homepage Setup ==="
echo "Setting up container with persistent storage..."

# Create host data directory for volume mount with proper permissions
echo "Creating host data directory with 777 permissions..."
mkdir -p ./data
chmod 777 ./data
echo "Host data directory permissions set to 777"

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

echo "Waiting for container to initialize..."
sleep 8

echo "Checking container status..."
if docker ps -f name=homepage | grep -q homepage; then
    echo "✅ Container is running"
else
    echo "❌ Container failed to start"
    echo "Check logs with: docker logs homepage"
    exit 1
fi

echo ""
echo "🎉 Setup complete! Your homepage is available at:"
echo "  http://$(hostname -I | awk '{print $1}')/"
echo "  http://localhost/"
echo ""
echo "� Management interfaces:"
echo "  �🔧 Setup page: http://$(hostname -I | awk '{print $1}')/setup.html" 
echo "  🐛 Debug info: http://$(hostname -I | awk '{print $1}')/setup-debug.php"
echo ""
echo "📝 Useful commands:"
echo "  View logs: docker logs homepage"
echo "  Stop: docker stop homepage" 
echo "  Restart: docker restart homepage"
echo ""
echo "All permissions and configuration are handled automatically inside the container."
