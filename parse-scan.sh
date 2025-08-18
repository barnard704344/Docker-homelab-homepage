#!/usr/bin/env bash
set -e

# Parse nmap scan results and generate services.json for the homepage
SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "[discovery] Parsing scan results from ${SCAN_FILE}..."

if [[ ! -f "${SCAN_FILE}" ]]; then
    echo "[discovery] ERROR: No scan file found at ${SCAN_FILE}"
    echo "[]" > "${SERVICES_FILE}" || {
        echo "[discovery] ERROR: Cannot write to ${SERVICES_FILE}"
        exit 1
    }
    exit 1
fi

# Create services directory if it doesn't exist
mkdir -p "$(dirname "${SERVICES_FILE}")" || {
    echo "[discovery] ERROR: Cannot create directory $(dirname "${SERVICES_FILE}")"
    exit 1
}

echo "[discovery] Scan file size: $(wc -c < "${SCAN_FILE}") bytes"
echo "[discovery] Testing write permissions to $(dirname "${SERVICES_FILE}")..."

# Test write permissions
if ! touch "${SERVICES_FILE}.test" 2>/dev/null; then
    echo "[discovery] ERROR: Cannot write to $(dirname "${SERVICES_FILE}")"
    echo "[discovery] Directory permissions:"
    ls -la "$(dirname "${SERVICES_FILE}")" || true
    exit 1
else
    rm -f "${SERVICES_FILE}.test"
    echo "[discovery] Write permissions: OK"
fi

# Simple approach - extract named hosts with their open ports
services=()

echo "[discovery] Extracting named hosts and their ports..."
current_host=""
current_ip=""
current_ports=()

