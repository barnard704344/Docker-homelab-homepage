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
    # Try multiple strategies to ensure permissions work
    sudo chown -R 82:82 ./data 2>/dev/null || \
    sudo chown -R 33:33 ./data 2>/dev/null || \
    sudo chown -R www-data:www-data ./data 2>/dev/null || true
    
    # Also set broader permissions to ensure container can write
    sudo chmod -R 777 ./data
    echo "Applied chmod 777 to data directory for maximum compatibility"
else
    echo "No sudo available, setting generic permissions..."
    chmod -R 777 ./data 2>/dev/null || true
fi

# Create essential data files with proper permissions
echo "Creating essential data files..."
touch ./data/categories.json ./data/service-assignments.json ./data/services.json 2>/dev/null || true
chmod 666 ./data/*.json 2>/dev/null || true

# Double-check the data directory is accessible
if [[ -d ./data ]]; then
    echo "Data directory exists and has permissions: $(ls -ld ./data)"
    echo "Data files:"
    ls -la ./data/ 2>/dev/null || echo "No files in data directory yet"
else
    echo "WARNING: Data directory does not exist after creation attempt"
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

echo "Waiting for container to start..."
sleep 5

echo "Ensuring data directory permissions inside container..."
# Fix permissions inside the container after it starts
docker exec homepage mkdir -p /var/www/site/data 2>/dev/null || true
docker exec homepage chmod -R 777 /var/www/site/data 2>/dev/null || true
docker exec homepage chown -R nginx:nginx /var/www/site/data 2>/dev/null || true

# Create essential JSON files inside container if they don't exist
docker exec homepage touch /var/www/site/data/categories.json 2>/dev/null || true
docker exec homepage touch /var/www/site/data/service-assignments.json 2>/dev/null || true  
docker exec homepage touch /var/www/site/data/services.json 2>/dev/null || true
docker exec homepage chmod 666 /var/www/site/data/*.json 2>/dev/null || true

echo "Verifying permissions setup..."
docker exec homepage ls -la /var/www/site/data 2>/dev/null || echo "Could not list data directory"

echo "Checking status..."
sleep 2
docker ps -f name=homepage

echo "Testing category management permissions..."
sleep 3
if curl -s http://localhost/setup-debug.php | head -10; then
    echo ""
    echo "✅ Setup completed successfully!"
else
    echo ""
    echo "⚠️  Debug endpoint not ready yet, but container is running"
fi

echo ""
echo "Setup complete! Your homepage should be available at:"
echo "  http://$(hostname -I | awk '{print $1}')/"
echo "  http://localhost/"
echo ""
echo "🔧 Setup page: http://$(hostname -I | awk '{print $1}')/setup.html"
echo "🐛 Debug info: http://$(hostname -I | awk '{print $1}')/setup-debug.php"
echo ""
echo "To check logs: docker logs homepage"
echo "To test category creation:"
echo "  curl -X POST -H 'Content-Type: application/json' -d '{\"action\":\"save_categories\",\"categories\":{\"test\":\"Test Category\"}}' http://localhost/setup-data.php"
echo ""
echo "If category saving fails, check permissions with:"
echo "  docker exec homepage ls -la /var/www/site/data"
