#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="homelab-homepage"
CONTAINER_NAME="homelab-homepage"

echo "[*] Building image '${IMAGE_NAME}'..."
docker build -t "${IMAGE_NAME}" .

echo "[*] Stopping/removing existing container (if any)..."
docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[*] Setting up persistent data directory..."
# Create data directory with proper permissions
mkdir -p "$(pwd)/data/scan"
mkdir -p "$(pwd)/data"
# Set permissions for nginx user (82:82 in Alpine)
sudo chown -R 82:82 "$(pwd)/data" 2>/dev/null || chown -R www-data:www-data "$(pwd)/data" 2>/dev/null || true
sudo chmod -R 755 "$(pwd)/data"

echo "[*] Running container with --network host ..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --network host \
  -v "$(pwd)/data:/var/www/site/data" \
  "${IMAGE_NAME}"

echo "[*] Container started. Access your site at:  http://<HOST_LAN_IP>/"
echo "    Example: http://192.168.1.20/"
echo
echo "[*] Tail logs with:"
echo "    docker logs -f ${CONTAINER_NAME}"
