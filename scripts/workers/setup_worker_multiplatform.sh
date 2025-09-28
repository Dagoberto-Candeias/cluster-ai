#!/bin/bash
# =============================================================================
# Setup Multi-Plataforma - Worker Cluster AI
# =============================================================================
# Script unificado que funciona em Termux (Android), Debian, Manjaro e outras distros
# Detecta automaticamente a plataforma e adapta a instalação
#
# Autor: Cluster AI Team
# Data: 2025-09-23
# Versão: 1.0.0
# Arquivo: setup_worker_multiplatform.sh
# =============================================================================

set -euo pipefail

# --- Importar detector de plataforma ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_platform.sh"

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Configurações ---
readonly TIMEOUT_INSTALL=300  # 5 minutos para instalação
readonly TIMEOUT_CLONE=120   # 2 minutos para clone
readonly TIMEOUT_UPDATE=60   # 1 minuto para update
readonly SSH_PORT=8022

# --- Funções de logging ---
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $*"
}

section() {
    echo
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN} $1 ${NC}"
    echo -e "${GREEN}=================================================${NC}"
}

# --- Funções auxiliares ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_with_timeout() {
    local timeout_duration="$1"
    local command="$2"
    local description="$3"

    log_info "$description..."

    if timeout "$timeout_duration" bash -c "$command" 2>&1; then
        log_success "$description concluída"
        return 0
    else
        log_warn "Timeout em: $description"
        return 1
    fi
}

# --- Função para detectar e configurar plataforma ---
setup_platform_specific() {
    local platform
    platform=$(detect_platform)

    log_info "Detectando plataforma: $platform"

    case "$platform" in
        "termux")
            setup_termux
            ;;
        "debian"|"ubuntu")
            setup_debian_based
            ;;
        "manjaro"|"arch")
            setup_arch_based
            ;;
        "centos")
            setup_centos
            ;;
        "linux")
            setup_linux_generic
            ;;
        *)
            log_error "Plataforma não suportada: $platform"
            exit 1
            ;;
    esac
}

# --- Setup específico para Termux/Android ---
setup_termux() {
    log_info "Configurando para Termux (Android)..."

    # Configurar armazenamento
    if [ ! -d "$HOME/storage" ]; then
        log_info "Configurando armazenamento do Termux..."
        termux-setup-storage
        sleep 3
    fi

    # Instalar dependências do Termux
    log_info "Instalando dependências do Termux..."
    if ! run_with_timeout 300 "pkg update -y && pkg install -y openssh python git" "Instalando dependências Termux"; then
        log_error "Falha ao instalar dependências do Termux"
        exit 1
    fi
}

# --- Setup específico para Debian/Ubuntu ---
setup_debian_based() {
    log_info "Configurando para Debian/Ubuntu..."

    # Atualizar sistema
    if command_exists apt; then
        log_info "Atualizando sistema..."
        if ! run_with_timeout 300 "apt update && apt upgrade -y" "Atualizando sistema"; then
            log_warn "Falha na atualização, continuando..."
        fi

        # Instalar dependências
        log_info "Instalando dependências..."
        if ! run_with_timeout 300 "apt install -y openssh-server python3 python3-pip git" "Instalando dependências"; then
            log_error "Falha ao instalar dependências"
            exit 1
        fi
    else
        log_error "Gerenciador de pacotes apt não encontrado"
        exit 1
    fi
}

# --- Setup específico para Manjaro/Arch ---
setup_arch_based() {
    log_info "Configurando para Manjaro/Arch..."

    # Atualizar sistema
    if command_exists pacman; then
        log_info "Atualizando sistema..."
        if ! run_with_timeout 300 "pacman -Syu --noconfirm" "Atualizando sistema"; then
            log_warn "Falha na atualização, continuando..."
        fi

        # Instalar dependências
        log_info "Instalando dependências..."
        if ! run_with_timeout 300 "pacman -S --noconfirm openssh python python-pip git" "Instalando dependências"; then
            log_error "Falha ao instalar dependências"
            exit 1
        fi
    else
        log_error "Gerenciador de pacotes pacman não encontrado"
        exit 1
    fi
}

