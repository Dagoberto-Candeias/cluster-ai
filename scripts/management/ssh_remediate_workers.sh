#!/bin/bash
# =============================================================================
# SSH Remediation for Workers - Cluster AI
# =============================================================================
# Objetivo: auxiliar a configurar acesso SSH sem senha aos workers definidos em cluster.yaml,
# validar conectividade (ping/TCP), adicionar known_hosts e, opcionalmente, copiar a chave pública.
# Uso seguro por padrão (dry-run). Para aplicar mudanças use --apply.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKER_CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/ssh_remediation.log"
mkdir -p "$LOG_DIR"

APPLY=false
ONLY_WORKER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=true; shift ;;
    --worker)
      ONLY_WORKER="${2:-}"; shift 2 ;;
    -h|--help)
      cat <<EOF
Uso: $0 [--apply] [--worker <nome>]

  --apply              Aplica mudanças (ssh-copy-id, known_hosts). Padrão: dry-run
  --worker <nome>      Limita a um worker específico (nome conforme cluster.yaml)

Exemplos:
  $0                           # Dry-run em todos os workers
  $0 --worker android-worker   # Dry-run em um worker
  $0 --apply                   # Aplica mudanças em todos os workers
EOF
      exit 0 ;;
    *) shift ;;
  esac
done

need_cmd(){ command -v "$1" >/dev/null 2>&1 || { echo "Falta comando: $1"; exit 1; }; }
need_cmd yq
need_cmd ssh
need_cmd ssh-keygen

if [[ ! -f "$WORKER_CONFIG_FILE" ]]; then
  echo "cluster.yaml não encontrado em $WORKER_CONFIG_FILE" >&2
  exit 1
fi

# Garante que existe chave SSH local
if [[ ! -f "$HOME/.ssh/id_rsa.pub" && ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  echo "Chave SSH não encontrada. Gerando ed25519..."
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -q
fi
PUBKEY_FILE="${HOME}/.ssh/id_ed25519.pub"
[[ -f "$HOME/.ssh/id_rsa.pub" ]] && PUBKEY_FILE="$HOME/.ssh/id_rsa.pub"

mapfile -t workers < <(yq e '.workers | keys | .[]' "$WORKER_CONFIG_FILE")

for w in "${workers[@]}"; do
  [[ -n "$ONLY_WORKER" && "$ONLY_WORKER" != "$w" ]] && continue
  status=$(yq e ".workers[\"$w\"].status // \"active\"" "$WORKER_CONFIG_FILE" | tr 'A-Z' 'a-z')
  host=$(yq e ".workers[\"$w\"].host // .workers[\"$w\"].ip" "$WORKER_CONFIG_FILE")
  user=$(yq e ".workers[\"$w\"].user" "$WORKER_CONFIG_FILE")
  port=$(yq e ".workers[\"$w\"].port // 22" "$WORKER_CONFIG_FILE")

  echo "== $w ($user@$host:$port) status=$status =="
  [[ "$status" != "active" ]] && { echo "- skip (inactive)"; echo; continue; }

  # Ping
  if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then echo "- Ping: OK"; else echo "- Ping: FAIL"; fi
  # TCP
  if timeout 3 bash -lc "</dev/tcp/$host/$port" >/dev/null 2>&1; then echo "- TCP:$port: OK"; else echo "- TCP:$port: FAIL"; fi

  # known_hosts
  if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" echo OK >/dev/null 2>&1; then
    echo "- SSH: OK (known_hosts atualizado)"
  else
    echo "- SSH: autenticação falhou (pode requerer senha)"
  fi

  # Copiar chave (opcional)
  if $APPLY; then
    if command -v ssh-copy-id >/dev/null 2>&1; then
      echo "- Aplicando ssh-copy-id (pode solicitar senha)..."
      if ssh-copy-id -p "$port" -i "$PUBKEY_FILE" "$user@$host" >/dev/null 2>&1; then
        echo "  * Chave instalada"
      else
        echo "  * Falha ao instalar chave (verifique senha/perm.)"
      fi
    else
      echo "- ssh-copy-id não encontrado; pulei esta etapa"
    fi
  else
    echo "- Dry-run: não copiando chave. Use --apply para aplicar."
  fi

  # Verificar Dask
  if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" "pgrep -f dask >/dev/null && echo HAS_DASK || echo NO_DASK" 2>/dev/null | grep -q HAS_DASK; then
    echo "- Dask: RUNNING"
  else
    echo "- Dask: NOT RUNNING"
  fi
  echo
done | tee -a "$LOG_FILE"

echo "Relatório salvo em: $LOG_FILE"
