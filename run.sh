#!/usr/bin/env bash
set -euo pipefail

/app/scan.sh &
exec nginx -g 'daemon off;'