# --- Setup específico para CentOS ---
setup_centos() {
    log_info "Configurando para CentOS..."

    # Instalar dependências
    if command_exists yum; then
        log_info "Instalando dependências..."
        if ! run_with_timeout 300 "yum install -y openssh-server python3 python3-pip git" "Instalando dependências"; then
            log_error "Falha ao instalar dependências"
            exit 1
        fi
    else
        log_error "Gerenciador de pacotes yum não encontrado"
        exit 1
    fi
}

# --- Setup genérico para Linux ---
setup_linux_generic() {
    log_info "Configurando para Linux genérico..."

    # Tentar detectar gerenciador de pacotes
    local pm
    pm=$(get_package_manager "$(detect_platform)")

    case "$pm" in
        "apt")
            setup_debian_based
            ;;
        "pacman")
            setup_arch_based
            ;;
        "yum")
            setup_centos
            ;;
        *)
            log_error "Não foi possível detectar gerenciador de pacotes"
            log_info "Instale manualmente: openssh-server, python3, python3-pip, git"
            exit 1
            ;;
    esac
}

# --- Configuração comum de SSH ---
setup_ssh() {
    section "🔐 CONFIGURAÇÃO SSH"

    local platform
    platform=$(detect_platform)

    # Criar diretório SSH
    mkdir -p "$HOME/.ssh"

    # Gerar chave SSH se não existir
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log_info "Gerando chave SSH..."
        if run_with_timeout 30 "ssh-keygen -t rsa -b 2048 -N '' -f '$HOME/.ssh/id_rsa' -C 'cluster-ai-worker-$(date +%s)'" "Gerando chave SSH"; then
            log_success "Chave SSH gerada"
        else
            log_error "Falha ao gerar chave SSH"
            exit 1
        fi
    else
        log_success "Chave SSH já existe"
    fi

    # Configurar SSH para diferentes plataformas
    if is_android "$(detect_platform)"; then
        # Termux: iniciar SSH daemon diretamente
        log_info "Iniciando servidor SSH na porta $SSH_PORT..."
        if run_with_timeout 10 "sshd" "Iniciando servidor SSH"; then
            log_success "Servidor SSH iniciado na porta $SSH_PORT"
        else
            log_warn "Servidor SSH pode já estar rodando"
        fi
    else
        # Linux: configurar e iniciar serviço SSH
        log_info "Configurando serviço SSH..."

        # Criar arquivo de configuração SSH se não existir
        if [ ! -f "/etc/ssh/sshd_config" ]; then
            log_error "Arquivo de configuração SSH não encontrado"
            exit 1
        fi

        # Verificar se a porta 8022 está liberada
        if ! grep -q "Port $SSH_PORT" /etc/ssh/sshd_config; then
            log_info "Adicionando porta $SSH_PORT ao SSH..."
            echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
        fi

        # Iniciar serviço SSH
        if command_exists systemctl; then
            if ! run_with_timeout 10 "systemctl enable ssh && systemctl start ssh" "Iniciando serviço SSH"; then
                log_warn "Falha ao iniciar SSH via systemctl, tentando método alternativo..."
                if ! run_with_timeout 10 "service ssh start" "Iniciando serviço SSH"; then
                    log_warn "Falha ao iniciar SSH, tentando iniciar manualmente..."
                    sshd -p "$SSH_PORT"
                fi
            fi
        elif command_exists service; then
            if ! run_with_timeout 10 "service ssh start" "Iniciando serviço SSH"; then
                log_warn "Iniciando SSH manualmente..."
                sshd -p "$SSH_PORT"
            fi
        else
            log_warn "Iniciando SSH manualmente..."
            sshd -p "$SSH_PORT"
        fi

        log_success "Servidor SSH configurado na porta $SSH_PORT"
    fi
}

