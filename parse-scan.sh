#!/usr/bin/env bash
set -e

# Parse nmap scan results and generate services.json for the homepage
SCAN_FILE="/var/www/site/data/scan/last-scan.txt"
SERVICES_FILE="/var/www/site/data/services.json"
# Also create services.json in the web root for backward compatibility
SERVICES_FILE_COMPAT="/var/www/site/services.json"

echo "[discovery] Parsing scan results from ${SCAN_FILE}..."

if [[ ! -f "${SCAN_FILE}" ]]; then
    echo "[discovery] ERROR: No scan file found at ${SCAN_FILE}"
    echo "[]" > "${SERVICES_FILE}" || {
        echo "[discovery] ERROR: Cannot write empty array to ${SERVICES_FILE}"
        exit 1
    }
    # Also create compatibility file
    echo "[]" > "${SERVICES_FILE_COMPAT}" 2>/dev/null || true
    exit 1
fi

# Create services directory if it doesn't exist
mkdir -p "$(dirname "${SERVICES_FILE}")" || {
    echo "[discovery] ERROR: Cannot create directory $(dirname "${SERVICES_FILE}")"
    exit 1
}

# Also ensure web root directory exists for compatibility file
mkdir -p "$(dirname "${SERVICES_FILE_COMPAT}")" || {
    echo "[discovery] ERROR: Cannot create directory $(dirname "${SERVICES_FILE_COMPAT}")"
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

# Simple approach - extract hosts with their open ports
services=()

# Load custom ports to treat them as HTTP
declare -A custom_http_ports
CUSTOM_PORTS_FILE="/var/www/site/data/custom-ports.json"
if [[ -f "$CUSTOM_PORTS_FILE" ]]; then
    echo "[discovery] Loading custom HTTP ports..."
    if command -v jq >/dev/null 2>&1; then
        while IFS= read -r port; do
            if [[ -n "$port" ]]; then
                custom_http_ports["$port"]="1"
                echo "[discovery] Custom HTTP port: $port"
            fi
        done < <(jq -r '.[].port' "$CUSTOM_PORTS_FILE" 2>/dev/null || true)
    fi
fi

echo "[discovery] Extracting hosts and their ports..."
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
            echo "[discovery] Processing named host: $display_name ($ip)"
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
        
        # IP-only host - try reverse DNS lookup
        ip="${BASH_REMATCH[1]}"
        
        echo "[discovery] Found IP-only host: $ip, attempting reverse DNS lookup..."
        
        # Try reverse DNS lookup using nslookup or dig
        hostname=""
        if command -v nslookup >/dev/null 2>&1; then
            hostname=$(nslookup "$ip" 2>/dev/null | awk '/name =/ {print $4}' | sed 's/\.$//' | head -1)
        elif command -v dig >/dev/null 2>&1; then
            hostname=$(dig -x "$ip" +short 2>/dev/null | sed 's/\.$//' | head -1)
        elif command -v host >/dev/null 2>&1; then
            hostname=$(host "$ip" 2>/dev/null | awk '{print $5}' | sed 's/\.$//' | head -1)
        fi
        
        # Use hostname if found, otherwise use IP
        if [[ -n "$hostname" ]] && [[ "$hostname" != "$ip" ]] && [[ ! "$hostname" =~ ^[0-9.]+$ ]]; then
            # Clean up hostname
            display_name=$(echo "$hostname" | sed 's/\.islington\.local$//' | sed 's/\.local$//')
            current_host="$display_name"
            current_ip="$ip"
            echo "[discovery] Resolved $ip to: $display_name"
        else
            current_host="$ip"  # Use IP as the display name
            current_ip="$ip"
            echo "[discovery] No hostname found for $ip, using IP address"
        fi
        
        current_ports=()
        echo "[discovery] Processing IP-only host: $current_host ($ip)"
        
    elif [[ -n "$current_host" ]] && [[ $line =~ ^([0-9]+)/tcp[[:space:]]+open[[:space:]]+([^[:space:]]+) ]]; then
        # Found an open port for current host
        port="${BASH_REMATCH[1]}"
        service="${BASH_REMATCH[2]}"
        
        # Include all discovered ports
        current_ports+=("$port/$service")
        echo "[discovery]   Found port: $port ($service)"
    fi
done < "${SCAN_FILE}"

# Don't forget the last host
if [[ -n "$current_host" ]] && [[ ${#current_ports[@]} -gt 0 ]]; then
    ports_str=$(IFS=','; echo "${current_ports[*]}")
    services+=("$current_host|$current_ip|$ports_str")
    echo "[discovery] Saved final: $current_host ($current_ip) - Ports: $ports_str"
fi

echo "[discovery] Found ${#services[@]} services total"

# Convert to JSON format
json_services=()

# Load existing category assignments if they exist
declare -A category_assignments
declare -A category_names
if [[ -f "/var/www/site/data/service-assignments.json" ]]; then
    echo "[discovery] Loading existing category assignments..."
    if command -v jq >/dev/null 2>&1; then
        while IFS="=" read -r key value; do
            category_assignments["$key"]="$value"
        done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' /var/www/site/data/service-assignments.json 2>/dev/null || true)
    fi
fi

if [[ -f "/var/www/site/data/categories.json" ]]; then
    echo "[discovery] Loading category names..."
    if command -v jq >/dev/null 2>&1; then
        while IFS="=" read -r key value; do
            category_names["$key"]="$value"
        done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' /var/www/site/data/categories.json 2>/dev/null || true)
    fi
fi

for service_line in "${services[@]}"; do
    IFS='|' read -r host ip ports <<< "$service_line"
    
    # Split ports
    IFS=',' read -ra port_array <<< "$ports"
    port_descriptions=()
    available_ports=()
    primary_url=""
    
    for port_info in "${port_array[@]}"; do
        if [[ -n "$port_info" ]]; then
            IFS='/' read -r port service <<< "$port_info"
            port_descriptions+=("$port ($service)")
            
            # Determine URL based on port and service
            case $port in
                80) 
                    primary_url="http://$ip"
                    available_ports+=("$port:http://$ip")
                    ;;
                81) 
                    primary_url="http://$ip:$port"
                    available_ports+=("$port:http://$ip:$port")
                    ;;
                443) 
                    primary_url="https://$ip"
                    available_ports+=("$port:https://$ip")
                    ;;
                8080|8000|3000|5000|9000) 
                    if [[ -z "$primary_url" ]]; then
                        primary_url="http://$ip:$port"
                    fi
                    available_ports+=("$port:http://$ip:$port")
                    ;;
                8443|9443) 
                    if [[ -z "$primary_url" ]]; then
                        primary_url="https://$ip:$port"
                    fi
                    available_ports+=("$port:https://$ip:$port")
                    ;;
                22)
                    available_ports+=("$port:ssh://$ip:$port")
                    ;;
                53|5380)
                    # DNS servers - 53 is standard DNS, 5380 is Technitium DNS
                    if [[ $port == "5380" ]]; then
                        if [[ -z "$primary_url" ]]; then
                            primary_url="http://$ip:$port"
                        fi
                        available_ports+=("$port:http://$ip:$port")
                    else
                        available_ports+=("$port:dns://$ip:$port")
                    fi
                    ;;
                *)
                    # Default based on service name
                    case $service in
                        http*|*http*|web*)
                            if [[ -z "$primary_url" ]]; then
                                primary_url="http://$ip:$port"
                            fi
                            available_ports+=("$port:http://$ip:$port")
                            ;;
                        https*|*https*)
                            if [[ -z "$primary_url" ]]; then
                                primary_url="https://$ip:$port"
                            fi
                            available_ports+=("$port:https://$ip:$port")
                            ;;
                        *)
                            # Check if this is a custom HTTP port from setup page
                            if [[ -n "${custom_http_ports[$port]}" ]]; then
                                if [[ -z "$primary_url" ]]; then
                                    primary_url="http://$ip:$port"
                                fi
                                available_ports+=("$port:http://$ip:$port")
                            # Default to http for high ports, raw for system ports
                            elif [[ $port -gt 1000 ]]; then
                                if [[ -z "$primary_url" ]]; then
                                    primary_url="http://$ip:$port"
                                fi
                                available_ports+=("$port:http://$ip:$port")
                            else
                                available_ports+=("$port:tcp://$ip:$port")
                            fi
                            ;;
                    esac
                    ;;
            esac
        fi
    done
    
    # Set default URL if none found
    if [[ -z "$primary_url" ]]; then
        primary_url="http://$ip"
    fi
    
    # Determine service type and description
    service_type="Unknown"
    description="Network service"
    
    # Check if this service has a custom category assignment
    if [[ -n "${category_assignments[$host]}" ]]; then
        assigned_category="${category_assignments[$host]}"
        if [[ -n "${category_names[$assigned_category]}" ]]; then
            service_type="${category_names[$assigned_category]}"
            description="Custom assigned service"
            echo "[discovery] Using custom category for $host: $service_type"
        fi
    else
        # Default service type detection based on ports and hostname
        if [[ "$host" =~ plex|media ]]; then
            service_type="Media"
            description="Plex Media Server"
        elif [[ "$host" =~ jellyfin ]]; then
            service_type="Media" 
            description="Jellyfin Media Server"
        elif [[ "$host" =~ domoticz ]]; then
            service_type="Home Automation"
            description="Domoticz Home Automation"
        elif echo "$ports" | grep -q "53\|5380"; then
            service_type="Network"
            description="DNS Server"
        elif echo "$ports" | grep -q "443\|8443\|9443"; then
            service_type="Web Service"
            description="HTTPS Web Service"
        elif echo "$ports" | grep -q "80\|8080\|3000\|5000\|8000\|9000"; then
            service_type="Web Service"
            description="HTTP Web Service"
        elif echo "$ports" | grep -q "22"; then
            service_type="Server"
            description="SSH Server"
        fi
    fi
    
    # Create port objects for frontend
    ports_json=()
    for port_url in "${available_ports[@]}"; do
        IFS=':' read -r port_num url <<< "$port_url"
        ports_json+=("{\"port\": \"$port_num\", \"service\": \"$(echo "$service_line" | cut -d'/' -f2)\", \"url\": \"$url\"}")
    done
    ports_array="[$(IFS=','; echo "${ports_json[*]}")]"
    
    # Create the service JSON entry
    json_entry="{
        \"title\": \"$host\",
        \"url\": \"$primary_url\",
        \"group\": \"$service_type\",
        \"desc\": \"$description - $(IFS=' '; echo "${port_descriptions[*]}")\",
        \"tags\": [\"discovered\", \"$service_type\"],
        \"ports\": $ports_array
    }"
    
    json_services+=("$json_entry")
