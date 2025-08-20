# Docker Homelab Homepage

A lightweight Docker container that provides a clean homepage for your homelab with automatic network service discovery, intelligent port detection, and advanced category management.

## ✨ Features

- **🏠 Clean Homepage**: Interactive service cards with status indicators
- **🔍 Smart Discovery**: Optimized nmap scanning of 43+ common homelab ports
- **🗂️ Category Management**: Advanced categorization system with persistent storage
- **📌 Persistent Pins**: Server-side pin storage that syncs across browsers
- **🔧 Smart Port Selection**: Clickable port buttons with persistent selection memory
- **📊 Live Scan Status**: Real-time scanning progress and completion indicators
- **💾 Persistent Data**: All data survives container rebuilds
- **🎯 One-Click Setup**: Single script handles everything automatically

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage

# Run the setup (handles everything automatically)
./setup.sh
```

That's it! Access your homepage at `http://localhost/` or `http://<your-server-ip>/`

## 🔄 Rebuilding & Updates

```bash
# Pull latest changes and rebuild
git pull
./setup.sh

# The setup script automatically:
# - Stops and removes old container
# - Builds fresh image with latest code  
# - Creates new container with proper permissions
# - Preserves all your data in ./data directory
```

## ⚙️ Configuration

The setup script automatically configures:
- **Network**: Scans `192.168.1.0/24` by default
- **Scanning**: Every 10 minutes automatically (optimized 90-second scans)
- **Storage**: Persistent data directory with proper Docker volume permissions
- **Category System**: Full category management with setup interface

### Management Interfaces
- **🔧 Setup Page**: `http://<your-ip>/setup.html` - Category management
- **🐛 Debug Info**: `http://<your-ip>/setup-debug.php` - Permission diagnostics

To customize scanning, edit environment variables in `setup.sh`:
```bash
-e SUBNETS="192.168.1.0/24 10.0.1.0/24"  # Multiple networks
-e SCAN_INTERVAL=15                        # Scan every 15 minutes
```

## 🔧 Usage

### Web Interface
- **🗂️ Categories**: Services organized by type (Network, Media, Home Automation, etc.)
- **📌 Pinned**: Toggle view of pinned services only
- **🔄 Refresh**: Reload services from scan results  
- **🔍 Scan Status**: Live indicator showing scan progress and last completion time
- **Port Buttons**: Click port numbers to access specific services (selections persist)

### Category Management
- **Setup Interface**: Access via `http://<your-ip>/setup.html`
- **Add Categories**: Create custom categories for your services
- **Assign Services**: Drag and drop or bulk assign services to categories
- **Persistent Storage**: All categories and assignments survive container rebuilds

## 💻 Smart Service Discovery

The optimized scanner targets 43 common homelab ports and automatically discovers:

### **🎬 Media Servers**
- **Jellyfin** (8096) - Open-source media streaming
- **Plex Media Server** (32400) - Popular media platform
- **TVHeadend** (9981) - TV streaming and recording

### **💾 Storage & Backup**
- **Synology DSM** (5000/5001) - Synology NAS management
- **QNAP QTS** (5000/5001) - QNAP NAS interface
- **TrueNAS/FreeNAS** (5000/5001) - ZFS storage management
- **Proxmox Backup Server** (8007) - Enterprise backup solution

### **📊 Monitoring & Observability**
- **Grafana** (3001) - Dashboards and visualization
- **Prometheus** (9090) - Metrics collection and alerting
- **InfluxDB** (8086) - Time-series database
- **Netdata** (19999) - Real-time system monitoring
- **Node Exporter** (9100) - System metrics

### **🚀 Development & Code**
- **Code-server** (32168, 8443) - VS Code in browser
- **Angular Dev Server** (4200) - Frontend development
- **Ollama AI** (11434) - Local LLM server
- **Various Dev Servers** (3000, 5000, 7000, 8000) - Node.js, Python, etc.

### **🖨️ 3D Printing & IoT**
- **Obico** (3334) - 3D printer monitoring
- **OctoPrint** (Auto-detected) - 3D printer management

### **🐳 Container Management**
- **Portainer** (9000) - Docker container management
- **Docker API** (2375/2376) - Docker daemon API

### **⚙️ System Management**
- **Proxmox VE** (8006) - Hypervisor management
- **Webmin** (10000) - System administration
- **SSH** (22) - Secure shell access

## 🗂️ File Structure

```
├── setup.sh              # Main setup script (use this!)
├── site/
│   ├── index.html         # Homepage interface with category system
│   ├── setup.html         # Category management interface
│   ├── setup-data.php     # Category management API
│   ├── setup-debug.php    # Permission diagnostics
│   └── pins.php           # Pin storage API
├── scan.sh                # Optimized network scanning (43 ports)
├── parse-scan.sh          # Convert scans to JSON with smart service detection
└── data/                  # Persistent storage (auto-created)
    ├── categories.json    # Custom categories
    ├── service-assignments.json # Service-to-category mappings
    ├── services.json      # Discovered services
    └── scan/              # Scan results
```

## ⚡ Performance Optimizations

### **Fast Scanning (90 seconds vs 10+ minutes)**
- **Targeted Ports**: Scans only 43 relevant homelab ports instead of 10,000+
- **Aggressive Timeouts**: 15s per host, 500ms RTT for maximum speed
- **Smart Recognition**: Automatically identifies service types and generates proper URLs

### **Persistent Storage**
- **Volume Mounting**: `./data:/var/www/site/data` survives container rebuilds
- **Cross-Browser Sync**: Categories, pins and port selections sync via server APIs
- **Automatic Permissions**: Docker volume mount permissions handled automatically

## 🔍 Advanced

### Manual Commands
```bash
# Check live scan status
curl http://localhost/scan-status.php

# View discovered services with categories
curl http://localhost/services.json

# Manage categories
curl http://localhost/setup-data.php?action=get_categories
```

### Container Management
```bash
# View logs
docker logs homepage

# Container shell access
docker exec -it homepage /bin/sh

# Restart container
docker restart homepage
```

## 🆕 Recent Updates

- **🗂️ Category Management System**: Full category management with setup interface at `/setup.html`
- **💾 Persistent Categories**: Server-side category storage with automatic Docker permission handling
- **📊 Live Scan Status**: Real-time scanning progress with time-since-completion
- **🔧 Persistent Port Selection**: Port choices survive rebuilds and sync across browsers
- **⚡ 6x Faster Scanning**: Optimized from 10+ minutes to ~90 seconds
- **🎬 Media Server Support**: Auto-discovery of Jellyfin, Plex, TVHeadend
- **💾 NAS Integration**: Support for Synology, QNAP, TrueNAS, Proxmox Backup
- **📈 Full Monitoring Stack**: Grafana, Prometheus, InfluxDB, exporters
- **🚀 Modern Dev Tools**: Code-server, Ollama AI, Angular dev servers
- **🖨️ 3D Printing**: Obico monitoring support
- **🔄 Smart UI**: Removed manual scan button, added intelligent status display
- **🛠️ Docker Permission Fix**: Automatic PHP-FPM and volume mount permission handling

## 📝 License

MIT