# --- Clonagem do projeto ---
clone_project() {
    section "📥 BAIXANDO PROJETO CLUSTER AI"

    local project_dir
    project_dir=$(get_platform_config "$(detect_platform)" "project_dir")

    if [ ! -d "$project_dir" ]; then
        mkdir -p "$(dirname "$project_dir")"

        # Tentar SSH primeiro (para repositórios privados)
        log_info "Tentando clonar via SSH..."
        if run_with_timeout 120 "git clone git@github.com:Dagoberto-Candeias/cluster-ai.git '$project_dir'" "Clonando via SSH"; then
            log_success "Projeto clonado via SSH"
        else
            log_warn "SSH falhou, tentando via HTTPS..."
            # Fallback para HTTPS
            if run_with_timeout 120 "git clone https://github.com/Dagoberto-Candeias/cluster-ai.git '$project_dir'" "Clonando via HTTPS"; then
                log_success "Projeto clonado via HTTPS"
            else
                log_error "Falha ao clonar repositório"
                exit 1
            fi
        fi
    else
        log_info "Projeto já existe, verificando atualizações..."
        cd "$project_dir"
        if run_with_timeout 60 "git pull" "Atualizando projeto"; then
            log_success "Projeto atualizado"
        else
            log_warn "Falha ao atualizar, continuando com versão existente"
        fi
    fi
}

# --- Configuração final ---
final_configuration() {
    section "⚙️ CONFIGURAÇÃO FINAL"

    local project_dir
    project_dir=$(get_platform_config "$(detect_platform)" "project_dir")

    cd "$project_dir"

    # Instalar Dask para o worker
    log_info "Instalando Dask para o worker..."
    if run_with_timeout 120 "pip install dask[distributed]" "Instalando Dask"; then
        log_success "Dask instalado com sucesso"
    else
        log_warn "Falha ao instalar Dask, mas continuando..."
    fi

    # Otimizações específicas da plataforma
    optimize_for_platform

    log_success "Configuração final concluída"
}

# --- Otimizações específicas da plataforma ---
optimize_for_platform() {
    local platform
    platform=$(detect_platform)

    log_info "Aplicando otimizações para $platform..."

    if is_android "$platform"; then
        # Otimizações para Android/Termux
        if command_exists termux-wake-lock; then
            termux-wake-lock
            log_success "Wake lock ativado para manter o dispositivo acordado"
        fi

        # Configurar animações
        settings put system animator_duration_scale 0.5 2>/dev/null || true
        settings put system transition_animation_scale 0.5 2>/dev/null || true
        settings put system window_animation_scale 0.5 2>/dev/null || true

        log_success "Otimização para Android aplicada"
    else
        # Otimizações para Linux desktop
        log_info "Configurações de Linux aplicadas"
    fi
}

# --- Exibir informações finais ---
show_final_info() {
    section "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"

    local platform
    platform=$(detect_platform)

    echo
    echo "📱 Worker configurado para: $(get_platform_info "$platform")"
    echo
    echo "🔑 CHAVE SSH PÚBLICA (copie tudo abaixo):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "🌐 INFORMAÇÕES DE CONEXÃO:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo 'Verifique rede')"
    echo "   Porta SSH: $SSH_PORT"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Copie a chave SSH acima"
    echo "2. No seu servidor principal, execute: ./manager.sh"
    echo "3. Escolha: 'Configurar Cluster' > 'Gerenciar Workers Remotos'"
    echo "4. Configure um worker $(get_platform_info "$platform")"
    echo "5. Cole a chave SSH quando solicitado"
    echo "6. Digite o IP do worker e porta $SSH_PORT"
    echo
    echo "🧪 Para testar: bash $HOME/Projetos/cluster-ai/scripts/workers/test_worker_multiplatform.sh"
    echo
}

# --- Função principal ---
main() {
    section "🤖 CLUSTER AI - SETUP MULTI-PLATAFORMA"
    echo "Suporte: Termux (Android), Debian, Manjaro, Ubuntu, CentOS"
    echo "Tempo estimado: 3-8 minutos"
    echo

    # Detectar e configurar plataforma
    setup_platform_specific

    # Configurações comuns
    setup_ssh
    clone_project
    final_configuration
    show_final_info

    echo "🎊 Pronto! Seu sistema agora é um worker do Cluster AI!"
    echo
}

# --- Execução ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
