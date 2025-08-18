#!/usr/bin/env bash
set -euo pipefail

# Parse nmap scan results and generate services.json for the homepage
SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "[discovery] Parsing scan results from ${SCAN_FILE}..."

if [[ ! -f "${SCAN_FILE}" ]]; then
    echo "[discovery] No scan file found, creating empty services.json"
    echo "[]" > "${SERVICES_FILE}"
    exit 0
fi

# Create services directory if it doesn't exist
mkdir -p "$(dirname "${SERVICES_FILE}")"

# Use a more reliable approach with arrays
declare -a services=()

# Extract named hosts from scan results
while IFS= read -r line; do
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.+)\ \(([0-9.]+)\)$ ]]; then
        hostname="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        
        # Clean up hostname
        display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
        
        # Skip if display name is empty, just an IP, or starts with ESP_ (too many ESP devices)
        if [[ -n "$display_name" ]] && [[ ! "$display_name" =~ ^[0-9.]+$ ]] && [[ ! "$display_name" =~ ^ESP_ ]]; then
            services+=("$display_name|$ip")
            echo "[discovery] Found: $display_name ($ip)"
        fi
    fi
done < <(grep "^Nmap scan report for" "${SCAN_FILE}")

echo "[discovery] Creating JSON with ${#services[@]} entries..."

# Create a temporary file first
TEMP_FILE=$(mktemp)
trap "rm -f ${TEMP_FILE}" EXIT

# Generate JSON more carefully
{
    echo "["
    for i in "${!services[@]}"; do
        IFS='|' read -r name ip <<< "${services[$i]}"
        
        # Escape any special characters in name
        escaped_name=$(echo "$name" | sed 's/"/\\"/g')
        
        # Add comma if not first entry
        if [[ $i -gt 0 ]]; then
            echo ","
        fi
        
        # Generate JSON entry without trailing comma
        printf '  {\n    "title": "%s",\n    "url": "http://%s",\n    "group": "Discovered",\n    "desc": "Auto-discovered from network scan (%s)",\n    "tags": ["discovered", "nmap", "homelab"]\n  }' "$escaped_name" "$ip" "$ip"
    done
    echo
    echo "]"
} > "${TEMP_FILE}"

# Validate JSON before moving
if command -v jq >/dev/null 2>&1; then
    if ! jq . "${TEMP_FILE}" >/dev/null 2>&1; then
        echo "[discovery] ERROR: Generated invalid JSON"
        cat "${TEMP_FILE}"
        exit 1
    fi
fi

# Move to final location
mv "${TEMP_FILE}" "${SERVICES_FILE}"

# Set permissions (ignore errors if not running as root)
chown nginx:nginx "${SERVICES_FILE}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE}" 2>/dev/null || true

echo "[discovery] Generated services.json with ${#services[@]} entries"
echo "[discovery] File size: $(wc -c < "${SERVICES_FILE}") bytes"
