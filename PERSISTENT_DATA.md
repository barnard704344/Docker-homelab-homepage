# Persistent Scan Data Implementation

## What Changed
The full scan results and pins now persist across container rebuilds by using a volume-mounted data directory.

## File Changes
- **scan.sh**: Now saves scan results to `/var/www/site/data/scan/` (persistent)
- **parse-scan.sh**: Reads from persistent location and creates services.json in `/var/www/site/data/`
- **pins.php**: Stores pins in `/var/www/site/data/pins.json` (persistent)
- **run.sh & rebuild.sh**: Both now mount `./data:/var/www/site/data` as a volume
- **.gitignore**: Excludes the data directory from git commits

## Directory Structure
```
./data/                     # On host (persistent)
├── scan/
│   └── last-scan.txt      # Full nmap scan results
├── services.json          # Parsed service discovery data
├── pins.json             # User pin data
└── scan.txt -> scan/last-scan.txt  # Convenience symlink
```

## How It Works
1. Host `./data` directory is mounted as `/var/www/site/data` inside container
2. All scan data, parsed services, and pins are stored in this mounted volume
3. When container is rebuilt, data persists on the host filesystem
4. Compatibility symlinks ensure existing functionality works

## Usage
After pulling and rebuilding:
```bash
git pull
./rebuild.sh
```

Your scan results and pins will survive the rebuild!
