#!/usr/bin/env bash
set -euo pipefail

# Parse nmap scan results and generate services.json for the homepage
SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "[discovery] Parsing scan results from ${SCAN_FILE}..."

if [[ ! -f "${SCAN_FILE}" ]]; then
    echo "[discovery] ERROR: No scan file found at ${SCAN_FILE}"
    echo "[]" > "${SERVICES_FILE}"
    exit 1
fi

# Create services directory if it doesn't exist
mkdir -p "$(dirname "${SERVICES_FILE}")"

echo "[discovery] Scan file size: $(wc -c < "${SCAN_FILE}") bytes"

# Simple approach - just extract named hosts first
declare -a services=()

echo "[discovery] Extracting named hosts..."
while IFS= read -r line; do
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.+)\ \(([0-9.]+)\)$ ]]; then
        hostname="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        
        # Clean up hostname
        display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
        
        # Skip ESP devices and ensure we have a real hostname
        if [[ -n "$display_name" ]] && [[ ! "$display_name" =~ ^[0-9.]+$ ]] && [[ ! "$display_name" =~ ^ESP_ ]]; then
            services+=("$display_name|$ip")
            echo "[discovery] Found: $display_name ($ip)"
        fi
    fi
done < "${SCAN_FILE}"

echo "[discovery] Found ${#services[@]} named hosts"

if [[ ${#services[@]} -eq 0 ]]; then
    echo "[discovery] WARNING: No named hosts found, creating empty services file"
    echo "[]" > "${SERVICES_FILE}"
    exit 0
fi

# Create JSON file
echo "[discovery] Creating JSON file..."
{
    echo "["
    for i in "${!services[@]}"; do
        IFS='|' read -r name ip <<< "${services[$i]}"
        
        # Add comma if not first entry
        if [[ $i -gt 0 ]]; then
            echo ","
        fi
        
        # Simple JSON entry
        printf '  {\n    "title": "%s",\n    "url": "http://%s",\n    "group": "Discovered",\n    "desc": "Auto-discovered: %s",\n    "tags": ["discovered", "nmap"]\n  }' "$name" "$ip" "$ip"
    done
    echo
    echo "]"
} > "${SERVICES_FILE}"

# Validate JSON
if command -v jq >/dev/null 2>&1; then
    if jq . "${SERVICES_FILE}" >/dev/null 2>&1; then
        echo "[discovery] JSON validation: OK"
    else
        echo "[discovery] ERROR: Invalid JSON generated"
        cat "${SERVICES_FILE}"
        exit 1
    fi
else
    echo "[discovery] jq not available, skipping JSON validation"
fi

# Set permissions
chown nginx:nginx "${SERVICES_FILE}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE}" 2>/dev/null || true

echo "[discovery] SUCCESS: Generated ${#services[@]} services"
echo "[discovery] File: ${SERVICES_FILE} ($(wc -c < "${SERVICES_FILE}") bytes)"
echo "[discovery] Content preview:"
head -10 "${SERVICES_FILE}" | sed 's/^/[discovery]   /'
