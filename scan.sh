#!/usr/bin/env bash
set -euo pipefail

# ENV (with defaults set in Dockerfile; can be overridden at run-time)
SUBNETS="${SUBNETS:-}"
PORTS="${PORTS:-80,443,8080,8443}"
DNS_SERVER="${DNS_SERVER:-}"
SEARCH_DOMAINS="${SEARCH_DOMAINS:-}"
HOSTNAMES="${HOSTNAMES:-}"
INTERVAL="${INTERVAL:-600}"
USE_TLS_MAP="${USE_TLS_MAP:-true}"

OUT_DIR="/var/www/site"
OUT_FILE="${OUT_DIR}/services.json"
PORTMAP="/app/ports.map"

log() { printf '[scanner] %s\n' "$*" >&2; }

ensure_outdir() {
  mkdir -p "$OUT_DIR"
  if [ ! -w "$OUT_DIR" ]; then
    log "ERROR: $OUT_DIR not writable"
    exit 1
  fi
}

ptr_lookup() {
  local ip="$1"
  if [ -n "$DNS_SERVER" ]; then
    dig +short -x "$ip" @"$DNS_SERVER" 2>/dev/null | sed -e 's/\.$//' | head -n1
  else
    dig +short -x "$ip" 2>/dev/null | sed -e 's/\.$//' | head -n1
  fi
}

a_lookup() {
  local host="$1"
  if [ -n "$DNS_SERVER" ]; then
    dig +short "$host" @"$DNS_SERVER" 2>/dev/null | grep -E '^[0-9.]+$' | head -n1
  else
    dig +short "$host" 2>/dev/null | grep -E '^[0-9.]+$' | head -n1
  fi
}

map_port() {
  local port="$1"
  awk -F, -v p="$port" '
    $1 ~ /^[[:space:]]*#/ {next}
    $1 == p { print $2","$3","$4; found=1; exit }
    END { if(!found) print "http,web,Port "p }
  ' "$PORTMAP"
}

mk_url() {
  local ip="$1" port="$2" scheme tag desc
  IFS=, read -r scheme tag desc < <(map_port "$port")

  # Prefer PTR host if available (better cert alignment)
  local host ptr
  ptr="$(ptr_lookup "$ip")"
  if [ -n "$ptr" ]; then
    host="$ptr"
  else
    host="$ip"
  fi

  # Scheme hints by port (toggle with USE_TLS_MAP)
  if [ "$USE_TLS_MAP" = "true" ]; then
    case "$port" in
      443|8443|8006|32400|3000|3001|8123|5601) scheme="https" ;;
      80|8080|9090|9093|9200|32168|9000) : ;; # keep map default
    esac
  fi

  case "$scheme:$port" in
    http:80|https:443) printf "%s://%s" "$scheme" "$host" ;;
    *)                 printf "%s://%s:%s" "$scheme" "$host" "$port" ;;
  esac
}

seed_entries() {
  local hosts=($HOSTNAMES)
  local domains=($SEARCH_DOMAINS)
  for h in "${hosts[@]}"; do
    local ip; ip="$(a_lookup "$h")"
    [ -z "$ip" ] && continue
    for port in $(echo "$PORTS" | tr ',' ' '); do
      mk_url "$ip" "$port"
      echo
    done
  done

  local commons=(proxmox portainer grafana traefik kubernetes k8s truenas synology obico dvr plex vault authelia gitea jenkins harbor prometheus alertmanager notify cpai)
  for d in "${domains[@]}"; do
    for name in "${commons[@]}"; do
      local fqdn="${name}.${d}"
      local ip; ip="$(a_lookup "$fqdn")"
      [ -z "$ip" ] && continue
      for port in $(echo "$PORTS" | tr ',' ' '); do
        mk_url "$ip" "$port"
        echo
      done
    done
  done
}

scan_cycle() {
  ensure_outdir

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  if [ -z "$SUBNETS" ]; then
    log "ERROR: set SUBNETS env (e.g., 10.72.28.0/22 10.136.40.0/24)"
    # write empty manifest to avoid frontend fetch errors
    echo '[]' > "${OUT_FILE}"
    return
  fi

  log "Scanning SUBNETS=[$SUBNETS] PORTS=[$PORTS]"
  nmap -n -Pn --open -p "$PORTS" $SUBNETS -oG - 2>/dev/null \
    | awk '/Ports:/{print}' > "$tmp"

  {
    echo '['
    first=1

    # nmap results
    while IFS= read -r line; do
      ip=$(echo "$line" | awk '{print $2}')
      ports=$(echo "$line" | sed -n 's/.*Ports: //p' | tr ',' '\n' | awk -F/ '$2=="open"{print $1}')
      [ -z "$ports" ] && continue

      ptr="$(ptr_lookup "$ip")"
      for p in $ports; do
        url="$(mk_url "$ip" "$p")"
        IFS=, read -r scheme tag desc < <(map_port "$p")
        title="${ptr:-$ip}"
        group="Discovered"
        statusPath="/"

        [ $first -eq 0 ] && echo ','
        first=0
        jq -cn --arg t "$title" \
               --arg u "$url" \
               --arg g "$group" \
               --arg d "$desc" \
               --argjson tags "[\"$tag\"]" \
               --arg s "$statusPath" \
          '{title:$t,url:$u,group:$g,desc:$d,tags:$tags,statusPath:$s}'
      done
    done < "$tmp"

    # seeds
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      [ $first -eq 0 ] && echo ','
      first=0
      host=$(echo "$url" | awk -F[/:] '{print $4}')
      title="${host}"
      group="Discovered"
      desc="Seeded"
      tag="seed"
      statusPath="/"
      jq -cn --arg t "$title" \
             --arg u "$url" \
             --arg g "$group" \
             --arg d "$desc" \
             --argjson tags "[\"$tag\"]" \
             --arg s "$statusPath" \
        '{title:$t,url:$u,group:$g,desc:$d,tags:$tags,statusPath:$s}'
    done < <(seed_entries | sort -u)

    echo
    echo ']'
  } > "${OUT_FILE}.tmp"

  mv "${OUT_FILE}.tmp" "${OUT_FILE}"
  log "Wrote $(wc -c < "${OUT_FILE}") bytes to ${OUT_FILE}"
}

main() {
  # run forever
  while true; do
    scan_cycle
    sleep "$INTERVAL"
  done
}

main
