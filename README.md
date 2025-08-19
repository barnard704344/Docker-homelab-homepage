# Docker Homelab Homepage

A lightweight Docker container that provides a clean homepage for your homelab with automatic network service discovery.

## ✨ Features

- **🏠 Clean Homepage**: Interactive service cards with status indicators
- **🔍 Network Discovery**: Automatic nmap-based scanning of your network
- **📌 Pin Services**: Server-side pin storage that syncs across browsers
- **🔧 Port Selection**: Clickable port buttons for each discovered service
- **📊 Persistent Data**: Scan results and pins survive container rebuilds
- **🎯 One-Click Setup**: Single script handles everything

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage

# Run the setup (handles everything automatically)
bash setup.sh
```

That's it! Access your homepage at `http://localhost/` or `http://<your-server-ip>/`

## ⚙️ Configuration

The setup script automatically configures:
- **Network**: Scans `192.168.1.0/24` by default
- **Scanning**: Every 10 minutes automatically
- **Storage**: Persistent data directory for scans and pins
- **Permissions**: Proper container permissions

To customize, edit environment variables in `setup.sh`:
```bash
-e SUBNETS="192.168.1.0/24 10.0.1.0/24"  # Multiple networks
-e SCAN_INTERVAL=15                        # Scan every 15 minutes
```

## 🔧 Usage

### Web Interface
- **📌 Pinned**: Toggle view of pinned services only
- **🔄 Refresh**: Reload services from scan results  
- **🔍 Run Scan**: Trigger immediate network scan
- **Port Buttons**: Click port numbers to access specific services

### Automatic Updates
```bash
# Handle git conflicts automatically and update
bash auto-update.sh
bash setup.sh
```

### Debugging
```bash
# Check what's happening
curl http://localhost/debug.php

# Run diagnostics
bash git-diagnostic.sh
bash diagnostic.sh
```

## 📁 What Gets Discovered

The scanner finds services on common ports and creates service cards for:
- **Web servers** (ports 80, 443, 8080, 3000, 5000, 8000, etc.)
- **Management interfaces** (8006, 9000, 19999, etc.) 
- **Named devices** (devices with hostnames, not just IP addresses)
- **All open ports** (shows clickable buttons for every discovered port)

## 🗂️ File Structure

```
├── setup.sh              # Main setup script (use this!)
├── auto-update.sh         # Handles git conflicts
├── diagnostic.sh          # Debug permission issues
├── site/
│   ├── index.html         # Homepage interface
│   └── pins.php           # Pin storage API
├── scan.sh                # Network scanning (nmap)
├── parse-scan.sh          # Convert scans to JSON
└── data/                  # Persistent storage (auto-created)
    ├── scan/              # Scan results
    ├── services.json      # Discovered services
    └── pins.json          # Saved pins
```

## 🔍 Advanced

### Manual Commands
```bash
# Trigger manual scan
curl http://localhost/run-scan.php

# View scan results
curl http://localhost/scan.txt

# Check discovered services
curl http://localhost/services.json
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

## 📝 License

MIT