while IFS= read -r line || [[ -n "$line" ]]; do
    # Check for host header with hostname
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.+)\ \(([0-9.]+)\)$ ]]; then
        # Save previous host if it had valid data
        if [[ -n "$current_host" ]] && [[ ${#current_ports[@]} -gt 0 ]]; then
            ports_str=$(IFS=','; echo "${current_ports[*]}")
            services+=("$current_host|$current_ip|$ports_str")
            echo "[discovery] Saved: $current_host ($current_ip) - Ports: $ports_str"
        fi
        
        hostname="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        
        # Clean up hostname
        display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
        
        # Skip ESP devices and ensure we have a real hostname
        if [[ -n "$display_name" ]] && [[ ! "$display_name" =~ ^[0-9.]+$ ]] && [[ ! "$display_name" =~ ^ESP_ ]]; then
            current_host="$display_name"
            current_ip="$ip"
            current_ports=()
            echo "[discovery] Processing: $display_name ($ip)"
        else
            current_host=""
            current_ip=""
            current_ports=()
        fi
        
    elif [[ $line =~ ^Nmap\ scan\ report\ for\ ([0-9.]+)$ ]]; then
        # Save previous host if it had valid data
        if [[ -n "$current_host" ]] && [[ ${#current_ports[@]} -gt 0 ]]; then
            ports_str=$(IFS=','; echo "${current_ports[*]}")
            services+=("$current_host|$current_ip|$ports_str")
            echo "[discovery] Saved: $current_host ($current_ip) - Ports: $ports_str"
        fi
        
        # IP-only hosts - skip
        current_host=""
        current_ip=""
        current_ports=()
        
    elif [[ -n "$current_host" ]] && [[ $line =~ ^([0-9]+)/tcp[[:space:]]+open[[:space:]]+([^[:space:]]+) ]]; then
        # Found an open port for current host
        port="${BASH_REMATCH[1]}"
        service="${BASH_REMATCH[2]}"
        
        # Focus on web-related ports
        case $port in
            80|443|8080|8443|3000|5000|8000|8888|8009)
                current_ports+=("$port/$service")
                echo "[discovery]   Found web port: $port ($service)"
                ;;
            *)
                # Include other interesting ports but mark them
                case $service in
                    http*|https*)
                        current_ports+=("$port/$service")
                        echo "[discovery]   Found HTTP port: $port ($service)"
                        ;;
                esac
                ;;
        esac
    fi
done < "${SCAN_FILE}"

# Don't forget the last host
if [[ -n "$current_host" ]] && [[ ${#current_ports[@]} -gt 0 ]]; then
    ports_str=$(IFS=','; echo "${current_ports[*]}")
    services+=("$current_host|$current_ip|$ports_str")
    echo "[discovery] Saved final: $current_host ($current_ip) - Ports: $ports_str"
fi

echo "[discovery] Found ${#services[@]} named hosts"

if [[ ${#services[@]} -eq 0 ]]; then
    echo "[discovery] WARNING: No named hosts found, creating empty services file"
    echo "[]" > "${SERVICES_FILE}" || {
        echo "[discovery] ERROR: Cannot write empty array to ${SERVICES_FILE}"
        exit 1
    }
    exit 0
fi

# Create JSON file
echo "[discovery] Creating JSON file..."
{
    echo "["
    for i in "${!services[@]}"; do
        service_entry="${services[$i]}"
        IFS='|' read -r name ip ports <<< "$service_entry"
        
        # Add comma if not first entry
        if [[ $i -gt 0 ]]; then
            echo ","
        fi
        
        # Determine primary URL and build description
        primary_url="http://$ip"
        description="Auto-discovered: $ip"
        
        if [[ -n "$ports" ]]; then
            # Parse ports and find the best one for primary URL
            IFS=',' read -ra port_array <<< "$ports"
            port_descriptions=()
            
            for port_info in "${port_array[@]}"; do
                if [[ -n "$port_info" ]]; then
                    IFS='/' read -r port service <<< "$port_info"
                    port_descriptions+=("$port ($service)")
                    
                    # Set primary URL based on port priority
                    case $port in
                        80) primary_url="http://$ip" ;;
                        443) primary_url="https://$ip" ;;
                        8080|3000|5000|8000|8888|8009) 
                            if [[ "$primary_url" == "http://$ip" ]]; then
                                primary_url="http://$ip:$port"
                            fi
                            ;;
                    esac
                fi
            done
            
            # Build description with port info
            port_list=$(IFS=', '; echo "${port_descriptions[*]}")
            description="Auto-discovered: $ip - Ports: $port_list"
        fi
        
        # Simple JSON entry - escape quotes in names
        escaped_name=$(echo "$name" | sed 's/"/\\"/g')
        escaped_desc=$(echo "$description" | sed 's/"/\\"/g')
        
        printf '  {\n    "title": "%s",\n    "url": "%s",\n    "group": "Discovered",\n    "desc": "%s",\n    "tags": ["discovered", "nmap"]\n  }' "$escaped_name" "$primary_url" "$escaped_desc"
    done
    echo
    echo "]"
} > "${SERVICES_FILE}" || {
    echo "[discovery] ERROR: Failed to write JSON to ${SERVICES_FILE}"
    exit 1
}

# Validate JSON
if command -v jq >/dev/null 2>&1; then
    if jq . "${SERVICES_FILE}" >/dev/null 2>&1; then
        echo "[discovery] JSON validation: OK"
    else
        echo "[discovery] ERROR: Invalid JSON generated"
        cat "${SERVICES_FILE}"
        exit 1
    fi
else
    echo "[discovery] jq not available, skipping JSON validation"
fi

# Set permissions
chown nginx:nginx "${SERVICES_FILE}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE}" 2>/dev/null || true

echo "[discovery] SUCCESS: Generated ${#services[@]} services"
echo "[discovery] File: ${SERVICES_FILE} ($(wc -c < "${SERVICES_FILE}") bytes)"
echo "[discovery] Content preview:"
head -10 "${SERVICES_FILE}" | sed 's/^/[discovery]   /'