done

# Write JSON output with merge logic
echo "[discovery] Loading existing services for merge..."

# Load existing services if file exists
existing_services=()
if [[ -f "${SERVICES_FILE}" ]] && [[ -s "${SERVICES_FILE}" ]]; then
    if command -v jq >/dev/null 2>&1; then
        # Use jq to read existing services
        while IFS= read -r service; do
            if [[ -n "$service" ]]; then
                existing_services+=("$service")
            fi
        done < <(jq -c '.[]' "${SERVICES_FILE}" 2>/dev/null || echo "")
        echo "[discovery] Loaded ${#existing_services[@]} existing services"
    fi
fi

# Create associative array of new services by title for quick lookup
declare -A new_services_by_title
for service in "${json_services[@]}"; do
    if [[ -n "$service" ]]; then
        title=$(echo "$service" | jq -r '.title' 2>/dev/null || echo "")
        if [[ -n "$title" ]]; then
            new_services_by_title["$title"]="$service"
        fi
    fi
done

# Merge logic: update existing, keep offline, add new
merged_services=()

# First, process existing services
for existing_service in "${existing_services[@]}"; do
    if [[ -n "$existing_service" ]]; then
        title=$(echo "$existing_service" | jq -r '.title' 2>/dev/null || echo "")
        if [[ -n "$title" ]]; then
            if [[ -n "${new_services_by_title[$title]}" ]]; then
                # Service found in current scan - update it
                echo "[discovery] Updating existing service: $title"
                merged_services+=("${new_services_by_title[$title]}")
                # Remove from new services to avoid duplicates
                unset new_services_by_title["$title"]
            else
                # Service not in current scan - keep existing (offline)
                echo "[discovery] Keeping offline service: $title"
                merged_services+=("$existing_service")
            fi
        fi
    fi
done

# Add any new services that weren't in existing services
for title in "${!new_services_by_title[@]}"; do
    echo "[discovery] Adding new service: $title"
    merged_services+=("${new_services_by_title[$title]}")
done

# Generate final JSON
json_output="[$(IFS=','; echo "${merged_services[*]}")]"

echo "$json_output" | jq '.' > "${SERVICES_FILE}" 2>/dev/null || {
    echo "[discovery] WARNING: jq failed, writing raw JSON"
    echo "$json_output" > "${SERVICES_FILE}"
}

# Also write compatibility file
echo "$json_output" | jq '.' > "${SERVICES_FILE_COMPAT}" 2>/dev/null || {
    echo "$json_output" > "${SERVICES_FILE_COMPAT}"
}

echo "[discovery] ✓ Merged services: ${#merged_services[@]} total (${#json_services[@]} from current scan)"
echo "[discovery] ✓ Output written to: ${SERVICES_FILE}"
echo "[discovery] ✓ Compatibility file: ${SERVICES_FILE_COMPAT}"
