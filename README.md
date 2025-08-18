# Homelab Homepage (Docker)

A lightweight **network-scanning homepage** for your homelab.  
This container runs an Nginx-powered site that can be updated dynamically using `scan.sh` (via `nmap`) to discover services on your LAN.

---

## 📦 Features
- Simple static homepage served by **Nginx**
- Auto-populated by network scan (`nmap`)
- Runs in Docker with minimal dependencies
- LAN-accessible via published port
- Configurable subnet scanning with `SUBNETS` environment variable

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
```

### 2. Build the Docker Image
```bash
docker build -t homelab-homepage .
```

### 3. Run the Container (Port 8080)
Stop and remove any existing container first:
```bash
docker stop homelab-homepage 2>/dev/null || true
docker rm homelab-homepage 2>/dev/null || true
```

Then start a fresh one (example with a single subnet):
```bash
docker run -d   --name homelab-homepage   -p 8080:80   -e SUBNETS="192.168.1.0/24"   -e RUN_SCAN_ON_START=1   homelab-homepage
```

> This maps port 80 inside the container to port 8080 on the host.  
> Example: if your host is `192.168.1.20`, the site will be at:
> ```
> http://192.168.1.20:8080/
> ```

---

## 🔍 Configuring Subnet Scans

You can configure which subnets to scan by setting the `SUBNETS` environment variable.  
Multiple subnets are supported by providing them space-separated.

Examples:
```bash
# Single subnet
-e SUBNETS="192.168.1.0/24"

# Multiple subnets
-e SUBNETS="192.168.1.0/24 10.72.28.0/22 10.136.40.0/24"
```

Enable automatic scan at container startup with:
```bash
-e RUN_SCAN_ON_START=1
```

---

## 🔍 Manual Scanning

Trigger a manual scan inside the container at any time:
```bash
docker exec -it homelab-homepage /app/scan.sh
```

The latest scan result will be written to:
- `/var/www/site/scan/last-scan.txt` inside the container
- Accessible via browser at `http://<HOST_LAN_IP>:8080/scan/last-scan.txt` or `http://<HOST_LAN_IP>:8080/scan.txt`

---

## 🛠️ Troubleshooting

### Check Container Logs
```bash
docker logs -f homelab-homepage
```

### Verify Container is Running
```bash
docker ps
```

### Firewall
Make sure port 8080 is open on the host:
```bash
sudo ufw allow 8080/tcp
```

---

## 🧹 Maintenance

Stop the container:
```bash
docker stop homelab-homepage
```

Remove the container:
```bash
docker rm homelab-homepage
```

Rebuild after making changes:
```bash
docker build -t homelab-homepage .
```

---

## 🌐 Access
- From host: [http://localhost:8080](http://localhost:8080)
- From LAN: `http://<HOST_LAN_IP>:8080/`
  - Example: `http://192.168.1.20:8080/`

---

## 📄 License
MIT
