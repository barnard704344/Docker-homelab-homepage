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

# Ensure all required directories exist
mkdir -p /var/www/site/scan
mkdir -p /run/nginx
mkdir -p /run/php
mkdir -p /var/log/nginx

# Set proper ownership for web directories
chown -R nginx:nginx /var/www/site
chmod -R 755 /var/www/site

# Ensure PHP-FPM can write to necessary directories
chown -R nginx:nginx /var/www/site/scan
chmod 755 /var/www/site/scan

echo "[start] SUBNETS='${SUBNETS:-(default in scan.sh)}'"
echo "[start] RUN_SCAN_ON_START='${RUN_SCAN_ON_START}'"
echo "[start] SCAN_INTERVAL='${SCAN_INTERVAL}' minute(s)"

# If a positive interval is set, launch a background refresher loop
if [[ "${SCAN_INTERVAL}" =~ ^[1-9][0-9]*$ ]]; then
  echo "[start] Launching background scanner every ${SCAN_INTERVAL} minute(s)..."
  (
    while true; do
      echo "[scanner] running scheduled scan..."
      /app/scan.sh || echo "[scanner] WARNING: scan failed"
      sleep $(( SCAN_INTERVAL * 60 ))
    done
  ) &
elif [[ "${RUN_SCAN_ON_START}" == "1" ]]; then
  echo "[start] RUN_SCAN_ON_START=1 -> running initial scan..."
  /app/scan.sh || echo "[scanner] WARNING: initial scan failed (non-fatal)"
fi

echo "[start] Starting PHP-FPM..."
php-fpm82 -D

# Wait a moment for PHP-FPM to fully start
sleep 2

echo "[start] Starting nginx..."
exec nginx -g 'daemon off;'
