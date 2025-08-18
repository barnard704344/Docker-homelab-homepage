#!/bin/bash

echo "=== Building and Testing Homepage Container ==="
echo "Date: $(date)"
echo

# Stop any existing container
echo "Stopping existing containers..."
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

# Build the container
echo
echo "Building container..."
if ! docker build -t homepage .; then
    echo "ERROR: Build failed!"
    exit 1
fi

# Run container with host networking
echo
echo "Starting container with host networking..."
if ! docker run -d --name homepage --network host homepage; then
    echo "ERROR: Container start failed!"
    exit 1
fi

# Wait a moment for startup
echo "Waiting for container startup..."
sleep 5

# Check container status
echo
echo "Container status:"
docker ps -f name=homepage

# Check logs
echo
echo "Container logs:"
docker logs homepage

# Test the debug script
echo
echo "=== Running Debug Script ==="
docker exec homepage /usr/local/bin/debug-parser.sh

# Test web access
echo
echo "=== Testing Web Access ==="
if curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost/; then
    echo
    echo "Web server is responding!"
else
    echo
    echo "Web server is not responding"
fi

echo
echo "=== Manual Commands ==="
echo "To run scan manually: docker exec homepage /usr/local/bin/scan.sh"
echo "To debug parser: docker exec homepage /usr/local/bin/debug-parser.sh" 
echo "To check logs: docker logs homepage"
echo "To access shell: docker exec -it homepage /bin/sh"
echo "To test web debug: curl http://localhost/debug.php"
