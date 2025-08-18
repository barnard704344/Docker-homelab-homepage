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
  } >> "${OUTFILE}"

  # Basic TCP scan; add -sV if you want service versions (slower)
  if ! nmap -T4 -Pn "${NET}" >> "${OUTFILE}" 2>&1; then
    echo "[!] nmap failed for ${NET}" >> "${OUTFILE}"
  fi
done

echo >> "${OUTFILE}"
echo "Done." >> "${OUTFILE}"

# Convenience symlink
ln -sf "${OUTFILE}" /var/www/site/scan.txt

echo "[scanner] OK: wrote ${OUTFILE}"
