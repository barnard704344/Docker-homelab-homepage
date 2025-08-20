#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# start.sh - Container entrypoint
# - Sets up necessary directories and permissions
# - Starts PHP-FPM for scan button functionality
# - Serves the site with nginx (foreground)
# - Optionally runs scan.sh once at start (RUN_SCAN_ON_START=1)
# - Optionally runs scan.sh on an interval in minutes (SCAN_INTERVAL=N)
# - Accepts space-separated subnets via SUBNETS env (defaults in scan.sh)
# -------------------------------------------------------------------

SCAN_INTERVAL="${SCAN_INTERVAL:-0}"   # minutes; 0 disables scheduler
RUN_SCAN_ON_START="${RUN_SCAN_ON_START:-0}"

echo "[start] Setting up directories and permissions..."

# Ensure all required directories exist (both old and new paths for compatibility)
mkdir -p /var/www/site/scan
mkdir -p /var/www/site/data/scan
mkdir -p /run/nginx
mkdir -p /run/php
mkdir -p /var/log/nginx

# Set proper ownership for web directories
chown -R nginx:nginx /var/www/site
# NOTE: Don't set blanket 755 permissions here - it overwrites our 777 data directory
chmod 755 /var/www/site
# Set 755 only for the site files, not the data directory
find /var/www/site -type f -not -path "*/data/*" -exec chmod 644 {} \;
find /var/www/site -type d -not -path "*/data*" -exec chmod 755 {} \;

# Force create and setup persistent data directory with maximum permissions
echo "[start] Setting up persistent data directory..."
mkdir -p /var/www/site/data
mkdir -p /var/www/site/data/scan

# Set maximum permissions for category management to work - be very aggressive
echo "[start] Setting 777 permissions for data directory..."
chmod 777 /var/www/site/data
chmod 777 /var/www/site/data/scan
chmod -R 777 /var/www/site/data

# Try different ownership approaches
echo "[start] Setting ownership..."
chown -R nginx:nginx /var/www/site/data 2>/dev/null || true
chown -R www-data:www-data /var/www/site/data 2>/dev/null || true
chown -R nobody:nobody /var/www/site/data 2>/dev/null || true

# Force permissions again after ownership changes - this is critical
chmod -R 777 /var/www/site/data
chmod 777 /var/www/site/data

