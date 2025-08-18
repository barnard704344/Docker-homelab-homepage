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

# Use a more reliable approach with arrays
declare -a services=()

# Extract named hosts from scan results
while IFS= read -r line; do
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.+)\ \(([0-9.]+)\)$ ]]; then
        hostname="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        
        # Clean up hostname
        display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
        
        # Skip if display name is empty or just an IP
        if [[ -n "$display_name" ]] && [[ ! "$display_name" =~ ^[0-9.]+$ ]]; then
            services+=("$display_name|$ip")
            echo "[discovery] Found: $display_name ($ip)"
        fi
    fi
done < <(grep "^Nmap scan report for" "${SCAN_FILE}")

# Generate JSON
echo "[discovery] Creating JSON with ${#services[@]} entries..."

echo "[" > "${SERVICES_FILE}"
for i in "${!services[@]}"; do
    IFS='|' read -r name ip <<< "${services[$i]}"
    
    # Add comma if not first entry
    if [[ $i -gt 0 ]]; then
        echo "," >> "${SERVICES_FILE}"
    fi
    
    cat >> "${SERVICES_FILE}" << EOF
  {
    "title": "${name}",
    "url": "http://${ip}",
    "group": "Discovered",
    "desc": "Auto-discovered from network scan (${ip})",
    "tags": ["discovered", "nmap", "homelab"]
  }EOF
done

echo >> "${SERVICES_FILE}"
echo "]" >> "${SERVICES_FILE}"

# Set permissions
chown nginx:nginx "${SERVICES_FILE}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE}"

echo "[discovery] Generated services.json with ${#services[@]} entries"
