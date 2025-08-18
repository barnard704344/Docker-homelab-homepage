# Homelab Homepage (Docker)

A lightweight **network‑scanning homepage** for your homelab.  
Served by **Nginx** with **PHP-FPM**, featuring an interactive homepage with service liTail container logs:
```bash
docker logs -f homepage
```

Confirm it's running:
```bash
docker ps --filter name=homepage
```

Test nginx from inside the container:
```bash
docker exec homepage curl -v http://127.0.0.1/
``` scanner (`nmap`), and **automatic service discovery** from network scans.

---

## 📦 Features
- **Interactive homepage** with service management, search, and status monitoring
- **On-demand scanning** via web interface button (no SSH required!)
- **Automatic service discovery** - scans detect and add web services automatically
- **Enhanced debugging** with built-in diagnostic tools
- Links to scan results directly from the homepage
- Auto‑generated scan reports using **nmap** with enhanced parsing
- **Host networking support** for reliable network scanning
- Configurable scanning:
  - `SUBNETS` — one or more space‑separated subnets (default: `192.168.1.0/24`)
  - `RUN_SCAN_ON_START=1` — run a scan once at container start
  - `SCAN_INTERVAL=<minutes>` — run scans on a schedule (e.g., `10` = every 10 minutes)
- Service status monitoring with visual indicators
- Pinnable services and search functionality

---

## 🎯 Homepage Features

### Service Management
- **Service Cards**: Pre-configured links to common homelab services (Proxmox, Portainer)
- **Status Indicators**: Live status dots showing service availability (green = online, red = offline)
- **Search**: Press `/` or use the search box to find services quickly
- **Pin Services**: Use 📌 button to pin frequently used services
- **Groups**: Services organized by categories (Core, Monitoring, Discovered, etc.)

### Network Monitoring
- **Scan Results Links**: Direct access to latest and timestamped scan files
- **On-Demand Scanning**: "🔍 Run Scan" button for instant network scans
- **Automatic Service Discovery**: Scans automatically detect web services and add them to homepage
- **Smart Parsing**: Identifies services running on ports 80, 443, 8080, 3000, 5000, 8000, 8888, etc.
- **Named Host Detection**: Only discovers devices with proper hostnames (skips IP-only devices)
- **Debug Tools**: Built-in diagnostic endpoints for troubleshooting

### Service Discovery
The homepage automatically discovers services from nmap scans:
- Detects web services on common ports (80, 443, 8080, 3000, 5000, 8000, 8888, 8009)
- Creates service cards for discovered services in the "Discovered" group
- Shows service URLs, descriptions, and status indicators
- Updates automatically after each scan completes

---

## 🚀 Quick Start

### 1) Clone
```bash
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
```

### 2) Build
```bash
docker build -t homelab-homepage .
```

### 3) Run (with host networking for network scanning)
**Important**: Use `--network host` for reliable network scanning capabilities.

Stop/remove any existing container:
```bash
docker stop homepage 2>/dev/null || true
docker rm   homepage 2>/dev/null || true
```

Run with host networking (recommended):
```bash
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homepage
```

> **Access**: `http://<HOST_LAN_IP>/` (e.g., `http://192.168.1.20/`) - Uses port 80 with host networking

#### Alternative Configurations
- **Port mapping** (network scanning may have limitations):
  ```bash
  docker run -d \
    --name homepage \
    -p 8080:80 \
    -e SUBNETS="192.168.1.0/24" \
    -e RUN_SCAN_ON_START=1 \
    homepage
  ```
- **Multiple subnets**:
  ```bash
  -e SUBNETS="192.168.1.0/24 10.72.28.0/22 10.136.40.0/24"
  ```

---

## 🔍 Scanning Features

### Web Interface Scanning
- **Click "🔍 Run Scan" button** on the homepage to trigger scans instantly
- No SSH access required - scan directly from your browser
- Real-time feedback with scan status indicators

### Scan Results Access
- **Homepage links**: Direct links to scan results in the "Monitoring" section
- Inside container: `/var/www/site/scan/last-scan.txt` (plus symlink `/var/www/site/scan.txt`)
- In browser:
  - `http://<HOST_LAN_IP>:8080/scan/last-scan.txt`
  - `http://<HOST_LAN_IP>:8080/scan.txt`

### Manual Command Line Scanning
Trigger a manual scan from command line:
```bash
docker exec homepage /usr/local/bin/scan.sh
```

Run the service discovery parser separately:
```bash
docker exec homepage /usr/local/bin/parse-scan.sh
```

---

## 🛠️ Debugging & Troubleshooting

