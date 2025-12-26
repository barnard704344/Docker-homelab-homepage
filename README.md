# Docker Homelab Homepage

A self-hosted homepage that discovers services on your network using nmap. Built with Docker (Alpine Linux), nginx, PHP, and vanilla JavaScript. Features manual network scanning, persistent service tracking, and server-side storage for cross-device access.

## Features

- **🔍 Manual Network Scanning** - Scan when you want via the web UI button
- **💾 Persistent Storage** - Services, pins, and settings survive container rebuilds
- **📱 Cross-Device Sync** - All configuration stored server-side, accessible from any device
- **🏷️ Custom Categories** - Organize services into categories via the setup page
- **📌 Service Pinning** - Pin frequently used services for quick access
- **🗑️ Manual Deletion** - Delete services permanently; missing services are preserved until you remove them
- **🔌 Multi-Port Support** - Select which port to use when services have multiple ports

## Quick Start

### Using Docker Compose (Recommended)

```bash
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage

# Edit docker-compose.yml to set your SUBNETS
docker-compose up -d --build
```

### Using setup.sh

```bash
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
bash setup.sh
```

### Access

- **Homepage**: http://your-server-ip
- **Setup Page**: http://your-server-ip/setup.html

## Configuration

### Environment Variables

Set these in `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `SUBNETS` | `192.168.1.0/24` | Network(s) to scan (space-separated for multiple) |
| `RUN_SCAN_ON_START` | `0` | Set to `1` to scan when container starts |
| `SCAN_INTERVAL` | `0` | Auto-scan interval in minutes (0 = disabled) |

### Port Scanning

Edit `ports.map` to customize which ports are scanned:

```csv
# port,scheme,tag,desc
80,http,web,HTTP
443,https,web,HTTPS
8080,http,web,Alt HTTP
```

Additional ports can be added via the setup page.

## Updating

```bash
cd Docker-homelab-homepage
git pull
docker-compose down
docker-compose up -d --build
```

Your data in `./data/` is preserved across rebuilds.

## File Structure

```
Docker-homelab-homepage/
├── docker-compose.yml     # Container configuration
├── Dockerfile             # Container build definition
├── nginx.conf             # Web server config
├── start.sh               # Container entrypoint
├── scan.sh                # Network scanner
├── parse-scan.sh          # Scan result parser
├── cleanup-service.sh     # Service cleanup utility
├── ports.map              # Port scan configuration
├── data/                  # Persistent data (mounted volume)
│   ├── services.json
│   ├── pins.json
│   ├── port-selections.json
│   ├── categories.json
│   └── scan/
└── site/                  # Web interface
    ├── index.html         # Homepage
    ├── setup.html         # Configuration page
    ├── css/common.css     # Shared styles
    ├── js/utils.js        # Shared utilities
    └── *.php              # API endpoints
```

## How Scanning Works

| Scenario | Behavior |
|----------|----------|
| Service found | Updated with `last_seen` timestamp |
| Service not found | Marked as "missing" (kept in list with indicator) |
| Service deleted | Permanently removed, won't reappear on future scans |

Services never auto-delete. You control what stays and what goes.

## Troubleshooting

### Service not discovered
- Add the port to `ports.map` or via the setup page
- Click **Run Scan** on the homepage

### Service shows IP instead of hostname
- Ensure your DNS server has reverse DNS (PTR records)
- Check container DNS: `docker exec homelab-homepage cat /etc/resolv.conf`

### Container issues
```bash
# Check logs
docker logs homelab-homepage

# Restart
docker-compose restart

# Full rebuild
docker-compose down
docker-compose up -d --build
```

### Reset all data
```bash
docker exec homelab-homepage /usr/local/bin/cleanup-service.sh all --nuclear
# Then click Run Scan on homepage
```

---

**Note**: Designed for internal/homelab use. Scans your local network to discover services.
