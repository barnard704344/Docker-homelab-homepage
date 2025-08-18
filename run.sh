#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="homelab-homepage"
CONTAINER_NAME="homelab-homepage"

echo "[*] Building image '${IMAGE_NAME}'..."
docker build -t "${IMAGE_NAME}" .

echo "[*] Stopping/removing existing container (if any)..."
docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[*] Running container with --network host ..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --network host \
  "${IMAGE_NAME}"

echo "[*] Container started. Access your site at:  http://<HOST_LAN_IP>/"
echo "    Example: http://192.168.1.20/"
echo
echo "[*] Tail logs with:"
echo "    docker logs -f ${CONTAINER_NAME}"
