#!/bin/bash

# Diagnostic script to check scanning status on remote server
echo "=== Homelab Homepage Scanning Diagnostics ==="
echo "Date: $(date)"
echo "Server: $(hostname) ($(hostname -I | awk '{print $1}'))"
echo ""

# Check if we're on the expected server
SERVER_IP=$(hostname -I | awk '{print $1}')
if [[ "$SERVER_IP" == "192.168.1.105" ]]; then
    echo "✓ Running on expected server (192.168.1.105)"
else
    echo "ℹ Running on server: $SERVER_IP (expected: 192.168.1.105)"
fi

echo ""
# Check if container is running
echo "1. Container Status:"
if docker ps -f name=homepage --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep homepage; then
    echo "✓ Container is running"
else
    echo "✗ Container is not running"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "To start container, run: bash setup.sh"
    exit 1
fi

echo ""
echo "2. Environment Variables:"
docker exec homepage env | grep -E "(SCAN_|SUBNETS|RUN_SCAN)" | sort || echo "No scan environment variables found"

echo ""
echo "3. Container Processes:"
docker exec homepage ps aux | grep -E "(nmap|scan)" || echo "No scan processes currently running"

echo ""
echo "4. Recent Container Logs:"
echo "--- Last 25 lines ---"
docker logs --tail 25 homepage 2>&1

echo ""
echo "5. Network Connectivity Test:"
echo "--- Testing network from container ---"
docker exec homepage ping -c 1 192.168.1.1 >/dev/null 2>&1 && echo "✓ Gateway reachable" || echo "✗ Gateway not reachable"
docker exec homepage ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "✓ Internet reachable" || echo "✗ Internet not reachable"

echo ""
echo "6. File System Check:"
echo "--- Scan files ---"
docker exec homepage ls -la /var/www/site/ | grep -E "(scan|service)" || echo "No scan files found"
echo "--- Data directory ---"
docker exec homepage ls -la /var/www/site/data/ 2>/dev/null || echo "Data directory not accessible"
echo "--- Permissions ---"
docker exec homepage ls -ld /var/www/site/data 2>/dev/null || echo "Cannot check data permissions"

echo ""
echo "7. Web Interface Status:"
echo "--- HTTP Response from server ---"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null | grep -q "200"; then
    echo "✓ Local web interface accessible (HTTP 200)"
else
    echo "✗ Local web interface not accessible"
fi

echo "--- HTTP Response from remote ---"
if curl -s -o /dev/null -w "%{http_code}" http://192.168.1.105/ 2>/dev/null | grep -q "200"; then
    echo "✓ Remote web interface accessible (HTTP 200)"
else
    echo "✗ Remote web interface not accessible"
fi

echo ""
echo "8. Scan Status Endpoint:"
echo "--- Current scan status ---"
SCAN_STATUS=$(curl -s http://localhost/scan-status.php 2>/dev/null || echo "endpoint_not_accessible")
echo "Scan status: $SCAN_STATUS"

echo ""
echo "9. Manual Scan Test:"
echo "--- Attempting manual scan (this may take 90 seconds) ---"
echo "Starting scan..."
if docker exec homepage timeout 120 /usr/local/bin/scan.sh; then
    echo "✓ Manual scan completed successfully"
    echo "--- Checking for generated files ---"
    docker exec homepage ls -la /var/www/site/data/scan/ 2>/dev/null || echo "Scan directory not found"
    if docker exec homepage test -f /var/www/site/data/scan/last-scan.txt; then
        SCAN_SIZE=$(docker exec homepage wc -c /var/www/site/data/scan/last-scan.txt 2>/dev/null | awk '{print $1}')
        echo "✓ Scan file created (${SCAN_SIZE} bytes)"
    else
        echo "✗ Scan file not created"
    fi
else
    echo "✗ Manual scan failed or timed out"
fi

echo ""
echo "=== Diagnostics Complete ==="
echo ""
echo "🌐 Access your homepage at: http://192.168.1.105/"
echo ""
echo "If scanning is still not working:"
echo "1. Check environment: docker exec homepage env | grep SCAN"
echo "2. Restart container: docker restart homepage"
echo "3. Check logs: docker logs homepage"
echo "4. Test network from container: docker exec homepage nmap -sn 192.168.1.1/24"
