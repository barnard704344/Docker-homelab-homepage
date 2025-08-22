# Docker Homelab Homepage - API & Debug Scripts Documentation

This document provides comprehensive documentation for all API endpoints and debug scripts in the Docker Homelab Homepage project.

## Table of Contents
- [API Endpoints](#api-endpoints)
- [Debug Scripts](#debug-scripts)
- [Usage Examples](#usage-examples)
- [Common Patterns](#common-patterns)

---

## API Endpoints

All API endpoints return JSON responses unless otherwise specified. Most endpoints include appropriate CORS headers for cross-origin requests.

### System Information & Debug APIs

#### `/debug.php`
**Purpose**: Provides comprehensive system debug information
**Method**: GET
**Response Format**: JSON

**Functionality**:
- Checks scan file status (both legacy and persistent locations)
- Validates services.json files
- Reports directory permissions and accessibility
- Lists available scripts and their executable status
- Provides system timestamps and server information

**Response Structure**:
```json
{
  "timestamp": "2024-01-01 12:00:00",
  "server_ip": "192.168.1.105",
  "scan_files": {
    "legacy_path": {"path": "...", "exists": true, "size": 1234, "readable": true},
    "persistent_path": {"path": "...", "exists": true, "size": 1234, "readable": true}
  },
  "services_files": {
    "legacy": {"path": "...", "exists": true, "valid_json": true, "service_count": 5},
    "persistent": {"path": "...", "exists": true, "valid_json": true, "service_count": 5}
  },
  "directories": {
    "/var/www/site": {"exists": true, "writable": true, "permissions": "0755"}
  },
  "scripts": {
    "scan.sh": {"path": "...", "exists": true, "executable": true}
  }
}
```

### Network Scanning APIs

#### `/run-scan.php`
**Purpose**: Triggers a network scan using the scan.sh script
**Method**: GET
**Response Format**: JSON

**Functionality**:
- Executes the network scan script (`/usr/local/bin/scan.sh`)
- Returns scan output and status
- Handles errors and timeouts gracefully

**Response Structure**:
```json
{
  "status": "success|error",
  "message": "Descriptive message",
  "output": "Command output",
  "return_code": 0
}
```

#### `/site/scan-status.php`
**Purpose**: Checks if a network scan is currently running
**Method**: GET
**Response Format**: Plain text
**Cache-Control**: No cache headers set

**Response**: Returns "running" or "idle" as plain text

#### `/site/scan-progress.php`
**Purpose**: Returns current scan progress information
**Method**: GET
**Response Format**: JSON
**CORS**: Enabled for cross-origin requests

**Functionality**:
- Reads scan progress from `/var/www/site/data/scan-progress.json`
- Validates progress data freshness (5-minute timeout)
- Returns progress status, percentage, and messages

**Response Structure**:
```json
{
  "status": "running|idle|error",
  "progress": 75,
  "message": "Scanning subnet 192.168.1.0/24",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### `/site/parse-scan.php`
**Purpose**: Manually triggers the parse-scan script
**Method**: GET
**Response Format**: JSON
**CORS**: Enabled

**Functionality**:
- Executes `/app/parse-scan.sh` to process scan results
- Returns script output and execution status
- Checks services.json file creation and size

**Response Structure**:
```json
{
  "success": true,
  "output": "Script execution output",
  "return_code": 0,
  "services_file_exists": true,
  "services_file_size": 1234
}
```

### Data Management APIs

#### `/site/setup-data.php`
**Purpose**: Comprehensive data management API for categories, assignments, services, and configuration
**Methods**: GET, POST
**Response Format**: JSON
**Cache-Control**: No cache headers

**File Locations**:
- Categories: `/var/www/site/data/categories.json`
- Service Assignments: `/var/www/site/data/service-assignments.json`
- Services: `/var/www/site/data/services.json`
- Custom Ports: `/var/www/site/data/custom-ports.json`
- Deleted Services: `/var/www/site/data/deleted-services.json`

**GET Actions**:
- `get_categories`: Returns available service categories
- `get_assignments`: Returns service-to-category assignments
- `get_services`: Returns discovered services
- `get_custom_ports`: Returns custom port configurations
- `get_deleted_services`: Returns list of deleted services

**POST Actions**:
- `save_categories`: Save/update categories
- `save_assignments`: Save service category assignments
- `save_custom_ports`: Save custom port configurations
- `save_deleted_services`: Save deleted services list

**Usage Examples**:
```
GET /site/setup-data.php?action=get_categories
POST /site/setup-data.php
Body: {"action": "save_categories", "categories": {...}}
```

#### `/site/pins.php`
**Purpose**: Manages pinned services/items
**Methods**: GET, POST, DELETE
**Response Format**: JSON
**CORS**: Full CORS support
**Data File**: `/var/www/site/data/pins.json`

**Functionality**:
- GET: Returns all pinned items
- POST: Add new pin or sync entire pins array
- DELETE: Remove specific pin

**Special POST Actions**:
- Standard: Add single pin with title, URL, etc.
- Sync: Replace entire pins array (`{"action": "sync", "pins": [...]}`)

#### `/site/port-selections.php`
**Purpose**: Manages port selection preferences for services
**Methods**: GET, POST
**Response Format**: JSON
**Cache-Control**: No cache headers
**Data File**: `/var/www/site/data/port-selections.json`

**Functionality**:
- GET: Returns saved port selections
- POST: Saves port selection preferences via sync action

**POST Usage**:
```json
{
  "action": "sync",
  "selections": {
    "service-name": {"port": 8080, "protocol": "http"}
  }
}
```

### Development & Testing APIs

#### `/site/debug-save.php`
**Purpose**: Tests data saving functionality for debugging
**Method**: GET
**Response Format**: Plain text

**Functionality**:
- Tests writing to the data directory
- Checks file permissions and ownership
- Provides detailed debugging output for save operations

#### `/site/test-parser.php`
**Purpose**: Manual testing tool for the scan parser
**Method**: GET
**Response Format**: Plain text

**Functionality**:
- Validates scan file existence and readability
- Checks parser script availability and permissions
- Tests data directory write capabilities
- Executes parser and reports results
- Validates services.json creation and content

#### `/site/write-test.php`
**Purpose**: Tests write permissions from PHP perspective
**Method**: GET
**Response Format**: Plain text

**Functionality**:
- Tests directory existence and permissions
- Checks file ownership and group information
- Performs actual write tests
- Compares with /tmp write capabilities
- Reports PHP process user/group information

#### `/site/fix-permissions.php`
**Purpose**: Attempts to fix data directory permissions
**Method**: GET
**Response Format**: JSON

**Functionality**:
- Creates data directory if missing
- Attempts to set proper permissions (0777)
- Tries to fix ownership issues
- Performs write tests to validate fixes

#### `/site/setup-debug.php`
**Purpose**: Comprehensive setup and configuration debugging
**Method**: GET
**Response Format**: Plain text

**Functionality**:
- Scans multiple potential data directories
- Tests write capabilities across directories
- Reports file ownership and permissions
- Tests category save functionality
- Provides setup recommendations

---

## Debug Scripts

### Shell Script Diagnostics

#### `debug-parser.sh`
**Purpose**: Manual debugging of the scan parser functionality
**Location**: `/usr/local/bin/debug-parser.sh` (created by start.sh)
**Language**: Bash

**Functionality**:
- Checks container environment status
- Validates scan file existence and content
- Tests services.json file status
- Examines directory permissions
- Executes parser script manually
- Reports final parsing results and service counts

**Usage**: Execute directly in container environment
```bash
/usr/local/bin/debug-parser.sh
```

#### `diagnostic.sh`
**Purpose**: Docker container permission diagnostics
**Language**: Bash

**Functionality**:
- Checks Docker container status
- Examines host data directory permissions
- Inspects volume mount configurations
- Tests debug endpoint accessibility
- Performs container internal permission checks
- Attempts automatic permission fixes

**Usage**: Run from host system with Docker access
```bash
./diagnostic.sh
```

#### `dns-diagnostic.sh`
**Purpose**: DNS resolution debugging for discovered services
**Language**: Bash
**Parameters**: IP address (optional, defaults to 192.168.1.79)

**Functionality**:
- Tests multiple DNS resolution methods (nslookup, dig, host)
- Examines container DNS configuration
- Tests nmap DNS resolution behavior
- Checks /etc/hosts for static entries
- Analyzes system resolver capabilities
- Cross-references with services.json entries
- Provides DNS troubleshooting recommendations

**Usage**:
```bash
./dns-diagnostic.sh [IP_ADDRESS]
```

#### `scan-diagnostic.sh`
**Purpose**: Comprehensive scanning system diagnostics
**Language**: Bash

**Functionality**:
- Verifies server and container status
- Checks environment variables
- Monitors running processes
- Analyzes recent container logs
- Tests network connectivity
- Examines file system permissions
- Tests web interface accessibility
- Performs manual scan execution
- Provides troubleshooting recommendations

**Usage**: Run from host system
```bash
./scan-diagnostic.sh
```

#### `git-diagnostic.sh`
**Purpose**: Git repository modification diagnostics
**Language**: Bash

**Functionality**:
- Lists files with local changes
- Shows detailed diffs for key files
- Reports git configuration settings
- Provides file permission information
- Shows recent commit history
- Offers suggestions for resolving git issues

**Usage**:
```bash
./git-diagnostic.sh
```

### Core System Scripts

#### `scan.sh`
**Purpose**: Main network scanning script
**Location**: `/usr/local/bin/scan.sh`
**Language**: Bash
**Environment Variables**: 
- `SUBNETS`: Comma-separated subnet list (default: "192.168.1.0/24")

**Functionality**:
- Performs network discovery using nmap
- Scans specified subnets for active hosts
- Identifies open ports and services
- Provides DNS resolution for discovered hosts
- Updates scan progress via JSON progress file
- Outputs results to persistent data directory

**Output Files**:
- `/var/www/site/data/scan/last-scan.txt`: Raw scan results
- `/var/www/site/data/scan-progress.json`: Real-time progress updates

#### `parse-scan.sh`
**Purpose**: Processes raw scan results into structured service data
**Location**: `/usr/local/bin/parse-scan.sh`
**Language**: Bash

**Functionality**:
- Parses nmap scan results
- Extracts service information (IP, port, service type)
- Resolves hostnames via DNS
- Generates services.json with discovered services
- Handles service deduplication and updates

#### `start.sh`
**Purpose**: Container initialization and setup script
**Language**: Bash

**Functionality**:
- Sets up container environment
- Creates required directories and files
- Configures permissions for data persistence
- Installs debug scripts dynamically
- Initializes default configuration files

### Additional Utility Scripts

#### `refresh-dns.sh`
**Purpose**: DNS cache clearing and forced refresh
**Language**: Bash

**Functionality**:
- Clears potential DNS cache entries
- Removes old scan results to force fresh discovery
- Backs up existing services.json
- Triggers fresh scan with DNS resolution
- Useful for resolving hostname caching issues

**Usage**: Run when hostnames are not updating properly
```bash
./refresh-dns.sh
```

#### `run.sh`
**Purpose**: Complete container build, setup, and launch script
**Language**: Bash
**Variables**: 
- `IMAGE_NAME`: "homelab-homepage" 
- `CONTAINER_NAME`: "homepage"

**Functionality**:
- Builds Docker image from Dockerfile
- Stops and removes existing container
- Creates persistent data directories with proper permissions
- Launches container with host networking
- Sets up volume mounts for data persistence

**Usage**: Primary deployment script
```bash
./run.sh
```

#### `setup.sh`
**Purpose**: Initial project setup and configuration
**Language**: Bash

#### `cleanup-service.sh`
**Purpose**: Service cleanup operations
**Language**: Bash

#### `auto-update.sh`
**Purpose**: Automated update procedures
**Language**: Bash

#### `fix-permissions.sh`
**Purpose**: Host-level permission fixes
**Language**: Bash

#### `quick-fix.sh`
**Purpose**: Quick system fixes and adjustments
**Language**: Bash

#### `test-container.sh`
**Purpose**: Container functionality testing
**Language**: Bash

---

## Usage Examples

### Triggering a Network Scan
```bash
# Start a network scan
curl http://localhost/run-scan.php

# Check scan status
curl http://localhost/site/scan-status.php

# Monitor scan progress
curl http://localhost/site/scan-progress.php
```

### Managing Service Data
```bash
# Get all categories
curl http://localhost/site/setup-data.php?action=get_categories

# Get discovered services
curl http://localhost/site/setup-data.php?action=get_services

# Save service assignments
curl -X POST http://localhost/site/setup-data.php \
  -H "Content-Type: application/json" \
  -d '{"action": "save_assignments", "assignments": {"MyService": "network"}}'
```

### Managing Pins
```bash
# Get all pins
curl http://localhost/site/pins.php

# Add a new pin
curl -X POST http://localhost/site/pins.php \
  -H "Content-Type: application/json" \
  -d '{"title": "My Service", "url": "http://192.168.1.100:8080"}'

# Sync entire pins array
curl -X POST http://localhost/site/pins.php \
  -H "Content-Type: application/json" \
  -d '{"action": "sync", "pins": [...]}'
```

### System Debugging
```bash
# Get comprehensive debug information
curl http://localhost/debug.php | jq .

# Test write permissions
curl http://localhost/site/write-test.php

# Fix permissions issues
curl http://localhost/site/fix-permissions.php
```

### Container Debugging
```bash
# Run comprehensive diagnostics
./scan-diagnostic.sh

# Debug DNS issues
./dns-diagnostic.sh 192.168.1.100

# Check parser functionality
docker exec homepage /usr/local/bin/debug-parser.sh

# Fix permission issues
./diagnostic.sh
```

### Core System Operations
```bash
# Deploy the complete system
./run.sh

# Trigger fresh DNS resolution
./refresh-dns.sh

# Manual network scan with custom subnets
docker exec homepage env SUBNETS="192.168.1.0/24,10.0.0.0/24" /usr/local/bin/scan.sh

# Parse existing scan results
docker exec homepage /usr/local/bin/parse-scan.sh

# Check container environment
docker exec homepage /usr/local/bin/debug-parser.sh
```

---

## Common Patterns

### Error Handling
Most API endpoints follow these patterns:
- Return HTTP 400 for invalid requests
- Return HTTP 500 for server errors
- Include error messages in JSON responses
- Use appropriate HTTP status codes

### CORS Support
Many endpoints include CORS headers:
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');
```

### Cache Control
Critical endpoints disable caching:
```php
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');
```

### Data Directory Structure
```
/var/www/site/data/
├── categories.json          # Service categories
├── service-assignments.json # Service to category mappings
├── services.json           # Discovered services
├── custom-ports.json       # Custom port configurations
├── deleted-services.json   # Deleted services list
├── pins.json              # Pinned services
├── port-selections.json   # Port selection preferences
└── scan/
    └── last-scan.txt      # Raw scan results
```

### File Permissions
- Data directory: 0777 (full permissions for container access)
- JSON files: Created with appropriate permissions for nginx user
- Scripts: Executable permissions required (/usr/local/bin/*)

This documentation covers all API endpoints and debug scripts in the Docker Homelab Homepage project. For specific implementation details, refer to the individual script files.