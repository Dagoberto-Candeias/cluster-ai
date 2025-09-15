#!/bin/bash
#
# Configura o Dask Scheduler e Worker como serviços do systemd.
#

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em ${UTILS_DIR}/common.sh"
    exit 1
fi
source "${UTILS_DIR}/common.sh"

if [ "$EUID" -ne 0 ]; then
    error "Este script precisa ser executado com privilégios de superusuário (sudo) para instalar os serviços."
    exit 1
fi

VENV_PATH="${PROJECT_ROOT}/.venv/bin"
USER_EXEC=$(logname) # Pega o usuário que invocou o sudo

create_scheduler_service() {
    section "Criando serviço systemd para Dask Scheduler"

    local service_file="/etc/systemd/system/dask-scheduler.service"
    
    log "Criando arquivo de serviço em $service_file"

    cat << EOF > "$service_file"
[Unit]
Description=Dask Scheduler for Cluster AI
After=network.target

[Service]
User=$USER_EXEC
Group=$(id -gn "$USER_EXEC")
WorkingDirectory=$PROJECT_ROOT
ExecStart=${VENV_PATH}/dask-scheduler --host 0.0.0.0 --port 8786 --dashboard-address :8787
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    success "Arquivo de serviço do Dask Scheduler criado."
}

create_worker_service() {
    section "Criando serviço systemd para Dask Worker local"

    local service_file="/etc/systemd/system/dask-worker.service"
    
    log "Criando arquivo de serviço em $service_file"

    cat << EOF > "$service_file"
[Unit]
Description=Dask Local Worker for Cluster AI
After=dask-scheduler.service
Requires=dask-scheduler.service

[Service]
User=$USER_EXEC
Group=$(id -gn "$USER_EXEC")
WorkingDirectory=$PROJECT_ROOT
ExecStart=${VENV_PATH}/dask-worker tcp://127.0.0.1:8786 --nthreads 2 --memory-limit 4GB
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    success "Arquivo de serviço do Dask Worker criado."
    warn "NOTA: O worker está configurado com 2 threads e 4GB de RAM. Edite $service_file para ajustar."
}

main() {
    if [ ! -d "$VENV_PATH" ]; then
        error "Ambiente virtual não encontrado em $VENV_PATH. Execute o instalador primeiro."
        exit 1
    fi

    create_scheduler_service
    create_worker_service

    log "Recarregando o daemon do systemd..."
    systemctl daemon-reload

    log "Habilitando os serviços para iniciar no boot..."
    systemctl enable dask-scheduler.service
    systemctl enable dask-worker.service

    success "Serviços Dask configurados! Use 'sudo systemctl start dask-scheduler' para iniciar."
}

main "$@"