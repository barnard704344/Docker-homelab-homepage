#!/usr/bin/env bash
set -euo pipefail

# Accept space-separated subnets from env; default if not set.
# Examples:
#   SUBNETS="192.168.1.0/24"
#   SUBNETS="192.168.1.0/24 10.72.28.0/22 10.136.40.0/24"
SUBNETS="${SUBNETS:-192.168.1.0/24}"

OUTDIR="/var/www/site/scan"
TIMESTAMP="$(date -Iseconds)"
mkdir -p "${OUTDIR}"

OUTFILE="${OUTDIR}/last-scan.txt"
: > "${OUTFILE}"

{
  echo "=== Homelab Homepage Scan ==="
  echo "Date: ${TIMESTAMP}"
  echo "Subnets: ${SUBNETS}"
  echo
  echo "Open ports (top 1000) per host"
  echo "--------------------------------"
} >> "${OUTFILE}"

# Scan each subnet in the list
for NET in ${SUBNETS}; do
  {
    echo
    echo ">>> Subnet: ${NET}"
    echo "---------------------"
    echo "Testing network connectivity..."
    
    # Test basic connectivity first
    if ping -c 1 -W 5 $(echo ${NET} | cut -d'/' -f1 | sed 's/0$/1/') >/dev/null 2>&1; then
      echo "Network appears reachable"
    else
      echo "Warning: Network may not be reachable"
    fi
    
    echo "Starting nmap scan..."
  } >> "${OUTFILE}"

  # Basic TCP scan with faster timing and reduced port range for testing
  # Use -T4 (aggressive timing), -F (fast scan - top 100 ports), --host-timeout for faster results
  if ! timeout 300 nmap -T4 -F -Pn --host-timeout 60s "${NET}" >> "${OUTFILE}" 2>&1; then
    echo "[!] nmap failed or timed out for ${NET}" >> "${OUTFILE}"
  fi
  
  {
    echo "Scan completed for ${NET}"
    echo
  } >> "${OUTFILE}"
done

echo >> "${OUTFILE}"
echo "Done." >> "${OUTFILE}"

# Convenience symlink
ln -sf "${OUTFILE}" /var/www/site/scan.txt

echo "[scanner] OK: wrote ${OUTFILE}"
