# Docker Homelab Homepage

A self-hosted homepage that automatically discovers and organizes services on your network. Built with Docker + nmap for easy deployment and network scanning.

## Features

- **🔍 Automatic Discovery**: Scans your network to find running services
- **🏷️ Service Organization**: Organize services into custom categories  
- **📌 Quick Access**: Pin frequently used services to the top
- **🎨 Clean Interface**: Responsive web interface that works on all devices
- **⚙️ Persistent Storage**: Settings and data survive container updates

## Quick Start

```bash
git clone https://github.com/barnard704344/Docker-homelab-homepage.git
cd Docker-homelab-homepage
bash setup.sh
```

Then visit http://localhost or http://your-server-ip

## Configuration

### Initial Setup
1. Visit `/setup.html` to configure categories and scanning options
2. The first scan runs automatically, or manually trigger with: `docker exec homepage /usr/local/bin/scan.sh`
3. Organize discovered services into categories
4. Pin your most-used services for quick access

### Environment Variables
Set these in your Docker run command or modify `setup.sh`:

- `SUBNETS`: Networks to scan (default: `192.168.1.0/24`)
- `SCAN_INTERVAL`: Auto-scan interval in minutes (default: `10`, set to `0` to disable)
- `RUN_SCAN_ON_START`: Run scan at startup (default: `1`)

### Custom Ports
Add additional ports to scan via the setup interface. The scanner detects common service ports including web servers (80, 443, 8080), databases (3306, 5432), media servers (8096, 32400), and more.

## Management

### Container Commands
```bash
# View logs
docker logs homepage

# Manual scan
docker exec homepage /usr/local/bin/scan.sh

# Restart container
docker restart homepage

# Stop container
docker stop homepage
```

### Updates
```bash
git pull
bash setup.sh
```

Your data and settings will persist across updates.

## Troubleshooting

### Container Won't Start
Check logs: `docker logs homepage`

### No Services Found
1. Verify your network subnet in environment variables
2. Check that services are actually running on expected ports
3. Ensure the container can reach your network

### Permissions Issues
The setup script handles permissions automatically. If you encounter issues, ensure the `./data` directory is writable.

---

**Security Note**: This tool scans your network and is intended for internal use only.