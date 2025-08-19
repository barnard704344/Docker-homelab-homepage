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
  echo "Open ports (top 10000) per host"
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

  # Comprehensive TCP scan with extended port range
  # Use -T4 (aggressive timing), -p- (all ports 1-65535) or -p1-10000 for faster scan
  # Add -R for reverse DNS lookups to get hostnames for IP-only devices
  # --top-ports 10000 scans the most common 10000 ports instead of all 65535 for better performance
  if ! timeout 600 nmap -T4 --top-ports 10000 -Pn -R --host-timeout 120s "${NET}" >> "${OUTFILE}" 2>&1; then
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

# Parse scan results for service discovery
echo "[scanner] Parsing scan results for service discovery..."
if [[ -x /usr/local/bin/parse-scan.sh ]]; then
    /usr/local/bin/parse-scan.sh || echo "[scanner] WARNING: service discovery failed (non-fatal)"
else
    echo "[scanner] WARNING: parse-scan.sh not found at /usr/local/bin/"
    ls -la /usr/local/bin/parse* /app/ 2>/dev/null || true
fi
