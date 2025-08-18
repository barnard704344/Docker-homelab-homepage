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

### 3) Run (publish to host port 8080)
Stop/remove any existing container:
```bash
docker stop homelab-homepage 2>/dev/null || true
docker rm   homelab-homepage 2>/dev/null || true
```

Run with a single subnet and **scheduled scans every 10 minutes**:
```bash
docker run -d   --name homelab-homepage   -p 8080:80   -e SUBNETS="192.168.1.0/24"   -e SCAN_INTERVAL=10   homelab-homepage
```

> Access: `http://<HOST_LAN_IP>:8080/` (e.g., `http://192.168.1.20:8080/`)

#### Alternatives
- **Single scan at startup only** (no schedule):
  ```bash
  docker run -d     --name homelab-homepage     -p 8080:80     -e SUBNETS="192.168.1.0/24"     -e RUN_SCAN_ON_START=1     homelab-homepage
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
- Host: [http://localhost:8080](http://localhost:8080)
- LAN: `http://<HOST_LAN_IP>:8080/` (e.g., `http://192.168.1.20:8080/`)

---

## 📄 License
MIT
