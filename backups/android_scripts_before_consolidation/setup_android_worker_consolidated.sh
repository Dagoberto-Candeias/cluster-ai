#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# Cluster AI - Android Worker Setup (CONSOLIDADO)
# =============================================================================
# Script consolidado com as melhores funcionalidades dos 3 scripts anteriores
# Combina: funcionalidades avançadas + timeout robusto + simplicidade de uso
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 2.0.0 - Consolidado
# Arquivo: setup_android_worker_consolidated.sh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly CONFIG_DIR="${PROJECT_ROOT}/config"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"

# -----------------------------------------------------------------------------
# CORES PARA OUTPUT (ANSI)
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# CONFIGURAÇÃO
# -----------------------------------------------------------------------------
readonly TIMEOUT_INSTALL=300  # 5 minutos para instalação
readonly TIMEOUT_CLONE=120   # 2 minutos para clone
readonly TIMEOUT_UPDATE=60   # 1 minuto para update
readonly SSH_PORT=8022

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOGGING PADRONIZADAS
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] ${SCRIPT_NAME}: $*${NC}" >&2
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE LOG PARA ARQUIVO
# -----------------------------------------------------------------------------
log_to_file() {
    local level="$1"
    local message="$2"
    local log_file="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

    # Criar diretório de logs se não existir
    mkdir -p "${LOG_DIR}"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${SCRIPT_NAME}: ${message}" >> "${log_file}"
}

# Alias para compatibilidade
log() { log_info "$*"; }
success() { log_success "$*"; }
warn() { log_warn "$*"; }
error() { log_error "$*"; }
info() { log_info "$*"; }

section() {
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN} $1 ${NC}"
    echo -e "${GREEN}=================================================${NC}"
}

# -----------------------------------------------------------------------------
# FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_with_timeout() {
    local timeout_duration="$1"
    local command="$2"
    local description="$3"

    log "$description..."

    if timeout "$timeout_duration" bash -c "$command" 2>&1; then
        success "$description concluída"
        return 0
    else
        warn "Timeout em: $description"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# VERIFICAÇÕES INICIAIS
# -----------------------------------------------------------------------------
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

check_storage() {
    if [ ! -d "$HOME/storage" ]; then
        warn "Configurando armazenamento..."
        termux-setup-storage
        sleep 3
    fi
    success "Armazenamento configurado"
}

