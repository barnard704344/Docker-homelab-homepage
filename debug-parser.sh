#!/usr/bin/env bash

# Debug script to test the parser manually
echo "=== Parser Debug Script ==="
echo "Date: $(date)"
echo

# Check if running in container
if [[ -f /.dockerenv ]]; then
    echo "Running inside Docker container: YES"
else
    echo "Running inside Docker container: NO"
fi

echo
echo "=== File System Status ==="
SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "Scan file: $SCAN_FILE"
if [[ -f "$SCAN_FILE" ]]; then
    echo "  EXISTS: $(wc -c < "$SCAN_FILE") bytes"
    echo "  First 5 lines:"
    head -5 "$SCAN_FILE" | sed 's/^/    /'
else
    echo "  NOT FOUND"
fi

echo
echo "Services file: $SERVICES_FILE"
if [[ -f "$SERVICES_FILE" ]]; then
    echo "  EXISTS: $(wc -c < "$SERVICES_FILE") bytes"
    echo "  Content:"
    cat "$SERVICES_FILE" | sed 's/^/    /'
else
    echo "  NOT FOUND"
fi

echo
echo "Directory permissions:"
ls -la /var/www/site/ || echo "Directory not accessible"

echo
echo "=== Running Parser ==="
if [[ -x /usr/local/bin/parse-scan.sh ]]; then
    echo "Parser found at /usr/local/bin/parse-scan.sh"
    /usr/local/bin/parse-scan.sh
else
    echo "Parser NOT found at /usr/local/bin/parse-scan.sh"
    echo "Looking for parser scripts..."
    find / -name "parse-scan.sh" -type f 2>/dev/null || echo "No parse-scan.sh found anywhere"
fi

echo
echo "=== Final Status ==="
if [[ -f "$SERVICES_FILE" ]]; then
    echo "Services file size after parsing: $(wc -c < "$SERVICES_FILE") bytes"
    if command -v jq >/dev/null 2>&1; then
        service_count=$(jq length "$SERVICES_FILE" 2>/dev/null || echo "invalid JSON")
        echo "Number of services: $service_count"
    fi
else
    echo "Services file was not created"
fi
