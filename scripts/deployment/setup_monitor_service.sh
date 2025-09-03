#!/bin/bash
# Script para criar e configurar o serviço systemd para o monitor de recursos.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Configuração do Serviço ---
SERVICE_NAME="cluster-monitor.service"
SERVICE_FILE_PATH="/etc/systemd/system/$SERVICE_NAME"
MONITOR_SCRIPT_PATH="${PROJECT_ROOT}/scripts/management/monitor_mode.sh"
# O usuário deve ser o mesmo que executa o projeto para ter acesso aos arquivos
SERVICE_USER="${SUDO_USER:-$(whoami)}"
TTY_NUMBER=8 # Usaremos o TTY8, que geralmente está livre

# --- Funções ---
main() {
    section "Configurando Serviço de Monitoramento Contínuo"

    if [[ $EUID -ne 0 ]]; then
        error "Este script precisa ser executado com privilégios de root (sudo)."
        info "Execute: sudo bash $0"
        return 1
    fi

    if [ -f "$SERVICE_FILE_PATH" ]; then
        success "O serviço de monitoramento '$SERVICE_NAME' já está configurado."
        log "Para reiniciar: sudo systemctl restart $SERVICE_NAME"
        log "Para ver o status, mude para o terminal 8 (Ctrl+Alt+F8)."
        return 0
    fi

    log "Criando o arquivo de serviço: $SERVICE_FILE_PATH"

    # Conteúdo do arquivo de serviço
    tee "$SERVICE_FILE_PATH" > /dev/null << EOL
[Unit]
Description=Cluster AI Continuous Status Monitor
After=network.target

[Service]
User=$SERVICE_USER
Group=$(id -gn "$SERVICE_USER")
WorkingDirectory=$PROJECT_ROOT
ExecStart=/bin/bash $MONITOR_SCRIPT_PATH

# Configurações para rodar em um terminal virtual (TTY)
StandardInput=tty-force
StandardOutput=tty
TTYPath=/dev/tty$TTY_NUMBER
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

    chmod 644 "$SERVICE_FILE_PATH"
    log "Arquivo de serviço criado com sucesso."

    if confirm_operation "Deseja habilitar e iniciar o serviço agora?"; then
        log "Recarregando o daemon do systemd..."
        systemctl daemon-reload
        log "Habilitando o serviço para iniciar no boot..."
        systemctl enable "$SERVICE_NAME"
        log "Iniciando o serviço..."
        systemctl start "$SERVICE_NAME"
        
        success "Serviço '$SERVICE_NAME' configurado e iniciado!"
        log "Para ver o monitor, mude para o terminal 8 (pressione Ctrl+Alt+F8)."
        log "Para voltar à sua sessão gráfica, use Ctrl+Alt+F1 ou Ctrl+Alt+F7 (depende da sua distro)."
    else
        warn "Configuração do serviço concluída, mas não foi habilitado ou iniciado."
        log "Para habilitar e iniciar manualmente, execute:"
        log "  sudo systemctl daemon-reload && sudo systemctl enable --now $SERVICE_NAME"
    fi
}

main "$@"