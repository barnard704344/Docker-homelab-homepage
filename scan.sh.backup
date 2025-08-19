#!/usr/bin/env bash
set -euo pipefail

# Acc  # Fast homelab scan targeting common service ports
  # Use -T4 (aggressive timing) with specific ports for typical homelab services
  # Common homelab ports: web (80,443,8080,8443,3000,5000,8000,9000), 
  # management (8006,19999,9090,3001), AI/ML (11434), Code (8443,32168), 
  # Docker (2375,2376), 3D printing (3334), media (8096,32400,9981), 
  # monitoring (3001,8086,9090,9100,9187,19999), databases, ssh, etc.
  HOMELAB_PORTS="21,22,23,25,53,80,110,143,443,993,995,1433,2375,2376,3000,3001,3306,3334,4200,5000,5432,6379,7000,8000,8006,8080,8081,8086,8090,8096,8443,8888,9000,9090,9100,9187,9443,9981,10000,11434,19999,32168,32400"
  
  if ! timeout 90 nmap -T4 -p "${HOMELAB_PORTS}" -Pn -R --host-timeout 15s --max-rtt-timeout 500ms "${NET}" >> "${OUTFILE}" 2>&1; then
    echo "[!] nmap failed or timed out for ${NET}" >> "${OUTFILE}"
  fiseparated subnets from env; default if not set.
# Examples:
#   SUBNETS="192.168.1.0/24"
#   SUBNETS="192.168.1.0/24 10.72.28.0/22 10.136.40.0/24"
SUBNETS="${SUBNETS:-192.168.1.0/24}"

# Use persistent data directory that survives container rebuilds
OUTDIR="/var/www/site/data/scan"
TIMESTAMP="$(date -Iseconds)"
mkdir -p "${OUTDIR}"

OUTFILE="${OUTDIR}/last-scan.txt"
: > "${OUTFILE}"

{
  echo "=== Homelab Homepage Scan ==="
  echo "Date: ${TIMESTAMP}"
  echo "Subnets: ${SUBNETS}"
  echo
  echo "Open ports (homelab services) per host"
  echo "---------------------------------------"
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

  # Fast homelab scan targeting common service ports
  # Use -T4 (aggressive timing) with specific ports for typical homelab services
  # Common homelab ports: web (80,443,8080,8443,3000,5000,8000,9000), 
  # management (8006,19999,9090,3001), AI/ML (11434), Code (8443,32168), 
  # Docker (2375,2376), 3D printing (3334), media (8096,32400,9981), 
  # monitoring (3001,8086,9090,9100,9187,19999), NAS/backup (5000,5001,8007,8080), databases, ssh, etc.
  HOMELAB_PORTS="21,22,23,25,53,80,110,143,443,993,995,1433,2375,2376,3000,3001,3306,3334,4200,5000,5001,5432,6379,7000,8000,8006,8007,8080,8081,8086,8090,8096,8443,8888,9000,9090,9100,9187,9443,9981,10000,11434,19999,32168,32400"
  
  if ! timeout 90 nmap -T4 -p "${HOMELAB_PORTS}" -Pn -R --host-timeout 15s --max-rtt-timeout 500ms "${NET}" >> "${OUTFILE}" 2>&1; then
    echo "[!] nmap failed or timed out for ${NET}" >> "${OUTFILE}"
  fi
  
  {
    echo "Scan completed for ${NET}"
    echo
  } >> "${OUTFILE}"
done

echo >> "${OUTFILE}"
echo "Done." >> "${OUTFILE}"

# Convenience symlinks for both old and new locations
ln -sf "${OUTFILE}" /var/www/site/scan.txt
# Also create a symlink in the persistent directory for easy access
ln -sf "${OUTFILE}" /var/www/site/data/scan.txt

# Create compatibility symlinks from old scan directory to persistent location
mkdir -p /var/www/site/scan
ln -sf "${OUTFILE}" /var/www/site/scan/last-scan.txt
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
