#!/bin/bash
# =============================================================================
# Usage:
# =============================================================================
# Example:
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: issue-certs-simple.sh
# =============================================================================

#!/usr/bin/env bash
set -euo pipefail
# issue-certs.sh -- automates Let's Encrypt certificate issuance using the certbot container
#
# Usage:
#   ./issue-certs.sh <DOMAIN> <EMAIL>
# Example:
#   ./issue-certs.sh example.com admin@example.com
#
# Requirements:
# - docker and docker compose installed and working
# - files present in current dir: docker-compose-tls.yml, nginx-tls.conf
# - Ollama running on the host at :11434 (or adjust docker-compose to point to host IP)
#
DOMAIN=${1:-}
EMAIL=${2:-}

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Usage: $0 <DOMAIN> <EMAIL>"
  exit 2
fi

COMPOSE_FILE=docker-compose-tls.yml

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Error: $COMPOSE_FILE not found in $(pwd). Please run this script from the folder containing the docker-compose file." >&2
  exit 3
fi

# Ensure nginx config exists
if [ ! -f nginx-tls.conf ]; then
  echo "Error: nginx-tls.conf not found. Make sure nginx-tls.conf is present and contains SERVER_NAME_PLACEHOLDER." >&2
  exit 4
fi

# Replace SERVER_NAME_PLACEHOLDER in nginx-tls.conf -> create a working nginx.conf
TMP_NGINX=nginx.conf
cp nginx-tls.conf "$TMP_NGINX"
sed -i "s/SERVER_NAME_PLACEHOLDER/$DOMAIN/g" "$TMP_NGINX"

# Create persistent dirs
mkdir -p ./letsencrypt ./html/.well-known/acme-challenge
chmod 755 ./html

# Start containers (open-webui + nginx + certbot)
echo "Starting containers (open-webui, nginx, certbot)..."
if command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose -f $COMPOSE_FILE"
else
  DC="docker compose -f $COMPOSE_FILE"
fi

$DC up -d open-webui nginx || { echo 'Failed to start compose services'; exit 5; }

# Wait for nginx to be reachable on port 80 locally (inside host)
echo "Waiting for nginx to bind port 80..."
sleep 3

# Issue certificate with certbot (webroot plugin)
echo "Issuing certificate for $DOMAIN ..."
$DC run --rm certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" --email "$EMAIL" --agree-tos --no-eff-email || {
  echo "Certbot failed. Check nginx logs and ensure the domain points to this server." >&2
  exit 6
}

# Reload nginx to pick up the new certs
echo "Reloading nginx to apply certificates..."
$DC exec nginx nginx -s reload || {
  echo "Failed to reload nginx via docker compose exec. You may need to restart the container manually." >&2
  exit 7
}

echo "Certificate issuance complete. Certificates stored in ./letsencrypt/live/$DOMAIN/"
echo "Done."
