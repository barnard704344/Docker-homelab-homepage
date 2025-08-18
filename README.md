# Homelab Homepage (Docker)

A lightweight **network-scanning homepage** for your homelab.  
This container runs an Nginx-powered site that can be updated dynamically using `scan.sh` (via `nmap`) to discover services on your LAN.

---

## 📦 Features
- Simple static homepage served by **Nginx**
- Auto-populated by network scan (`nmap`)
- Runs in Docker with minimal dependencies
- LAN-accessible (using Docker host networking)

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

### 3. Run the Container (Host Networking)
Stop and remove any existing container first:
```bash
docker stop homelab-homepage 2>/dev/null || true
docker rm homelab-homepage 2>/dev/null || true
```

Then start a fresh one:
```bash
docker run -d   --name homelab-homepage   --network host   homelab-homepage
```

> Using `--network host` makes the homepage available on the same IP as your Docker host.  
> Example: if your host is `192.168.1.20`, the site will be at:
> ```
> http://192.168.1.20/
> ```

---

## 🔍 Updating the Homepage via Scan

This repo includes a script that can scan your LAN and update the homepage dynamically.

Make scripts executable:
```bash
chmod +x scan.sh run.sh
```

Run the scan:
```bash
./scan.sh
```

Restart container with updated data:
```bash
./run.sh
```

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
Make sure port 80 is open on the host:
```bash
sudo ufw allow 80/tcp
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
- From host: [http://localhost](http://localhost)
- From LAN: `http://<HOST_LAN_IP>/`
  - Example: `http://192.168.1.20/`

---

## 📄 License
MIT
