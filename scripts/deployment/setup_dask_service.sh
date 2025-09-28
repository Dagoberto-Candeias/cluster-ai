#!/bin/bash
# =============================================================================
# Configura o Dask Scheduler e Worker como serviços do systemd.
# =============================================================================
# Configura o Dask Scheduler e Worker como serviços do systemd.
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: setup_dask_service.sh
# =============================================================================

# Definindo variáveis
USER_EXEC=$(whoami)
PROJECT_ROOT=$(pwd)
VENV_PATH="${PROJECT_ROOT}/.venv"

# Criando serviços systemd
create_scheduler_service() {
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
ExecStart=${VENV_PATH}/dask scheduler --host 0.0.0.0 --port 8786 --dashboard-address :8787
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    success "Arquivo de serviço do Dask Scheduler criado."
}

create_worker_service() {
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
