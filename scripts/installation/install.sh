#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Unified Installation Script
# Script de instalação unificado e inteligente do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script principal para instalação completa e inteligente do Cluster AI.
#   Detecta hardware automaticamente, instala dependências, configura
#   componentes e inicializa o sistema. Suporta diferentes perfis de
#   instalação (desenvolvimento, produção, workstation).
#
# Uso:
#   ./scripts/installation/install.sh [opções]
#
# Dependências:
#   - bash
#   - curl, wget
#   - sudo (para instalação de pacotes)
#   - python3 (para scripts auxiliares)
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
INSTALL_LOG="$LOG_DIR/install.log"

# Configurações padrão
DEFAULT_PROFILE="auto"
SUPPORTED_PROFILES=("auto" "development" "production" "workstation" "minimal")
COMPONENTS=("dask" "ollama" "openwebui" "monitoring" "security")

# Arrays para controle
INSTALLED_COMPONENTS=()
FAILED_COMPONENTS=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para detectar hardware
detect_hardware() {
    log_info "Detectando hardware do sistema..."

    local hardware_info=()

    # Detectar CPU
    if command -v lscpu &> /dev/null; then
        local cpu_cores=$(lscpu -p | grep -c "^[0-9]")
        hardware_info+=("CPU: $cpu_cores cores")
    fi

    # Detectar RAM
    if command -v free &> /dev/null; then
        local ram_gb=$(free -g | awk 'NR==2{printf "%.0f", $2}')
        hardware_info+=("RAM: ${ram_gb}GB")
    fi

    # Detectar GPU
    if command -v nvidia-smi &> /dev/null; then
        hardware_info+=("GPU: NVIDIA (CUDA)")
    elif command -v rocm-smi &> /dev/null; then
        hardware_info+=("GPU: AMD (ROCm)")
    else
        hardware_info+=("GPU: CPU only")
    fi

    # Detectar SO
    if [ -f /etc/os-release ]; then
        local os_name=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        hardware_info+=("OS: $os_name")
    fi

    log_success "Hardware detectado: ${hardware_info[*]}"
    return 0
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do sistema..."

    local missing_deps=()
    local required_commands=(
        "curl"
        "wget"
        "sudo"
        "python3"
        "git"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Todas as dependências verificadas"
    return 0
}

# Função para instalar componente
install_component() {
    local component=$1
    log_info "Instalando componente: $component"

    case $component in
        "dask")
            if [ -f "setup_dask.sh" ]; then
                bash setup_dask.sh >> "$INSTALL_LOG" 2>&1
                if [ $? -eq 0 ]; then
                    INSTALLED_COMPONENTS+=("Dask")
                    log_success "Dask instalado"
                    return 0
                fi
            fi
            ;;
        "ollama")
            if [ -f "setup_ollama.sh" ]; then
                bash setup_ollama.sh >> "$INSTALL_LOG" 2>&1
                if [ $? -eq 0 ]; then
                    INSTALLED_COMPONENTS+=("Ollama")
                    log_success "Ollama instalado"
                    return 0
                fi
            fi
            ;;
        "openwebui")
            if [ -f "setup_openwebui.sh" ]; then
                bash setup_openwebui.sh >> "$INSTALL_LOG" 2>&1
                if [ $? -eq 0 ]; then
                    INSTALLED_COMPONENTS+=("OpenWebUI")
                    log_success "OpenWebUI instalado"
                    return 0
                fi
            fi
            ;;
        "monitoring")
            if [ -f "setup_monitoring.sh" ]; then
                bash setup_monitoring.sh >> "$INSTALL_LOG" 2>&1
                if [ $? -eq 0 ]; then
                    INSTALLED_COMPONENTS+=("Monitoring")
                    log_success "Monitoring instalado"
                    return 0
                fi
            fi
            ;;
        "security")
            if [ -f "setup_security.sh" ]; then
                bash setup_security.sh >> "$INSTALL_LOG" 2>&1
                if [ $? -eq 0 ]; then
                    INSTALLED_COMPONENTS+=("Security")
                    log_success "Security instalado"
                    return 0
                fi
            fi
            ;;
        *)
            log_error "Componente desconhecido: $component"
            return 1
            ;;
    esac

    log_error "Falha ao instalar $component"
    FAILED_COMPONENTS+=("$component")
    return 1
}

