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
        
        # Determine primary URL and build description with port data
        primary_url="http://$ip"
        description="Auto-discovered: $ip"
        available_ports=[]
        
        if [[ -n "$ports" ]]; then
            # Parse ports and build available ports array
            IFS=',' read -ra port_array <<< "$ports"
            port_descriptions=()
            
            for port_info in "${port_array[@]}"; do
                if [[ -n "$port_info" ]]; then
                    IFS='/' read -r port service <<< "$port_info"
                    port_descriptions+=("$port ($service)")
                    
                    # Add to available ports with URL
                    case $port in
                        80) 
                            primary_url="http://$ip"
                            available_ports+=("80:http://$ip")
                            ;;
                        443) 
                            primary_url="https://$ip"
                            available_ports+=("443:https://$ip")
                            ;;
                        22)
                            available_ports+=("22:ssh://$ip:22")
                            ;;
                        21)
                            available_ports+=("21:ftp://$ip:21")
                            ;;
                        23)
                            available_ports+=("23:telnet://$ip:23")
                            ;;
                        25)
                            available_ports+=("25:smtp://$ip:25")
                            ;;
                        53)
                            available_ports+=("53:dns://$ip:53")
                            ;;
                        110)
                            available_ports+=("110:pop3://$ip:110")
                            ;;
                        143)
                            available_ports+=("143:imap://$ip:143")
                            ;;
                        993)
                            available_ports+=("993:imaps://$ip:993")
                            ;;
                        995)
                            available_ports+=("995:pop3s://$ip:995")
                            ;;
                        3128)
                            available_ports+=("3128:http://$ip:3128")
                            ;;
                        *) 
                            # For all other ports, try to determine protocol from service
                            case $service in
                                http*|*http*|web*)
                                    available_ports+=("$port:http://$ip:$port")
                                    if [[ "$primary_url" == "http://$ip" ]]; then
                                        primary_url="http://$ip:$port"
                                    fi
                                    ;;
                                https*|*https*)
                                    available_ports+=("$port:https://$ip:$port")
                                    if [[ "$primary_url" == "http://$ip" ]]; then
                                        primary_url="https://$ip:$port"
                                    fi
                                    ;;
                                ssh)
                                    available_ports+=("$port:ssh://$ip:$port")
                                    ;;
                                ftp)
                                    available_ports+=("$port:ftp://$ip:$port")
                                    ;;
                                telnet)
                                    available_ports+=("$port:telnet://$ip:$port")
                                    ;;
                                smtp)
                                    available_ports+=("$port:smtp://$ip:$port")
                                    ;;
                                *)
                                    # Default to http for unknown services on common web ports
                                    if [[ $port -gt 1000 ]] && [[ $port -lt 10000 ]]; then
                                        available_ports+=("$port:http://$ip:$port")
                                        if [[ "$primary_url" == "http://$ip" ]]; then
                                            primary_url="http://$ip:$port"
                                        fi
                                    else
                                        # For system ports, just show the raw port
                                        available_ports+=("$port:tcp://$ip:$port")
                                    fi
                                    ;;
                            esac
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
        
        # For IP-only hosts, use a more descriptive title
        if [[ "$name" =~ ^[0-9.]+$ ]]; then
            # This is an IP-only host, make the title more descriptive
            if [[ -n "$ports" ]]; then
                # Use the first service type for a better title
                IFS=',' read -ra port_array <<< "$ports"
                first_port_info="${port_array[0]}"
                IFS='/' read -r first_port first_service <<< "$first_port_info"
                
                case $first_service in
                    http*) service_type="Web Server" ;;
                    https*) service_type="Secure Web Server" ;;
                    ssh) service_type="SSH Server" ;;
                    *) service_type="Network Device" ;;
                esac
                
                escaped_name="$service_type ($name)"
            else
                escaped_name="Device ($name)"
            fi
        else
            # This is a named host (either original or resolved via DNS)
            escaped_name=$(echo "$name" | sed 's/"/\\"/g')
        fi
        
        printf '  {\n    "title": "%s",\n    "url": "%s",\n    "group": "Discovered",\n    "desc": "%s",\n    "tags": ["discovered", "nmap"],\n    "ports": [' "$escaped_name" "$primary_url" "$escaped_desc"
        
        # Add available ports as JSON array
        if [[ -n "$ports" ]]; then
            IFS=',' read -ra port_array <<< "$ports"
            for i in "${!port_array[@]}"; do
                port_info="${port_array[$i]}"
                if [[ -n "$port_info" ]]; then
                    IFS='/' read -r port service <<< "$port_info"
                    
                    # Determine URL for this port
                    case $port in
                        80) port_url="http://$ip" ;;
                        443) port_url="https://$ip" ;;
                        *) port_url="http://$ip:$port" ;;
                    esac
                    
                    if [[ $i -gt 0 ]]; then
                        printf ","
                    fi
                    printf '{"port":"%s","service":"%s","url":"%s"}' "$port" "$service" "$port_url"
                fi
            done
        fi
        
        printf ']\n  }'
    done
    echo
    echo "]"
} > "${SERVICES_FILE}" || {
    echo "[discovery] ERROR: Failed to write JSON to ${SERVICES_FILE}"
    exit 1
}

# Create compatibility copy in web root (don't fail if this doesn't work)
cp "${SERVICES_FILE}" "${SERVICES_FILE_COMPAT}" 2>/dev/null || true

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

# Set permissions for both files
chown nginx:nginx "${SERVICES_FILE}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE}" 2>/dev/null || true
chown nginx:nginx "${SERVICES_FILE_COMPAT}" 2>/dev/null || true
chmod 644 "${SERVICES_FILE_COMPAT}" 2>/dev/null || true

echo "[discovery] SUCCESS: Generated ${#services[@]} services"
echo "[discovery] File: ${SERVICES_FILE} ($(wc -c < "${SERVICES_FILE}") bytes)"
echo "[discovery] Content preview:"
head -10 "${SERVICES_FILE}" | sed 's/^/[discovery]   /'
