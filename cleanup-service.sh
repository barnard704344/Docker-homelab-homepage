#!/usr/bin/env bash

# Complete Service Cleanup Script
# Usage: ./cleanup-service.sh [service_name] [--nuclear]
# This script completely removes all traces of a service for fresh rediscovery

set -euo pipefail

SERVICE_NAME="${1:-}"
NUCLEAR="${2:-}"

if [[ -z "$SERVICE_NAME" ]]; then
    echo "Usage: $0 <service_name> [--nuclear]"
    echo ""
    echo "Examples:"
    echo "  $0 homelab          # Remove specific service 'homelab'"
    echo "  $0 all --nuclear    # Nuclear option: clear everything"
    echo ""
    exit 1
fi

echo "=== Complete Service Cleanup ==="
echo "Target: $SERVICE_NAME"
echo "Date: $(date)"
echo

cleanup_results=()

if [[ "$SERVICE_NAME" == "all" && "$NUCLEAR" == "--nuclear" ]]; then
    echo "🚨 NUCLEAR OPTION: Clearing ALL service data..."
    echo "This will remove all discovered services and force complete rediscovery."
    echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
    sleep 5
    
    # Nuclear cleanup - remove all service data
    files_to_remove=(
        "/var/www/site/services.json"
        "/var/www/site/data/services.json"
        "/var/www/site/data/service-assignments.json"
        "/var/www/site/data/categories.json"
        "/var/www/site/data/scan/last-scan.txt"
        "/var/www/site/scan.txt"
        "/var/www/site/data/scan.txt"
    )
    
    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            cleanup_results+=("Removed: $file")
            echo "✓ Removed: $file"
        fi
    done
    
    # Clear scan directory
    if [[ -d "/var/www/site/data/scan" ]]; then
        rm -rf /var/www/site/data/scan/*
        cleanup_results+=("Cleared scan directory")
        echo "✓ Cleared scan directory"
    fi
    
else
    echo "🧹 Cleaning up service: $SERVICE_NAME"
    
    # Remove from services.json files
    for services_file in "/var/www/site/services.json" "/var/www/site/data/services.json"; do
        if [[ -f "$services_file" ]]; then
            # Create backup
            cp "$services_file" "${services_file}.backup.$(date +%s)"
            
            # Remove service using jq if available, otherwise use PHP fallback
            if command -v jq >/dev/null 2>&1; then
                temp_file=$(mktemp)
                jq --arg service "$SERVICE_NAME" 'map(select(.title != $service))' "$services_file" > "$temp_file"
                mv "$temp_file" "$services_file"
                cleanup_results+=("Removed from $(basename $services_file)")
                echo "✓ Removed from $(basename $services_file)"
            else
                # PHP fallback for JSON manipulation
                php -r "
                \$file = '$services_file';
                \$serviceName = '$SERVICE_NAME';
                if (file_exists(\$file)) {
                    \$services = json_decode(file_get_contents(\$file), true) ?: [];
                    \$services = array_filter(\$services, function(\$service) use (\$serviceName) {
                        return \$service['title'] !== \$serviceName;
                    });
                    file_put_contents(\$file, json_encode(array_values(\$services), JSON_PRETTY_PRINT));
                }
                "
                cleanup_results+=("Removed from $(basename $services_file)")
                echo "✓ Removed from $(basename $services_file)"
            fi
        fi
    done
    
    # Remove from service assignments
    assignments_file="/var/www/site/data/service-assignments.json"
    if [[ -f "$assignments_file" ]]; then
        cp "$assignments_file" "${assignments_file}.backup.$(date +%s)"
        
        if command -v jq >/dev/null 2>&1; then
            temp_file=$(mktemp)
            jq --arg service "$SERVICE_NAME" 'del(.[$service])' "$assignments_file" > "$temp_file"
            mv "$temp_file" "$assignments_file"
        else
            # PHP fallback
            php -r "
            \$file = '$assignments_file';
            \$serviceName = '$SERVICE_NAME';
            if (file_exists(\$file)) {
                \$assignments = json_decode(file_get_contents(\$file), true) ?: [];
                unset(\$assignments[\$serviceName]);
                file_put_contents(\$file, json_encode(\$assignments, JSON_PRETTY_PRINT));
            }
            "
        fi
        cleanup_results+=("Removed category assignment")
        echo "✓ Removed category assignment"
    fi
    
    # Clear scan cache to force fresh discovery
    scan_files=(
        "/var/www/site/data/scan/last-scan.txt"
        "/var/www/site/scan.txt" 
        "/var/www/site/data/scan.txt"
    )
    
    for scan_file in "${scan_files[@]}"; do
        if [[ -f "$scan_file" ]]; then
            rm -f "$scan_file"
            cleanup_results+=("Cleared scan cache: $(basename $scan_file)")
            echo "✓ Cleared scan cache: $(basename $scan_file)"
        fi
    done
fi

echo
echo "🧹 Cleanup Summary:"
for result in "${cleanup_results[@]}"; do
    echo "  - $result"
done

echo
echo "🔄 Next steps:"
echo "1. Run a fresh scan: docker exec homelab-homepage /usr/local/bin/scan.sh"
echo "2. Or trigger via web interface: http://your-server/setup.html"
echo "3. The service will be rediscovered with fresh DNS resolution"

# Log the cleanup
echo "[$(date)] Complete cleanup performed: $(IFS=', '; echo "${cleanup_results[*]}")" >> /var/log/service-cleanup.log 2>/dev/null || true

echo
echo "✅ Cleanup complete!"
