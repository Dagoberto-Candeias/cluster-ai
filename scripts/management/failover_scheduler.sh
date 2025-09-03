#!/bin/bash
# Script de Failover Automático para Dask Scheduler

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"

# Carregar configurações
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Configurações padrão
PRIMARY_IP="${NODE_IP:-192.168.0.2}"
PRIMARY_PORT="${DASK_SCHEDULER_PORT:-8786}"
SECONDARY_IP="${DASK_SCHEDULER_SECONDARY_IP:-192.168.0.3}"
SECONDARY_PORT="${DASK_SCHEDULER_SECONDARY_PORT:-8788}"

LOG_FILE="${PROJECT_ROOT}/logs/failover.log"

# Função para verificar se scheduler está ativo
check_scheduler() {
    local ip="$1"
    local port="$2"
    timeout 5 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null
}

# Função para iniciar scheduler secundário
start_secondary_scheduler() {
    echo "$(date): Iniciando scheduler secundário em $SECONDARY_IP:$SECONDARY_PORT" >> "$LOG_FILE"

    # Criar script para iniciar scheduler secundário
    cat > /tmp/start_secondary_dask.sh << 'EOF'
#!/bin/bash
source .venv/bin/activate 2>/dev/null || true
cd /home/dcm/Projetos/cluster-ai
python -c "
import dask
from dask.distributed import Client, LocalCluster
import time

print('Iniciando scheduler secundário...')

cert_file = 'certs/dask_cert.pem'
key_file = 'certs/dask_key.pem'
auth_token = 'secure_token_12345'

security = {
    'tls': {
        'cert': cert_file,
        'key': key_file
    },
    'require_encryption': True,
    'auth': auth_token
}

cluster = LocalCluster(
    n_workers=2,
    threads_per_worker=2,
    dashboard_address=':8788',
    processes=False,
    security=security
)
client = Client(cluster)
print(f'Scheduler secundário: {cluster.scheduler_address}')
print('Scheduler secundário ativo. Pressione Ctrl+C para parar.')

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print('Encerrando scheduler secundário...')
    client.close()
    cluster.close()
"
EOF

    chmod +x /tmp/start_secondary_dask.sh
    nohup /tmp/start_secondary_dask.sh > /tmp/dask_secondary.log 2>&1 &
    echo $! > /tmp/dask_secondary.pid
}

# Função principal
main() {
    mkdir -p "${PROJECT_ROOT}/logs"

    echo "$(date): Verificando status do scheduler primário..." >> "$LOG_FILE"

    if check_scheduler "$PRIMARY_IP" "$PRIMARY_PORT"; then
        echo "$(date): Scheduler primário está ativo" >> "$LOG_FILE"
        exit 0
    fi

    echo "$(date): Scheduler primário está inativo. Verificando scheduler secundário..." >> "$LOG_FILE"

    if check_scheduler "$SECONDARY_IP" "$SECONDARY_PORT"; then
        echo "$(date): Scheduler secundário já está ativo" >> "$LOG_FILE"
        exit 0
    fi

    echo "$(date): Iniciando failover..." >> "$LOG_FILE"
    start_secondary_scheduler

    # Aguardar inicialização
    sleep 10

    if check_scheduler "$SECONDARY_IP" "$SECONDARY_PORT"; then
        echo "$(date): Failover concluído com sucesso" >> "$LOG_FILE"
        # Aqui poderia notificar workers para reconectar
    else
        echo "$(date): Falha no failover" >> "$LOG_FILE"
        exit 1
    fi
}

main "$@"