# Função para configurar sistema
configure_system() {
    log_info "Configurando sistema..."

    # Criar diretórios necessários
    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_ROOT/models"
    mkdir -p "$PROJECT_ROOT/configs"
    mkdir -p "$PROJECT_ROOT/backups"

    # Configurar permissões
    chmod +x "$PROJECT_ROOT/scripts/"*.sh 2>/dev/null || true

    log_success "Sistema configurado"
}

# Função para verificar instalação
verify_installation() {
    log_info "Verificando instalação..."

    local issues=()

    # Verificar se componentes estão acessíveis
    for component in "${INSTALLED_COMPONENTS[@]}"; do
        case $component in
            "Dask")
                if ! curl -s "http://localhost:8787" > /dev/null 2>&1; then
                    issues+=("Dask Dashboard não responde")
                fi
                ;;
            "Ollama")
                if ! curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
                    issues+=("Ollama API não responde")
                fi
                ;;
            "OpenWebUI")
                if ! curl -s "http://localhost:3000" > /dev/null 2>&1; then
                    issues+=("OpenWebUI não responde")
                fi
                ;;
        esac
    done

    if [ ${#issues[@]} -gt 0 ]; then
        log_warning "Problemas detectados:"
        printf '%s\n' "${issues[@]}" >&2
        return 1
    fi

    log_success "Instalação verificada com sucesso"
    return 0
}

# Função para mostrar status final
show_final_status() {
    log_info "=== STATUS FINAL DA INSTALAÇÃO ==="

    echo "✅ Componentes Instalados:"
    if [ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]; then
        printf '  - %s\n' "${INSTALLED_COMPONENTS[@]}"
    else
        echo "  Nenhum"
    fi

    echo "❌ Componentes com Falha:"
    if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
        printf '  - %s\n' "${FAILED_COMPONENTS[@]}"
    else
        echo "  Nenhum"
    fi

    echo "🌐 URLs de Acesso:"
    echo "  - OpenWebUI: http://localhost:3000"
    echo "  - Dask Dashboard: http://localhost:8787"
    echo "  - Ollama API: http://localhost:11434"

    echo "📝 Logs:"
    echo "  - Instalação: $INSTALL_LOG"
    echo "  - Sistema: $LOG_DIR/"

    echo "🚀 Próximos Passos:"
    echo "  1. Execute: ./scripts/start_cluster_complete.sh start"
    echo "  2. Acesse: http://localhost:3000"
    echo "  3. Configure modelos: ollama pull llama3:8b"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$INSTALL_LOG"

    local profile="${1:-$DEFAULT_PROFILE}"

    case "$profile" in
        "auto")
            log_info "🚀 Iniciando instalação automática do Cluster AI..."

            # Verificações iniciais
            detect_hardware
            check_dependencies || exit 1

            # Configurar sistema
            configure_system

            # Instalar componentes
            for component in "${COMPONENTS[@]}"; do
                install_component "$component"
            done

            # Verificar instalação
            verify_installation

            # Status final
            show_final_status
            ;;
        "development")
            log_info "🚀 Instalando perfil de desenvolvimento..."
            COMPONENTS=("dask" "ollama" "openwebui")
            main "auto"
            ;;
        "production")
            log_info "🚀 Instalando perfil de produção..."
            COMPONENTS=("dask" "ollama" "openwebui" "monitoring" "security")
            main "auto"
            ;;
        "workstation")
            log_info "🚀 Instalando perfil workstation..."
            COMPONENTS=("dask" "ollama" "openwebui" "monitoring")
            main "auto"
            ;;
        "minimal")
            log_info "🚀 Instalando perfil mínimo..."
            COMPONENTS=("ollama")
            main "auto"
            ;;
        "help"|*)
            echo "Cluster AI - Unified Installation Script"
            echo ""
            echo "Uso: $0 [perfil]"
            echo ""
            echo "Perfis de Instalação:"
            echo "  auto          - Instalação automática (padrão)"
            echo "  development   - Perfil de desenvolvimento"
            echo "  production    - Perfil de produção"
            echo "  workstation   - Perfil workstation"
            echo "  minimal       - Instalação mínima"
            echo "  help          - Mostra esta mensagem"
            echo ""
            echo "Exemplos:"
            echo "  $0 auto"
            echo "  $0 production"
            echo "  $0 development"
            echo ""
            echo "O script detectará automaticamente seu hardware e instalará"
            echo "os componentes apropriados para seu sistema."
            ;;
    esac
}

# Executar função principal
main "$@"
