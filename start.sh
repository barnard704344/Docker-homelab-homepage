#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# start.sh - Container entrypoint
# - Serves the site with nginx (foreground)
# - Optionally runs scan.sh once at start (RUN_SCAN_ON_START=1)
# - Optionally runs scan.sh on an interval in minutes (SCAN_INTERVAL=N)
# - Accepts space-separated subnets via SUBNETS env (defaults in scan.sh)
# -------------------------------------------------------------------

SCAN_INTERVAL="${SCAN_INTERVAL:-0}"   # minutes; 0 disables scheduler
RUN_SCAN_ON_START="${RUN_SCAN_ON_START:-0}"

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

echo "[start] Starting nginx..."
mkdir -p /run/nginx
exec nginx -g 'daemon off;'
