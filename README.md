# Homelab Homepage (Docker)

A lightweight **network‑scanning homepage** for your homelab.  
Served by **Nginx** with **PHP-FPM**, featuring an interactive homepage with service links and a built‑in scanner (`nmap`) that can run **on-demand via web button**, **once at start**, or **on a schedule**.

---

## 📦 Features
- Interactive homepage with service management and search
- **On-demand scanning** via web interface button (no SSH required!)
- Links to scan results directly from the homepage
- Auto‑generated scan reports using **nmap**
- **Port publishing** (default example maps to host port **8080**)
- Configurable scanning:
  - `SUBNETS` — one or more space‑separated subnets (default set in `scan.sh`)
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
- **Dynamic Service Discovery**: Automatically discover services from scan results

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
Stop/remove any existing container:
```bash
docker stop homelab-homepage 2>/dev/null || true
docker rm   homelab-homepage 2>/dev/null || true
```

Run with host networking to enable network scanning:
```bash
docker run -d \
  --name homelab-homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homelab-homepage
```

> Access: `http://<HOST_LAN_IP>:80/` (e.g., `http://192.168.1.20/`) - Note: Port 80 when using host networking

#### Alternatives
- **Port mapping instead of host networking** (network scanning may not work):
  ```bash
  docker run -d \
    --name homelab-homepage \
    -p 8080:80 \
    -e SUBNETS="192.168.1.0/24" \
    -e RUN_SCAN_ON_START=1 \
    homelab-homepage
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
docker exec -it homelab-homepage /app/scan.sh
```

---

## 🛠️ Logs & Troubleshooting

Tail container logs:
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
docker stop homelab-homepage 2>/dev/null || true
docker rm homelab-homepage 2>/dev/null || true

echo "Rebuilding image..."
docker build -t homelab-homepage .

echo "Starting new container..."
docker run -d \
  --name homelab-homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homelab-homepage

echo "Container rebuilt and started!"
docker ps --filter name=homelab-homepage
```

Make it executable: `chmod +x rebuild.sh` and run: `./rebuild.sh`

---

## 🧹 Maintenance

Stop:
```bash
docker stop homelab-homepage
```

Remove:
```bash
docker rm homelab-homepage
```

Rebuild after changes:
```bash
docker build -t homelab-homepage .
```

Update run command to include your preferred `SUBNETS`, `RUN_SCAN_ON_START`, or `SCAN_INTERVAL`.

---

## 🌐 Access
- Host: [http://localhost](http://localhost) (when using --network host)
- LAN: `http://<HOST_LAN_IP>/` (e.g., `http://192.168.1.20/`)
- Alternative with port mapping: `http://<HOST_LAN_IP>:8080/`

---

## 📄 License
MIT
