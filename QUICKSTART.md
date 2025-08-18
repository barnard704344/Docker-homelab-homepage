# Quick Setup Guide - Latest Version

This guide shows how to build and run the Docker Homelab Homepage with the latest service discovery features.

## 🚀 Quick Start (5 minutes)

### 1. Prerequisites
- Docker installed
- Network access for scanning (192.168.1.0/24 by default)
- Port 80 available (or use port mapping)

### 2. Clone and Build
```bash
# Clone the repository
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage

# Build the container
docker build -t homepage .
```

### 3. Run with Host Networking (Recommended)
```bash
# Stop any existing containers
docker stop homepage homelab-homepage 2>/dev/null || true
docker rm homepage homelab-homepage 2>/dev/null || true

# Run with host networking for best scanning performance
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homepage
```

### 4. Verify It's Working
```bash
# Check container status
docker ps -f name=homepage

# Check startup logs
docker logs homepage

# Test web access
curl http://localhost/ || curl http://$(hostname -I | awk '{print $1}')/

# Test the debug endpoint
curl http://localhost/debug.php
```

### 5. Access Your Homepage
- **Local**: http://localhost/
- **Network**: http://YOUR_SERVER_IP/
- **Debug Info**: http://YOUR_SERVER_IP/debug.php

## 🔧 Alternative Configurations

### Port Mapping (if host networking not available)
```bash
docker run -d \
  --name homepage \
  -p 8080:80 \
  -e SUBNETS="192.168.1.0/24" \
  -e RUN_SCAN_ON_START=1 \
  homepage

# Access via: http://YOUR_SERVER_IP:8080/
```

### Multiple Subnets
```bash
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24 10.0.0.0/24 172.16.0.0/16" \
  homepage
```

### Run Initial Scan on Startup
```bash
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e RUN_SCAN_ON_START=1 \
  homepage
```

## 🐛 Troubleshooting

### Check Service Discovery
```bash
# Run the debug script to see detailed status
docker exec homepage /usr/local/bin/debug-parser.sh

# Check if scan file was created
docker exec homepage ls -la /var/www/site/scan/

# Check if services.json was created
docker exec homepage ls -la /var/www/site/services.json

# Manually run a scan
docker exec homepage /usr/local/bin/scan.sh

# Check container logs for errors
docker logs homepage
```

### Debug Web Interface
```bash
# Test debug endpoint
curl http://localhost/debug.php | jq .

# Trigger a scan via web interface
curl -X POST http://localhost/run-scan.php

# Check nginx is responding
curl -I http://localhost/
```

### Common Issues and Solutions

**"No services found" after scan:**
1. Check debug endpoint: `curl http://localhost/debug.php`
2. Verify scan completed: `docker exec homepage ls -la /var/www/site/scan/`
3. Run debug script: `docker exec homepage /usr/local/bin/debug-parser.sh`

**Container won't start:**
1. Check logs: `docker logs homepage`
2. Verify port availability: `ss -ltnp | grep ':80'`
3. Try port mapping instead of host networking

**Scanning not working:**
1. Ensure host networking: `--network host`
2. Check subnet configuration matches your network
3. Test network access: `docker exec homepage ping 8.8.8.8`

## 🔄 Rebuilding After Changes

Create a simple rebuild script:

```bash
#!/bin/bash
# save as rebuild.sh and chmod +x rebuild.sh

echo "=== Rebuilding Homepage Container ==="
docker stop homepage 2>/dev/null || true
docker rm homepage 2>/dev/null || true

echo "Building..."
docker build -t homepage .

echo "Starting..."
docker run -d \
  --name homepage \
  --network host \
  -e SUBNETS="192.168.1.0/24" \
  -e SCAN_INTERVAL=10 \
  homepage

echo "Status:"
docker ps -f name=homepage
echo
echo "Logs:"
docker logs homepage
echo
echo "Testing debug endpoint..."
sleep 3
curl -s http://localhost/debug.php | jq .services_file.exists || echo "Debug endpoint not ready yet"
```

Run with: `./rebuild.sh`

## 📝 What's Included

✅ **Web Interface**: Interactive homepage with service cards  
✅ **Service Discovery**: Auto-detects web services from network scans  
✅ **Search Function**: Press `/` to search services  
✅ **Status Monitoring**: Green/red dots show service availability  
✅ **Scan Button**: Trigger scans from web interface  
✅ **Debug Tools**: Built-in diagnostics for troubleshooting  
✅ **Scheduled Scans**: Optional background scanning  
✅ **Host Networking**: Reliable network scanning support  

## 🎯 Next Steps

1. **Customize Services**: Edit `/var/www/site/index.html` to add your own service links
2. **Adjust Scanning**: Modify `SUBNETS` environment variable for your network
3. **Set Schedule**: Use `SCAN_INTERVAL=15` for scans every 15 minutes
4. **Monitor**: Use debug endpoint to monitor service discovery health

## 🔗 URLs

- **Homepage**: http://YOUR_SERVER_IP/
- **Debug Info**: http://YOUR_SERVER_IP/debug.php
- **Scan Results**: http://YOUR_SERVER_IP/scan.txt
- **Trigger Scan**: http://YOUR_SERVER_IP/run-scan.php

---

**Need Help?** 
- Check the debug endpoint first: `curl http://localhost/debug.php`
- Run the debug script: `docker exec homepage /usr/local/bin/debug-parser.sh`
- View logs: `docker logs homepage`
