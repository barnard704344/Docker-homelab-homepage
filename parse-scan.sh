#!/usr/bin/env bash
set -euo pipefail

# Parse nmap scan results and generate services.json for the homepage
# This script reads the scan output and creates service entries for discovered hosts

SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "[discovery] Parsing scan results from ${SCAN_FILE}..."

if [[ ! -f "${SCAN_FILE}" ]]; then
    echo "[discovery] No scan file found, creating empty services.json"
    echo "[]" > "${SERVICES_FILE}"
    exit 0
fi

# Create temporary file for building JSON
TEMP_JSON=$(mktemp)
echo "[" > "${TEMP_JSON}"

# Parse the scan results
FIRST_ENTRY=true

# Process each host entry
grep -A 20 "^Nmap scan report for" "${SCAN_FILE}" | while IFS= read -r line; do
    # Look for nmap scan report lines with hostnames and IPs
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.+)\ \(([0-9.]+)\)$ ]]; then
        hostname="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        
        # Clean up hostname (remove domain suffix)
        display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
        
        # Add entry for named hosts
        if [[ $FIRST_ENTRY == false ]]; then
            echo "," >> "${TEMP_JSON}"
        fi
        
        cat >> "${TEMP_JSON}" << EOF
  {
    "title": "${display_name}",
    "url": "http://${ip}",
    "group": "Discovered",
    "desc": "Auto-discovered from network scan (${ip})",
    "tags": ["discovered", "nmap"]
  }EOF
        
        FIRST_ENTRY=false
        
    elif [[ $line =~ ^Nmap\ scan\ report\ for\ ([0-9.]+)$ ]]; then
        # IP-only entries (less interesting, skip for now)
        continue
    fi
done

echo "]" >> "${TEMP_JSON}"

# Move the completed file
mv "${TEMP_JSON}" "${SERVICES_FILE}"
chown nginx:nginx "${SERVICES_FILE}"

echo "[discovery] Generated $(jq length "${SERVICES_FILE}") service entries in ${SERVICES_FILE}"
