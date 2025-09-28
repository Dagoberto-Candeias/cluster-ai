#!/bin/bash
# =============================================================================
# Usage:
# =============================================================================
# Features:
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: issue-certs-robust.sh
# =============================================================================

#!/usr/bin/env bash
set -euo pipefail
# issue-certs-robust.sh -- idempotent, retrying Let's Encrypt issuance via certbot container
#
# Usage:
#   ./issue-certs-robust.sh <DOMAIN> <EMAIL> [--force]
#
# Features:
# - Checks for docker/docker-compose availability
# - Verifies domain resolves to host (best-effort)
# - Ensures ports 80/443 are available (warns if in use)
# - Idempotent: skips issuance if cert exists unless --force is passed
# - Retries certbot issuance up to 3 times with exponential backoff
# - Writes logs to ./logs/issue-certs.log
# - Replaces SERVER_NAME_PLACEHOLDER in nginx-tls.conf and writes working nginx.conf
#
DOMAIN=${1:-}
EMAIL=${2:-}
FORCE=${3:-}

LOGDIR=./logs
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/issue-certs.log"

echo "=== issue-certs-robust: started at $(date -u) ===" | tee -a "$LOGFILE"

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Usage: $0 <DOMAIN> <EMAIL> [--force]" | tee -a "$LOGFILE"
  exit 2
fi

COMPOSE_FILE=docker-compose-tls.yml
NGINX_TEMPLATE=nginx-tls.conf
NGINX_CONF=nginx.conf

echo "Checking docker..." | tee -a "$LOGFILE"
if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH. Please install Docker." | tee -a "$LOGFILE"
  exit 3
fi

# prefer docker compose v2 (docker compose) but allow docker-compose fallback
if command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose -f $COMPOSE_FILE"
else
  DC="docker compose -f $COMPOSE_FILE"
fi

# Basic DNS resolution check (best-effort)
echo "Resolving domain $DOMAIN..." | tee -a "$LOGFILE"
RESOLVED_IP=""
if command -v getent >/dev/null 2>&1; then
  RESOLVED_IP=$(getent ahosts "$DOMAIN" | awk '{print $1; exit}' || true)
else
  # use python as fallback
  RESOLVED_IP=$(python3 - <<PY
import socket,sys
try:
    print(socket.gethostbyname(sys.argv[1]))
except Exception as e:
    pass
PY
 "$DOMAIN" 2>/dev/null)
fi

if [ -n "$RESOLVED_IP" ]; then
  echo "Domain $DOMAIN resolves to $RESOLVED_IP" | tee -a "$LOGFILE"
else
  echo "Warning: Could not resolve $DOMAIN from this host. Ensure DNS A/AAAA points to this server." | tee -a "$LOGFILE"
fi

# Check ports 80 and 443 availability on host (best-effort)
echo "Checking ports 80 and 443 on localhost..." | tee -a "$LOGFILE"
for P in 80 443; do
  if ss -ltnp 2>/dev/null | grep -q ":$P[[:space:]]"; then
    echo "Warning: Port $P appears in use. This may block cert issuance or nginx binding." | tee -a "$LOGFILE"
  else
    echo "Port $P appears free." | tee -a "$LOGFILE"
  fi
done

# Ensure compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Error: $COMPOSE_FILE not found in $(pwd). Aborting." | tee -a "$LOGFILE"
  exit 4
fi
if [ ! -f "$NGINX_TEMPLATE" ]; then
  echo "Error: $NGINX_TEMPLATE not found. Aborting." | tee -a "$LOGFILE"
  exit 5
fi

# If cert already exists and not forcing, skip
CERT_PATH="./letsencrypt/live/$DOMAIN/fullchain.pem"
if [ -f "$CERT_PATH" ] && [ "$FORCE" != "--force" ]; then
  echo "Certificate already exists at $CERT_PATH. Use --force to re-issue." | tee -a "$LOGFILE"
  exit 0
fi

# Prepare nginx.conf from template
echo "Preparing nginx.conf from $NGINX_TEMPLATE ..." | tee -a "$LOGFILE"
cp "$NGINX_TEMPLATE" "$NGINX_CONF"
# Replace placeholder safely
sed -i "s/SERVER_NAME_PLACEHOLDER/$DOMAIN/g" "$NGINX_CONF"

# Ensure webroot and letsencrypt dirs exist
mkdir -p ./letsencrypt ./html/.well-known/acme-challenge
chmod 755 ./html

# Start open-webui and nginx services (idempotent)
echo "Starting open-webui and nginx via compose..." | tee -a "$LOGFILE"
$DC up -d open-webui nginx 2>&1 | tee -a "$LOGFILE" || { echo "Failed to start services"; exit 6; }

# Wait for nginx to bind port 80 (max 30s)
echo "Waiting for nginx to bind port 80..." | tee -a "$LOGFILE"
TRIES=0
MAX_TRIES=30
until ss -ltnp 2>/dev/null | grep -q ":80[[:space:]]" || [ $TRIES -ge $MAX_TRIES ]; do
  sleep 1
  TRIES=$((TRIES+1))
done
if [ $TRIES -ge $MAX_TRIES ]; then
  echo "Warning: nginx did not bind port 80 within timeout. Check container logs." | tee -a "$LOGFILE"
fi

# Attempt cert issuance with retries
MAX_ATTEMPTS=3
ATTEMPT=1
SLEEP_BASE=5
ISSUED=0

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "Certbot attempt $ATTEMPT of $MAX_ATTEMPTS ..." | tee -a "$LOGFILE"
  if $DC run --rm certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" --email "$EMAIL" --agree-tos --no-eff-email 2>&1 | tee -a "$LOGFILE"; then
    echo "Certbot succeeded on attempt $ATTEMPT" | tee -a "$LOGFILE"
    ISSUED=1
    break
  else
    echo "Certbot failed on attempt $ATTEMPT" | tee -a "$LOGFILE"
    SLEEP=$((SLEEP_BASE * ATTEMPT))
    echo "Sleeping $SLEEP seconds before next attempt..." | tee -a "$LOGFILE"
    sleep "$SLEEP"
    ATTEMPT=$((ATTEMPT+1))
  fi
done

if [ $ISSUED -ne 1 ]; then
  echo "Certificate issuance failed after $MAX_ATTEMPTS attempts. See $LOGFILE for details." | tee -a "$LOGFILE"
  exit 7
fi

# Reload nginx to pick up certificates
echo "Reloading nginx to apply certificates..." | tee -a "$LOGFILE"
$DC exec nginx nginx -s reload 2>&1 | tee -a "$LOGFILE" || { echo "Failed to reload nginx via docker compose exec. Try: docker compose restart nginx" | tee -a "$LOGFILE"; exit 8; }

echo "Certificate issuance complete. Certificates at ./letsencrypt/live/$DOMAIN/" | tee -a "$LOGFILE"
echo "=== issue-certs-robust: finished at $(date -u) ===" | tee -a "$LOGFILE"
