#!/bin/bash
# Script para criar e configurar o serviço systemd para o monitor de recursos.

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    # shellcheck source=../utils/common.sh
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
fi

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  error "Este script precisa ser executado com privilégios de root (sudo)."
  echo "   💡 Execute: sudo bash $0"
  exit 1
fi

section "Configuração do Serviço de Monitoramento de Recursos"

# Variáveis de configuração
SERVICE_NAME="resource-monitor.service"
SERVICE_FILE_PATH="/etc/systemd/system/$SERVICE_NAME"
PROJECT_ROOT="/home/dcm/Projetos/cluster-ai"
MONITOR_SCRIPT_PATH="$PROJECT_ROOT/scripts/utils/memory_monitor.sh"
LOG_DIR="/var/log/cluster-ai"
LOG_FILE="$LOG_DIR/resource_monitor.log"

# Perguntar o e-mail para alertas
read -p "Digite o e-mail para receber os alertas (deixe em branco para não enviar): " -r EMAIL_RECIPIENT
read -p "Habilitar reinicialização automática de serviços (Ollama)? (s/N): " -r ENABLE_AUTO_HEAL

# Verificar se o script de monitoramento existe
if [ ! -f "$MONITOR_SCRIPT_PATH" ]; then
    error "Script de monitoramento não encontrado em: $MONITOR_SCRIPT_PATH"
    exit 1
fi

# Criar diretório de log
log "Criando diretório de log em $LOG_DIR..."
mkdir -p "$LOG_DIR"
chown dcm:dcm "$LOG_DIR"
touch "$LOG_FILE"
chown dcm:dcm "$LOG_FILE"

# Construir o comando de execução
EXEC_COMMAND="$MONITOR_SCRIPT_PATH -l $LOG_FILE"
if [ -n "$EMAIL_RECIPIENT" ]; then
    EXEC_COMMAND+=" -e $EMAIL_RECIPIENT"
fi
if [[ "$ENABLE_AUTO_HEAL" =~ ^[Ss]$ ]]; then
    EXEC_COMMAND+=" --auto-heal"

    log "Configurando permissões de sudo para reinicialização automática de serviços..."
    SUDOERS_FILE="/etc/sudoers.d/99-resource-monitor-heal"
    # Escreve as permissões para Ollama e Docker no mesmo arquivo
    echo "dcm ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart ollama.service" > "$SUDOERS_FILE"
    echo "dcm ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart docker.service" >> "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    log "Permissões configuradas em $SUDOERS_FILE. Isso permite que o monitor reinicie Ollama e Docker sem senha."
fi

# Criar o conteúdo do arquivo de serviço
log "Criando o arquivo de serviço: $SERVICE_FILE_PATH"

cat > "$SERVICE_FILE_PATH" << EOL
[Unit]
Description=Monitor de Recursos do Cluster AI
After=network.target

[Service]
User=dcm
Group=dcm
WorkingDirectory=$PROJECT_ROOT
ExecStart=$EXEC_COMMAND
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

chmod 644 "$SERVICE_FILE_PATH"

log "Arquivo de serviço criado com sucesso."

section "Próximos Passos"
echo "Para habilitar e iniciar o serviço, execute os seguintes comandos:"
echo -e "  ${YELLOW}sudo systemctl daemon-reload${NC}"
echo -e "  ${YELLOW}sudo systemctl enable $SERVICE_NAME${NC}"
echo -e "  ${YELLOW}sudo systemctl start $SERVICE_NAME${NC}"
echo ""
echo "Para verificar o status do serviço:"
echo -e "  ${CYAN}sudo systemctl status $SERVICE_NAME${NC}"
echo ""
echo "Para ver os logs em tempo real:"
echo -e "  ${CYAN}journalctl -u $SERVICE_NAME -f${NC}"
echo "  ou"
echo -e "  ${CYAN}tail -f $LOG_FILE${NC}"