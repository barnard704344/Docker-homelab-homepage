#!/usr/bin/env bash
set -euo pipefail

# Optional: run a scan on container start if env is set
if [[ "${RUN_SCAN_ON_START:-0}" == "1" ]]; then
  echo "[*] RUN_SCAN_ON_START=1 -> running initial scan..."
  /app/scan.sh || echo "[!] scan.sh failed (non-fatal)"
fi

echo "[*] Starting nginx..."
# Ensure runtime dir exists (should be created in Dockerfile, but safe to re-ensure)
mkdir -p /run/nginx
exec nginx -g 'daemon off;'
