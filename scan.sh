#!/usr/bin/env bash
set -euo pipefail

# Subnet to scan; change if your LAN is different
SUBNET="192.168.1.0/24"
OUTDIR="/var/www/site/scan"
OUTFILE="${OUTDIR}/last-scan.txt"

mkdir -p "${OUTDIR}"

echo "=== Homelab Homepage Scan ===" > "${OUTFILE}"
echo "Date: $(date -Iseconds)" >> "${OUTFILE}"
echo "Subnet: ${SUBNET}" >> "${OUTFILE}"
echo >> "${OUTFILE}"
echo "Open ports (top 1000) per host:" >> "${OUTFILE}"
echo "--------------------------------" >> "${OUTFILE}"

# Basic TCP scan of common ports
# You can tweak flags as desired (e.g., -sV for service detection)
nmap -T4 -Pn "${SUBNET}" >> "${OUTFILE}" || {
  echo "[!] nmap exited with non-zero status" >> "${OUTFILE}"
}

echo >> "${OUTFILE}"
echo "Done." >> "${OUTFILE}"

# Optional: symlink a convenience path
ln -sf "${OUTFILE}" /var/www/site/scan.txt
