#!/usr/bin/env bash
set -euo pipefail

# Parse nmap scan results and generate services.json for the homepage
SCAN_FILE="/var/www/site/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/services.json"

echo "[discovery] Parsing scan results from ${SCAN_FILE}..."

if [[ ! -f "${SCAN_FILE}" ]]; then
    echo "[discovery] No scan file found, creating empty services.json"
    echo "[]" > "${SERVICES_FILE}"
    exit 0
fi

# Create services directory if it doesn't exist
mkdir -p "$(dirname "${SERVICES_FILE}")"

# Function to determine service type and port
get_service_info() {
    local port=$1
    local service=$2
    local protocol="http"
    local service_type="web"
    
    case $port in
        80) protocol="http"; service_type="web" ;;
        443) protocol="https"; service_type="web" ;;
        8080) protocol="http"; service_type="web" ;;
        8443) protocol="https"; service_type="web" ;;
        3000) protocol="http"; service_type="web" ;;
        5000) protocol="http"; service_type="web" ;;
        8000) protocol="http"; service_type="web" ;;
        8888) protocol="http"; service_type="web" ;;
        8009) protocol="http"; service_type="web" ;;
        22) protocol="ssh"; service_type="ssh" ;;
        *) 
            case $service in
                http*) protocol="http"; service_type="web" ;;
                https*) protocol="https"; service_type="web" ;;
                ssh) protocol="ssh"; service_type="ssh" ;;
                *) protocol="http"; service_type="unknown" ;;
            esac
            ;;
    esac
    
    echo "$protocol|$service_type"
}

# Use associative arrays to store services by host
declare -A host_services

# Parse scan results to extract hosts and their services
current_host=""
current_ip=""

while IFS= read -r line; do
    # Check for host header
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.+)\ \(([0-9.]+)\)$ ]]; then
        hostname="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        
        # Clean up hostname
        display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
        
        # Skip ESP devices and unnamed hosts
        if [[ -n "$display_name" ]] && [[ ! "$display_name" =~ ^[0-9.]+$ ]] && [[ ! "$display_name" =~ ^ESP_ ]]; then
            current_host="$display_name"
            current_ip="$ip"
            host_services["$current_host"]="$current_ip|"
        else
            current_host=""
            current_ip=""
        fi
        
    elif [[ $line =~ ^Nmap\ scan\ report\ for\ ([0-9.]+)$ ]]; then
        # IP-only hosts - skip for now
        current_host=""
        current_ip=""
        
    elif [[ -n "$current_host" ]] && [[ $line =~ ^([0-9]+)/tcp[[:space:]]+open[[:space:]]+([^[:space:]]+) ]]; then
        # Found an open port
        port="${BASH_REMATCH[1]}"
        service="${BASH_REMATCH[2]}"
        
        IFS='|' read -r protocol service_type <<< "$(get_service_info "$port" "$service")"
        
        # Only include web services for the main list
        if [[ "$service_type" == "web" ]]; then
            port_info="$port:$protocol:$service"
            host_services["$current_host"]="${host_services[$current_host]}$port_info,"
        fi
    fi
done < "${SCAN_FILE}"

echo "[discovery] Found ${#host_services[@]} hosts with services"

# Create a temporary file first
TEMP_FILE=$(mktemp)
trap "rm -f ${TEMP_FILE}" EXIT

# Generate JSON
{
    echo "["
    first_entry=true
    
    for host in "${!host_services[@]}"; do
        IFS='|' read -r ip ports <<< "${host_services[$host]}"
        
        # Remove trailing comma from ports
        ports="${ports%,}"
        
        # Skip hosts with no web services
        if [[ -z "$ports" ]]; then
            continue
        fi
        
        # Add comma separator
        if [[ "$first_entry" != true ]]; then
            echo ","
        fi
        first_entry=false
        
        # Determine primary service (prefer 80, 443, then lowest port)
        primary_port=""
        primary_protocol=""
        primary_service=""
        
        IFS=',' read -ra port_array <<< "$ports"
        for port_info in "${port_array[@]}"; do
            if [[ -n "$port_info" ]]; then
                IFS=':' read -r port proto svc <<< "$port_info"
                if [[ -z "$primary_port" ]] || [[ "$port" == "80" ]] || [[ "$port" == "443" ]]; then
                    primary_port="$port"
                    primary_protocol="$proto"
                    primary_service="$svc"
                fi
                # Prefer standard ports
                if [[ "$port" == "80" ]] || [[ "$port" == "443" ]]; then
                    break
                fi
            fi
        done
        
        # Build URL
        if [[ "$primary_port" == "80" ]]; then
            url="http://${ip}"
        elif [[ "$primary_port" == "443" ]]; then
            url="https://${ip}"
        else
            url="${primary_protocol}://${ip}:${primary_port}"
        fi
        
        # Build description with all available ports
        port_list=""
        IFS=',' read -ra port_array <<< "$ports"
        for port_info in "${port_array[@]}"; do
            if [[ -n "$port_info" ]]; then
                IFS=':' read -r port proto svc <<< "$port_info"
                if [[ -n "$port_list" ]]; then
                    port_list="$port_list, "
                fi
                port_list="$port_list$port ($svc)"
            fi
        done
        
        # Escape any special characters in host name
        escaped_host=$(echo "$host" | sed 's/"/\\"/g')
        
        # Generate JSON entry
        printf '  {\n    "title": "%s",\n    "url": "%s",\n    "group": "Discovered",\n    "desc": "Auto-discovered: %s - Ports: %s",\n    "tags": ["discovered", "nmap", "%s"]\n  }' \
            "$escaped_host" "$url" "$ip" "$port_list" "$primary_service"
        
        echo "[discovery] Added: $host ($ip) - Primary: $primary_port, All: $port_list"
    done
    
    echo
    echo "]"
} > "${TEMP_FILE}"

# Validate JSON before moving
if command -v jq >/dev/null 2>&1; then
    if ! jq . "${TEMP_FILE}" >/dev/null 2>&1; then
        echo "[discovery] ERROR: Generated invalid JSON"
        cat "${TEMP_FILE}"
        exit 1
    fi
fi

# Move to final location
mv "${TEMP_FILE}" "${SERVICES_FILE}"

# Set permissions (ignore errors if not running as root)
chown nginx:nginx "${SERVICES_FILE}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE}" 2>/dev/null || true

service_count=$(jq length "${SERVICES_FILE}" 2>/dev/null || echo "unknown")
echo "[discovery] Generated services.json with ${service_count} services"
echo "[discovery] File size: $(wc -c < "${SERVICES_FILE}") bytes"
