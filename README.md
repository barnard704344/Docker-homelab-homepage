# Docker Homelab Homepage

A self-hosted homepage that discovers services on your network using a Docker container (built on Alpine Linux) + nginx + PHP + nmap. Features manual network scanning, service categorization, port management, and a clean web interface with server-side configuration storage for cross-device access.

## Features

### 🔍 **Network Discovery**
- Manual network scan via web UI button - scan when you want, not automatically
- Configurable port scanning via `ports.map` file - easily add/remove ports
- Detects 40+ common service ports by default (HTTP, HTTPS, SSH, DNS, media servers, etc.)
- Real-time service status checking
- Automatic protocol detection (HTTP/HTTPS/TCP/SSH)

### 🏷️ **Service Management**
- **Custom Categories**: Organize services into custom categories (Media, Network, Development, etc.)
- **Service Deletion**: Permanently delete services with one click - they'll be rediscovered fresh if they come back online
- **Custom Ports**: Add additional ports for scanning beyond the default set
- **Port Selection**: Choose which port to use when services run on multiple ports
- **Service Pinning**: Pin frequently used services to the top

### 💾 **Cross-Device Configuration**
- All settings stored on the server (not in browser localStorage)
- Pins, port selections, and categories sync across all devices
- View your customized homepage from any computer or device

### 🎨 **Clean Web Interface** 
- Responsive grid layout with service cards
- Real-time service status indicators
- Setup page for configuration management
- Mobile-friendly design

### ⚙️ **Advanced Configuration**
- Persistent category assignments and custom ports
- Optional auto-scan via environment variables

## Quick Start

### Prerequisites
- Docker
- Network access to scan your subnet

### 1. Clone and Run
```bash
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
bash setup.sh
```

### 2. Access the Interface
- **Homepage**: http://your-server-ip
- **Setup Page**: http://your-server-ip/setup.html

### 3. First-Time Setup
1. Visit the homepage and click the **🔍 Run Scan** button to discover services
2. Visit the setup page to configure categories and custom ports
3. Assign discovered services to categories
4. Pin your favorite services - they'll be available from any device!

### Environment Variables (Optional)
```bash
# Set these in docker-compose.yml or docker run command
SUBNETS="192.168.1.0/24"          # Network(s) to scan (space-separated for multiple)
RUN_SCAN_ON_START=1               # Set to 1 to run a scan when container starts
SCAN_INTERVAL=60                  # Auto-scan every N minutes (0 to disable)
```

## Configuration

### Port Scanning Customization
The scanner uses the `ports.map` file to determine which ports to scan. You can customize this by editing the CSV file:

```csv
# port,scheme,tag,desc
80,http,web,HTTP
81,http,web,NPM
443,https,web,HTTPS
# Add your custom ports here...
```

- **port**: Port number to scan
- **scheme**: Protocol (http/https/tcp/ssh/ftp/dns)
- **tag**: Service category (web/admin/database/docker/media/etc.)
- **desc**: Human-readable description

The scanner will automatically use ports defined in `ports.map`. If the file is missing or corrupted, it falls back to a hardcoded list.

### Custom Ports
You can also add additional custom ports via the setup interface, which supplements the `ports.map` configuration.

### Service Categories
Categories are automatically created and can be customized via the web interface.

## File Structure

```
Docker-homelab-homepage/
├── Dockerfile              # Container definition
├── nginx.conf             # Nginx web server config
├── setup.sh               # Build and run script
├── start.sh               # Container startup script
├── scan.sh                # Network scanning logic
├── parse-scan.sh          # Scan result parser
├── ports.map              # Port scanning configuration (CSV format)
├── debug.php              # Debug utilities
├── run-scan.php           # Scan trigger endpoint
├── site/                  # Web interface files
│   ├── index.html         # Main homepage
│   ├── setup.html         # Configuration interface
│   └── setup-data.php     # Backend API
└── data/                  # Persistent data directory
    ├── services.json      # Discovered services
    ├── categories.json    # Service categories
    ├── service-assignments.json  # Category assignments
    ├── custom-ports.json  # User-defined ports
    └── scan/              # Scan results and logs
```

## API Endpoints

### Service Management
- `POST /setup-data.php` - Main API endpoint
  - `action=get_services` - Get all discovered services
  - `action=save_assignments` - Save service category assignments
  - `action=save_categories` - Save category definitions
  - `action=save_custom_ports` - Save custom scanning ports
  - `action=delete_service` - Permanently delete a service (with complete cleanup)

## Troubleshooting

### Service Discovery Issues

#### Problem: Service shows old/incorrect hostname
**Cause**: DNS caching or stale service data

**Solutions**:
```bash
# Option 1: Delete service via web interface (automatic cleanup)
# Go to homepage → Delete service → Click "Run Scan" to trigger fresh discovery

# Option 2: Manual cleanup and rescan
docker exec homepage /usr/local/bin/cleanup-service.sh "old-hostname"
docker exec homepage /usr/local/bin/scan.sh
```

#### Problem: Service not being discovered
**Cause**: Port not in scan list or network connectivity issues

**Solutions**:
```bash
# Add missing port to ports.map or via web interface setup page
# Then run a new scan from the web UI or manually:
docker exec homepage /usr/local/bin/scan.sh
```

#### Problem: Multiple services have incorrect data
**Cause**: Widespread caching or configuration issues

**Solution**: Nuclear option (clears all service data)
```bash
docker exec homepage /usr/local/bin/cleanup-service.sh all --nuclear
# Then click "Run Scan" on homepage or run: docker exec homepage /usr/local/bin/scan.sh
```

### DNS Resolution Issues

#### Problem: Services show IP addresses instead of hostnames
**Cause**: Reverse DNS not configured or not accessible

**Solutions**:
1. Ensure your DNS server has reverse DNS (PTR records) configured
2. Check container can reach your DNS server:
```bash
docker exec homepage cat /etc/resolv.conf
```
3. Restart container for complete DNS reset:
```bash
docker restart homepage
```

### Manual Cleanup Commands

| Issue | Command |
|-------|---------|
| One service has wrong data | `docker exec homepage /usr/local/bin/cleanup-service.sh "service-name"` |
| Start completely fresh | `docker exec homepage /usr/local/bin/cleanup-service.sh all --nuclear` |
| Force new scan | `docker exec homepage /usr/local/bin/scan.sh` |

### Container Issues

#### Problem: Scans not working or permissions errors
```bash
# Check container logs
docker logs homepage

# Restart container
docker restart homepage

# Rebuild if needed
cd Docker-homelab-homepage
bash setup.sh
```

#### Problem: Web interface not loading
```bash
# Check if container is running
docker ps | grep homepage

# Check port binding
docker port homepage

# Restart container
docker restart homepage
```

## Updating

If you encounter git errors or `git pull` fails, you can rebuild the container from scratch:

```bash
# Stop and remove the existing container
docker stop homepage
docker rm homepage

# Remove the old image (optional but recommended)
docker rmi homelab-homepage

# Fresh clone and rebuild
cd ..
rm -rf Docker-homelab-homepage
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
bash setup.sh
```

---

**Note**: This homepage is designed for internal network use. It automatically scans and catalogs services on your network, so ensure you're comfortable with the security implications for your environment.