#!/usr/bin/env bash

# DNS Cache Clear and Force Refresh Script
echo "=== Clearing DNS Cache and Forcing Refresh ==="

# Clear any potential DNS cache
echo "1. Clearing potential DNS cache..."
echo > /etc/hosts 2>/dev/null || true

# Clear old scan results to force fresh discovery
echo "2. Clearing old scan results..."
rm -f /var/www/site/data/scan/last-scan.txt 2>/dev/null || true
rm -f /var/www/site/scan.txt 2>/dev/null || true

# Optional: Clear services.json to force complete rediscovery
echo "3. Backing up current services..."
if [[ -f "/var/www/site/data/services.json" ]]; then
    cp /var/www/site/data/services.json /var/www/site/data/services.json.backup.$(date +%s)
    echo "Backup created: services.json.backup.$(date +%s)"
fi

echo "4. Running fresh scan with DNS resolution..."
/usr/local/bin/scan.sh

echo "5. Done! Check the homepage to see if hostnames are updated."