### Built-in Debug Tools
The container includes several debugging tools:

**Debug endpoint** (check service discovery status):
```bash
curl http://localhost/debug.php
```

**Debug parser script** (comprehensive diagnostics):
```bash
docker exec homepage /usr/local/bin/debug-parser.sh
```

**Manual testing**:
```bash
# Check container logs
docker logs homepage

# Access container shell
docker exec -it homepage /bin/sh

# Check file permissions
docker exec homepage ls -la /var/www/site/

# Verify scan results
docker exec homepage cat /var/www/site/scan/last-scan.txt

# Check services.json
docker exec homepage cat /var/www/site/services.json
```

### Common Issues

**Services not appearing after scan:**
1. Check debug endpoint: `curl http://localhost/debug.php`
2. Run debug script: `docker exec homepage /usr/local/bin/debug-parser.sh`
3. Verify scan completed: `docker exec homepage ls -la /var/www/site/scan/`
4. Check services.json: `docker exec homepage cat /var/www/site/services.json`

**Network scanning not working:**
- Ensure you're using `--network host` for reliable network access
- Check SUBNETS environment variable matches your network
- Verify container can reach network: `docker exec homepage ping 8.8.8.8`

**Container not starting:**
- Check logs: `docker logs homepage`
- Verify no port conflicts: `ss -ltnp | grep ':80'`
- Ensure Docker has network access

### Container Logs
```bash
docker logs -f homelab-homepage
```

Confirm it’s running:
```bash
docker ps --filter name=homelab-homepage
```

Test nginx from inside the container:
```bash
docker exec -it homelab-homepage sh -lc "curl -v http://127.0.0.1/"
```

Open firewall if needed (Ubuntu/Debian with UFW):
```bash
sudo ufw allow 8080/tcp
```

If the port is busy:
```bash
ss -ltnp | grep ':8080 '
```

---

## 🔄 Rebuilding the Container

When you make changes to the code or want to update to the latest version:

### Method 1: Using Git (Recommended)
```bash
# On your development machine, commit and push changes
git add .
git commit -m "Update homepage features"
git push

# On your Docker host machine
git pull
docker stop homelab-homepage 2>/dev/null || true
docker rm homelab-homepage 2>/dev/null || true
docker build -t homelab-homepage .

# Restart with your preferred configuration (host networking recommended)
docker run -d \
  --name homelab-homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homelab-homepage
```

### Method 2: Manual File Transfer
```bash
# Transfer files to Docker host (adjust paths as needed)
scp -r /path/to/Docker-homelab-homepage/ user@docker-host:/path/to/project/

# On Docker host machine
cd /path/to/Docker-homelab-homepage
docker stop homelab-homepage 2>/dev/null || true
docker rm homelab-homepage 2>/dev/null || true
docker build -t homelab-homepage .
docker run -d --name homelab-homepage --network host -e SUBNETS="192.168.1.0/24" homelab-homepage
```

### Quick Rebuild Script
Create a `rebuild.sh` script on your Docker host:
```bash
#!/bin/bash
echo "Stopping existing container..."
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

echo "Rebuilding image..."
docker build -t homepage .

echo "Starting new container..."
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homepage

echo "Container rebuilt and started!"
docker ps --filter name=homepage
docker logs homepage
```

Make it executable and run:
```bash
chmod +x rebuild.sh
./rebuild.sh
```

---

## 🧹 Maintenance

Stop:
```bash
docker stop homepage
```

Remove:
```bash
docker rm homepage
```

Rebuild after changes:
```bash
docker build -t homepage .
```

Update run command to include your preferred `SUBNETS`, `RUN_SCAN_ON_START`, or `SCAN_INTERVAL`.

---

## 🌐 Access
- **Host networking**: `http://localhost/` or `http://<HOST_LAN_IP>/`
- **Port mapping**: `http://<HOST_LAN_IP>:8080/`

### Service URLs
- **Homepage**: `/`
- **Debug endpoint**: `/debug.php` 
- **Scan trigger**: `/run-scan.php`
- **Latest scan results**: `/scan.txt` or `/scan/last-scan.txt`

---

## 🧪 Development & Testing

For development and testing the service discovery functionality:

```bash
# Build and run with debugging enabled
docker build -t homepage .
docker run -d --name homepage --network host -e SUBNETS="192.168.1.0/24" homepage

# Test the discovery system
docker exec homepage /usr/local/bin/scan.sh
docker exec homepage /usr/local/bin/debug-parser.sh
curl http://localhost/debug.php

# Check logs for detailed output
docker logs homepage
```

---

## 📄 License
MIT
