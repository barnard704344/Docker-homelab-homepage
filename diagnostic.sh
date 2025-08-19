#!/bin/bash

# Diagnostic script to check permission issues
echo "=== Docker Homelab Homepage Diagnostic ==="
echo "Timestamp: $(date)"
echo

echo "=== Container Status ==="
docker ps -f name=homepage

echo
echo "=== Host Data Directory ==="
if [[ -d ./data ]]; then
    echo "Data directory exists:"
    ls -la ./data/
    echo
    echo "Data directory permissions:"
    ls -ld ./data
    if [[ -d ./data/scan ]]; then
        echo "Scan directory permissions:"
        ls -ld ./data/scan
    fi
else
    echo "❌ Data directory does not exist on host"
fi

echo
echo "=== Container Volume Mount ==="
docker inspect homepage | grep -A 20 '"Mounts":'

echo
echo "=== Debug Endpoint ==="
curl -s http://localhost/debug.php | jq '.directories'

echo
echo "=== Container Internal Check ==="
echo "Checking container internal permissions..."
docker exec homepage ls -la /var/www/site/data/ 2>/dev/null || echo "Cannot access container or directory"

echo
echo "=== Try Write Test ==="
echo "Testing write permissions in container..."
docker exec homepage touch /var/www/site/data/write-test 2>/dev/null && \
docker exec homepage rm /var/www/site/data/write-test && \
echo "✅ Write test successful" || echo "❌ Write test failed"

echo
echo "=== Manual Permission Fix ==="
echo "Attempting to fix permissions from inside container..."
docker exec homepage chown -R nginx:nginx /var/www/site/data
docker exec homepage chmod -R 755 /var/www/site/data

echo
echo "=== Retry Write Test ==="
docker exec homepage touch /var/www/site/data/write-test-2 2>/dev/null && \
docker exec homepage rm /var/www/site/data/write-test-2 && \
echo "✅ Write test successful after permission fix" || echo "❌ Write test still failing"