# Create empty files with proper permissions if they don't exist
touch /var/www/site/data/categories.json 2>/dev/null || true
touch /var/www/site/data/service-assignments.json 2>/dev/null || true
touch /var/www/site/data/services.json 2>/dev/null || true
chmod 666 /var/www/site/data/*.json 2>/dev/null || true

# Final aggressive permission set - MUST be 777 for category management
echo "[start] FINAL: Ensuring data directory is 777..."
chmod 777 /var/www/site/data
chmod -R 777 /var/www/site/data
# Verify it actually worked
ACTUAL_PERMS=$(stat -c "%a" /var/www/site/data 2>/dev/null || echo "000")
if [ "$ACTUAL_PERMS" = "777" ]; then
    echo "[start] ✅ Data directory permissions confirmed: 777"
else
    echo "[start] ❌ WARNING: Data directory permissions are: $ACTUAL_PERMS (should be 777)"
fi

# Test write capability extensively
echo "[start] Testing write capability..."
if touch /var/www/site/data/test-write 2>/dev/null; then
    rm -f /var/www/site/data/test-write
    echo "[start] ✓ Write test successful - category management should work"
else
    echo "[start] ❌ Write test failed - trying alternative approach..."
    # Last resort: make directory world-writable
    chmod 1777 /var/www/site/data
    if touch /var/www/site/data/test-write 2>/dev/null; then
        rm -f /var/www/site/data/test-write
        echo "[start] ✓ Write test successful with sticky bit"
    else
        echo "[start] ❌ Write test still failing - category management may not work"
        ls -la /var/www/site/ || echo "Cannot list directory"
    fi
fi

# Ensure PHP-FPM can write to necessary directories
chown -R nginx:nginx /var/www/site/scan
chmod 755 /var/www/site/scan

# Create compatibility symlinks from old scan directory to persistent data if volume is mounted
if [[ -d /var/www/site/data ]]; then
    echo "[start] Creating compatibility symlinks for old scan URLs..."
    # Ensure old scan directory exists and link to persistent data
    mkdir -p /var/www/site/scan
    ln -sf /var/www/site/data/scan/last-scan.txt /var/www/site/scan/last-scan.txt 2>/dev/null || true
    ln -sf /var/www/site/data/services.json /var/www/site/services.json 2>/dev/null || true
    echo "[start] ✓ Compatibility symlinks created"
fi

# Create debug script if it doesn't exist
if [[ ! -f /usr/local/bin/debug-parser.sh ]]; then
    echo "[start] Creating debug parser script..."
    cat > /usr/local/bin/debug-parser.sh << 'EODEBUG'
#!/usr/bin/env bash

# Debug script to test the parser manually
echo "=== Parser Debug Script ==="
echo "Date: $(date)"
echo

# Check if running in container
if [[ -f /.dockerenv ]]; then
    echo "Running inside Docker container: YES"
else
    echo "Running inside Docker container: NO"
fi

echo
echo "=== File System Status ==="
SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "Scan file: $SCAN_FILE"
if [[ -f "$SCAN_FILE" ]]; then
    echo "  EXISTS: $(wc -c < "$SCAN_FILE") bytes"
    echo "  First 5 lines:"
    head -5 "$SCAN_FILE" | sed 's/^/    /'
else
    echo "  NOT FOUND"
fi

echo
echo "Services file: $SERVICES_FILE"
if [[ -f "$SERVICES_FILE" ]]; then
    echo "  EXISTS: $(wc -c < "$SERVICES_FILE") bytes"
    echo "  Content:"
    cat "$SERVICES_FILE" | sed 's/^/    /'
else
    echo "  NOT FOUND"
fi

echo
echo "Directory permissions:"
ls -la /var/www/site/ || echo "Directory not accessible"

echo
echo "=== Running Parser ==="
if [[ -x /usr/local/bin/parse-scan.sh ]]; then
    echo "Parser found at /usr/local/bin/parse-scan.sh"
    /usr/local/bin/parse-scan.sh
else
    echo "Parser NOT found at /usr/local/bin/parse-scan.sh"
    echo "Looking for parser scripts..."
    find / -name "parse-scan.sh" -type f 2>/dev/null || echo "No parse-scan.sh found anywhere"
fi

echo
echo "=== Final Status ==="
if [[ -f "$SERVICES_FILE" ]]; then
    echo "Services file size after parsing: $(wc -c < "$SERVICES_FILE") bytes"
    if command -v jq >/dev/null 2>&1; then
        service_count=$(jq length "$SERVICES_FILE" 2>/dev/null || echo "invalid JSON")
        echo "Number of services: $service_count"
    fi
else
    echo "Services file was not created"
fi
EODEBUG
    chmod +x /usr/local/bin/debug-parser.sh
fi

# Ensure all scripts are executable
echo "[start] Making scripts executable..."
chmod +x /usr/local/bin/scan.sh /usr/local/bin/parse-scan.sh /usr/local/bin/debug-parser.sh /usr/local/bin/start.sh 2>/dev/null || true

# Also ensure any PHP scripts are accessible
chmod +x /var/www/site/run-scan.php /var/www/site/debug.php 2>/dev/null || true

# Verify scripts exist and are executable
echo "[start] Checking script status..."
for script in scan.sh parse-scan.sh debug-parser.sh; do
    if [[ -f "/usr/local/bin/$script" ]]; then
        if [[ -x "/usr/local/bin/$script" ]]; then
            echo "[start] ✓ $script exists and is executable"
        else
            echo "[start] ⚠ $script exists but is not executable"
        fi
    else
        echo "[start] ✗ $script not found"
    fi
done

echo "[start] SUBNETS='${SUBNETS:-(default in scan.sh)}'"
echo "[start] RUN_SCAN_ON_START='${RUN_SCAN_ON_START}'"
echo "[start] SCAN_INTERVAL='${SCAN_INTERVAL}' minute(s)"

# If a positive interval is set, launch a background refresher loop
if [[ "${SCAN_INTERVAL}" =~ ^[1-9][0-9]*$ ]]; then
  echo "[start] Launching background scanner every ${SCAN_INTERVAL} minute(s)..."
  (
    while true; do
      echo "[scanner] running scheduled scan..."
      /usr/local/bin/scan.sh || echo "[scanner] WARNING: scan failed"
      sleep $(( SCAN_INTERVAL * 60 ))
    done
  ) &
elif [[ "${RUN_SCAN_ON_START}" == "1" ]]; then
  echo "[start] RUN_SCAN_ON_START=1 -> running initial scan..."
  /usr/local/bin/scan.sh || echo "[scanner] WARNING: initial scan failed (non-fatal)"
fi

# Test the parser once at startup to ensure it works
echo "[start] Testing parser functionality..."
if [[ -x /usr/local/bin/parse-scan.sh ]]; then
    echo "[start] Parser script is executable, testing..."
    /usr/local/bin/parse-scan.sh || echo "[start] Parser test failed (this is normal if no scan data exists yet)"
else
    echo "[start] ERROR: Parser script not executable!"
fi

echo "[start] Starting PHP-FPM..."
php-fpm82 -D

# Wait a moment for PHP-FPM to fully start
sleep 2

echo "[start] Starting nginx..."
exec nginx -g 'daemon off;'
