#!/bin/bash

# Emergency permission fix script
# Run this on the remote server to diagnose and fix permission issues

echo "=== Permission Diagnosis and Fix ==="
echo "Date: $(date)"
echo

# Check if we're on the host or in container
if [[ -f /.dockerenv ]]; then
    echo "❌ This script should be run on the HOST, not inside the container"
    exit 1
fi

echo "✓ Running on host system"
echo

# Check current directory
echo "Current directory: $(pwd)"
echo "Contents:"
ls -la
echo

# Check if data directory exists and its permissions
if [[ -d "./data" ]]; then
    echo "Host data directory permissions:"
    ls -la ./data
    PERMS=$(stat -c "%a" ./data 2>/dev/null || echo "000")
    echo "Current permissions: $PERMS"
    echo
    
    if [[ "$PERMS" != "777" ]]; then
        echo "🔧 FIXING: Setting host data directory to 777..."
        chmod 777 ./data
        echo "✓ Host directory permissions updated"
        echo "New permissions:"
        ls -la ./data
    else
        echo "✓ Host directory already has 777 permissions"
    fi
else
    echo "📁 Creating data directory with 777 permissions..."
    mkdir -p ./data
    chmod 777 ./data
    echo "✓ Data directory created with 777 permissions"
fi

echo
echo "=== Container Status ==="
if docker ps -f name=homepage | grep -q homepage; then
    echo "✓ Container 'homepage' is running"
    echo "Container details:"
    docker ps -f name=homepage
    echo
    echo "🔄 Container needs to be restarted to pick up permission changes"
    echo "Run: docker restart homepage"
else
    echo "❌ Container 'homepage' is not running"
    echo "Run: ./setup.sh"
fi

echo
echo "=== Final Host Directory Check ==="
ls -la ./data
FINAL_PERMS=$(stat -c "%a" ./data 2>/dev/null || echo "000")
echo "Final host directory permissions: $FINAL_PERMS"

if [[ "$FINAL_PERMS" == "777" ]]; then
    echo "✅ Host permissions are correct"
    echo "Next step: Restart container with: docker restart homepage"
else
    echo "❌ Host permissions still wrong: $FINAL_PERMS"
    echo "Manual fix: chmod 777 ./data"
fi
