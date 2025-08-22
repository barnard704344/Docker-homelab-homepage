#!/usr/bin/env bash

# DNS Diagnostic Script for Homelab Homepage
# This script helps diagnose DNS resolution issues

echo "=== DNS Diagnostic Script ==="
echo "Date: $(date)"
echo

# Get the IP you're having issues with
IP="${1:-192.168.1.79}"
echo "Testing IP: $IP"
echo

# Test DNS resolution methods
echo "1. Testing nslookup (primary method used by parser):"
if command -v nslookup >/dev/null 2>&1; then
    echo "Full nslookup output:"
    nslookup "$IP" || echo "nslookup failed"
    echo
    echo "Parsed hostname (what the parser sees):"
    hostname=$(nslookup "$IP" 2>/dev/null | awk '/name =/ {print $4}' | sed 's/\.$//' | head -1)
    echo "Result: '$hostname'"
else
    echo "nslookup not available"
fi
echo

echo "2. Testing dig (fallback method):"
if command -v dig >/dev/null 2>&1; then
    echo "Full dig output:"
    dig -x "$IP" +short || echo "dig failed"
    echo
    echo "Parsed hostname (what the parser sees):"
    hostname=$(dig -x "$IP" +short 2>/dev/null | sed 's/\.$//' | head -1)
    echo "Result: '$hostname'"
else
    echo "dig not available"
fi
echo

echo "3. Testing host (second fallback):"
if command -v host >/dev/null 2>&1; then
    echo "Full host output:"
    host "$IP" || echo "host failed"
    echo
    echo "Parsed hostname (what the parser sees):"
    hostname=$(host "$IP" 2>/dev/null | awk '{print $5}' | sed 's/\.$//' | head -1)
    echo "Result: '$hostname'"
else
    echo "host not available"
fi
echo

echo "4. Container DNS configuration:"
echo "DNS servers in /etc/resolv.conf:"
cat /etc/resolv.conf 2>/dev/null || echo "Cannot read /etc/resolv.conf"
echo

echo "5. Testing nmap DNS resolution (what scan.sh actually uses):"
echo "Running: nmap -sn -R $IP"
nmap -sn -R "$IP" 2>/dev/null || echo "nmap DNS test failed"
echo

echo "6. Checking /etc/hosts for static entries:"
echo "Local hosts file entries:"
grep -i "$IP\|$(echo $IP | cut -d. -f4)" /etc/hosts 2>/dev/null || echo "No matching entries in /etc/hosts"
echo

echo "7. Testing container's system resolver:"
echo "getent hosts $IP:"
getent hosts "$IP" 2>/dev/null || echo "No getent resolution"
echo

echo "8. Current services.json entries for this IP:"
if [[ -f "/var/www/site/data/services.json" ]]; then
    grep -i "$IP" /var/www/site/data/services.json || echo "IP not found in services.json"
else
    echo "services.json not found"
fi
echo

echo "=== Recommendations ==="
echo "If you see the old hostname above:"
echo "1. Clear DNS cache in the container: docker exec homepage sh -c 'echo > /etc/hosts'"
echo "2. Restart the container: docker restart homepage"
echo "3. Delete the service from the web interface and re-scan"
echo "4. Check your DNS server is properly configured"
