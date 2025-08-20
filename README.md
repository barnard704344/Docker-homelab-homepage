# Docker Homelab Homepage

A self-hosted homepage that automatically discovers services on your network using a Docker container (built on Alpine Linux) + nginx + PHP + nmap. Features automatic network scanning, service categorization, port management, and a clean web interface.

## Features

### 🔍 **Automatic Network Discovery**
- Scans your network subnet using nmap to discover running services
- Detects 40+ common service ports (HTTP, HTTPS, SSH, DNS, media servers, etc.)
- Real-time service status checking
- Automatic protocol detection (HTTP/HTTPS/TCP/SSH)

### 🏷️ **Service Management**
- **Custom Categories**: Organize services into custom categories (Media, Network, Development, etc.)
- **Service Deletion**: Permanently delete services with one click - they'll be rediscovered fresh if they come back online
- **Custom Ports**: Add additional ports for scanning beyond the default set
- **Port Selection**: Choose which port to use when services run on multiple ports
- **Service Pinning**: Pin frequently used services to the top

### 🎨 **Clean Web Interface** 
- Responsive grid layout with service cards
- Real-time service status indicators
- Setup page for configuration management
- Mobile-friendly design

### ⚙️ **Advanced Configuration**
- Persistent category assignments and custom ports

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
1. Visit the setup page to configure categories and custom ports
2. The container automatically scans on startup, or trigger manually with: `docker exec homepage /usr/local/bin/scan.sh`
3. Assign discovered services to categories
4. Customize service settings as needed

## Configuration

### Custom Ports
Add custom ports via the setup interface.

### Service Categories
Categories are automatically created and can be customized via the web interface.

## Default Port Detection

The scanner automatically detects these services:

| Ports | Service Type | Examples |
|-------|--------------|----------|
| 22 | SSH | OpenSSH |
| 53 | DNS | Pi-hole, AdGuard, Technitium |
| 80, 8080, 8000, 8008, 8090 | HTTP | Web servers, dashboards |
| 443, 8443, 9443 | HTTPS | Secure web services |
| 139, 445 | SMB/CIFS | File shares, NAS |
| 993, 995 | Secure Email | IMAPS, POP3S |
| 3389 | RDP | Windows Remote Desktop |
| 5432 | PostgreSQL | Database |
| 3306 | MySQL/MariaDB | Database |
| 6379 | Redis | Cache/Database |
| 8096 | Jellyfin | Media Server |
| 32400 | Plex | Media Server |
| And many more... | | |

## File Structure

```
Docker-homelab-homepage/
├── Dockerfile              # Container definition
├── nginx.conf             # Nginx web server config
├── setup.sh               # Build and run script
├── start.sh               # Container startup script
├── scan.sh                # Network scanning logic
├── parse-scan.sh          # Scan result parser
├── ports.map              # Default port definitions
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
  - `action=delete_service` - Permanently delete a service

## Updating

If you encounter git errors or `git pull` fails, you can rebuild the container from scratch:

```bash
```bash
docker stop homepage
docker rm homepage
```

To rebuild and update with newer image versions:
```bash
docker rmi homepage

# Fresh clone and rebuild
cd ..
rm -rf Docker-homelab-homepage
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
bash setup.sh
```

---

**Note**: This homepage is designed for internal network use. It automatically scans and catalogs services on your network, so ensure you're comfortable with the security implications for your environment.