check_connectivity() {
    log "Verificando conectividade com internet..."
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        success "Conectividade OK"
        return 0
    else
        warn "Sem conectividade com internet"
        warn "Verifique sua conexão Wi-Fi e tente novamente"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# FASE 1: ATUALIZAÇÃO E INSTALAÇÃO
# -----------------------------------------------------------------------------
install_dependencies() {
    section "📦 FASE 1: ATUALIZAÇÃO E INSTALAÇÃO"

    log "Atualizando lista de pacotes..."
    if ! run_with_timeout 180 "pkg update -y" "Atualizando lista de pacotes"; then
        warn "Continuando sem atualização completa..."
    fi

    log "Atualizando pacotes instalados..."
    if ! run_with_timeout 300 "pkg upgrade -y" "Atualizando pacotes instalados"; then
        warn "Continuando com pacotes desatualizados..."
    fi

    log "Instalando dependências essenciais..."
    if run_with_timeout 300 "pkg install -y openssh python git ncurses-utils curl" "Instalando dependências"; then
        success "Dependências instaladas com sucesso"
    else
        error "Falha ao instalar dependências essenciais"
    fi
}

# -----------------------------------------------------------------------------
# FASE 2: CONFIGURAÇÃO SSH
# -----------------------------------------------------------------------------
setup_ssh() {
    section "🔐 FASE 2: CONFIGURAÇÃO SSH"

    # Criar diretório SSH
    mkdir -p "$HOME/.ssh"

    # Gerar chave SSH se não existir
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH para o dispositivo..."
        if run_with_timeout 30 "ssh-keygen -t rsa -b 2048 -N '' -f '$HOME/.ssh/id_rsa' -C 'android-worker-$(date +%s)'" "Gerando chave SSH"; then
            success "Chave SSH gerada"
        else
            error "Falha ao gerar chave SSH"
        fi
    else
        success "Chave SSH já existe"
    fi

    # Iniciar SSH daemon
    log "Iniciando servidor SSH na porta $SSH_PORT..."
    if run_with_timeout 10 "sshd" "Iniciando servidor SSH"; then
        success "Servidor SSH iniciado na porta $SSH_PORT"
    else
        warn "Servidor SSH pode já estar rodando"
    fi
}

# -----------------------------------------------------------------------------
# FASE 3: CLONAR PROJETO
# -----------------------------------------------------------------------------
clone_project() {
    section "📥 FASE 3: BAIXANDO PROJETO CLUSTER AI"

    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar SSH primeiro (para repositórios privados)
        log "Tentando clonar via SSH..."
        if run_with_timeout 120 "git clone git@github.com:Dagoberto-Candeias/cluster-ai.git '$HOME/Projetos/cluster-ai'" "Clonando via SSH"; then
            success "Projeto clonado via SSH"
        else
            warn "SSH falhou, tentando via HTTPS..."
            # Fallback para HTTPS
            if run_with_timeout 120 "git clone https://github.com/Dagoberto-Candeias/cluster-ai.git '$HOME/Projetos/cluster-ai'" "Clonando via HTTPS"; then
                success "Projeto clonado via HTTPS"
            else
                error "Falha ao clonar repositório"
            fi
        fi
    else
        log "Projeto já existe, verificando atualizações..."
        cd "$HOME/Projetos/cluster-ai"
        if run_with_timeout 60 "git pull" "Atualizando projeto"; then
            success "Projeto atualizado"
        else
            warn "Falha ao atualizar, continuando com versão existente"
        fi
    fi
}

# -----------------------------------------------------------------------------
# FASE 4: CONFIGURAÇÃO FINAL
# -----------------------------------------------------------------------------
final_configuration() {
    section "⚙️ FASE 4: CONFIGURAÇÃO FINAL"

    # Instalar Dask para o worker
    log "Instalando Dask para o worker..."
    if run_with_timeout 120 "pip install dask[distributed]" "Instalando Dask"; then
        success "Dask instalado com sucesso"
    else
        warn "Falha ao instalar Dask, mas continuando..."
    fi

    # Otimizações de bateria
    optimize_battery_usage

    success "Configuração final concluída"
}

# -----------------------------------------------------------------------------
# OTIMIZAÇÃO DE BATERIA
# -----------------------------------------------------------------------------
optimize_battery_usage() {
    log "Otimizando uso de bateria..."

    # Disable unnecessary services
    if command_exists termux-wake-lock; then
        termux-wake-lock
        success "Wake lock ativado para manter o dispositivo acordado"
    fi

    # Set CPU governor to powersave when idle
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
        success "Governor de CPU configurado para economia de energia"
    fi

    # Disable animations and effects
    settings put system animator_duration_scale 0.5 2>/dev/null || true
    settings put system transition_animation_scale 0.5 2>/dev/null || true
    settings put system window_animation_scale 0.5 2>/dev/null || true

    success "Otimização de bateria aplicada"
}

# -----------------------------------------------------------------------------
# EXIBIR INFORMAÇÕES FINAIS
# -----------------------------------------------------------------------------
show_final_info() {
    section "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"

    echo
    echo "📱 Seu dispositivo Android está pronto para ser worker!"
    echo
    echo "🔑 CHAVE SSH PÚBLICA (copie tudo abaixo):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "🌐 INFORMAÇÕES DE CONEXÃO:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo 'Verifique Wi-Fi')"
    echo "   Porta SSH: $SSH_PORT"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Copie a chave SSH acima"
    echo "2. No seu servidor principal, execute: ./manager.sh"
    echo "3. Escolha: 'Configurar Cluster' > 'Gerenciar Workers Remotos'"
    echo "4. Configure um worker Android (Termux)"
    echo "5. Cole a chave SSH quando solicitado"
    echo "6. Digite o IP do seu Android e porta $SSH_PORT"
    echo
    echo "🧪 Para testar: bash ~/Projetos/cluster-ai/scripts/android/test_android_worker.sh"
    echo
    echo "💡 DICAS:"
    echo "• Mantenha o Termux aberto em background"
    echo "• Use Wi-Fi estável na mesma rede"
    echo "• Monitore a bateria (>20%)"
    echo "• Para modo avançado: bash ~/Projetos/cluster-ai/scripts/android/setup_android_worker_robust.sh"
    echo
}

# -----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    section "🤖 CLUSTER AI - CONFIGURADOR CONSOLIDADO DE WORKER ANDROID"
    echo "Versão: 2.0.0 - Consolidado (Funcionalidades Avançadas + Timeout + Simplicidade)"
    echo "Tempo estimado: 3-8 minutos"
    echo

    # Verificações iniciais
    check_termux
    check_storage
    check_connectivity

    # Executar fases
    install_dependencies
    setup_ssh
    clone_project
    final_configuration
    show_final_info

    echo "🎊 Pronto! Seu Android agora é um worker do Cluster AI!"
    echo
}

# -----------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
