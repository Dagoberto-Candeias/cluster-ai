#!/bin/bash
# =============================================================================
# Detector de Plataforma Multi-Worker - Cluster AI
# =============================================================================
# Detecta automaticamente o ambiente onde o script está rodando
# Suporte: Termux (Android), Debian, Manjaro, Ubuntu, CentOS, etc.
#
# Autor: Cluster AI Team
# Data: 2025-09-23
# Versão: 1.0.0
# Arquivo: detect_platform.sh
# =============================================================================

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções de detecção ---
detect_termux() {
    if [ -d "/data/data/com.termux" ]; then
        echo "termux"
        return 0
    fi
    return 1
}

detect_debian() {
    if [ -f "/etc/debian_version" ]; then
        echo "debian"
        return 0
    fi
    return 1
}

detect_manjaro() {
    if [ -f "/etc/manjaro-release" ]; then
        echo "manjaro"
        return 0
    fi
    return 1
}

detect_ubuntu() {
    if [ -f "/etc/lsb-release" ] && grep -q "Ubuntu" /etc/lsb-release; then
        echo "ubuntu"
        return 0
    fi
    return 1
}

detect_centos() {
    if [ -f "/etc/centos-release" ] || [ -f "/etc/redhat-release" ]; then
        echo "centos"
        return 0
    fi
    return 1
}

detect_arch() {
    if [ -f "/etc/arch-release" ]; then
        echo "arch"
        return 0
    fi
    return 1
}

# --- Função principal de detecção ---
detect_platform() {
    local platform="unknown"

    # Verificar plataformas específicas primeiro
    if detect_termux >/dev/null 2>&1; then
        platform="termux"
    elif detect_manjaro >/dev/null 2>&1; then
        platform="manjaro"
    elif detect_debian >/dev/null 2>&1; then
        platform="debian"
    elif detect_ubuntu >/dev/null 2>&1; then
        platform="ubuntu"
    elif detect_centos >/dev/null 2>&1; then
        platform="centos"
    elif detect_arch >/dev/null 2>&1; then
        platform="arch"
    else
        # Fallback: verificar se é Linux genérico
        if [ "$(uname)" = "Linux" ]; then
            platform="linux"
        fi
    fi

    echo "$platform"
}

# --- Função para obter informações da plataforma ---
get_platform_info() {
    local platform="$1"

    case "$platform" in
        "termux")
            echo "Android com Termux"
            ;;
        "debian")
            echo "Debian Linux"
            ;;
        "manjaro")
            echo "Manjaro Linux"
            ;;
        "ubuntu")
            echo "Ubuntu Linux"
            ;;
        "centos")
            echo "CentOS Linux"
            ;;
        "arch")
            echo "Arch Linux"
            ;;
        "linux")
            echo "Linux Genérico"
            ;;
        *)
            echo "Plataforma Desconhecida"
            ;;
    esac
}

# --- Função para obter comandos específicos da plataforma ---
get_package_manager() {
    local platform="$1"

    case "$platform" in
        "termux")
            echo "pkg"
            ;;
        "debian"|"ubuntu")
            echo "apt"
            ;;
        "manjaro"|"arch")
            echo "pacman"
            ;;
        "centos")
            echo "yum"
            ;;
        *)
            # Tentar detectar automaticamente
            if command -v apt >/dev/null 2>&1; then
                echo "apt"
            elif command -v pacman >/dev/null 2>&1; then
                echo "pacman"
            elif command -v yum >/dev/null 2>&1; then
                echo "yum"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# --- Função para verificar se é Android/Termux ---
is_android() {
    local platform="$1"
    [ "$platform" = "termux" ]
}

# --- Função para verificar se é Linux desktop ---
is_linux_desktop() {
    local platform="$1"
    [ "$platform" != "termux" ] && [ "$platform" != "unknown" ]
}

# --- Função para obter configurações específicas ---
get_platform_config() {
    local platform="$1"
    local config_type="$2"

    case "$config_type" in
        "ssh_port")
            echo "8022"
            ;;
        "storage_dir")
            if is_android "$platform"; then
                echo "$HOME/storage"
            else
                echo "$HOME/cluster-storage"
            fi
            ;;
        "project_dir")
            echo "$HOME/Projetos/cluster-ai"
            ;;
        "log_dir")
            echo "$HOME/Projetos/cluster-ai/logs"
            ;;
        "ssh_key_path")
            echo "$HOME/.ssh/id_rsa"
            ;;
        "termux_api")
            if is_android "$platform"; then
                echo "termux-api"
            else
                echo ""
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# --- Função para exibir informações da plataforma ---
show_platform_info() {
    local platform
    platform=$(detect_platform)

    echo -e "${BLUE}=== INFORMAÇÕES DA PLATAFORMA ===${NC}"
    echo -e "Plataforma detectada: ${GREEN}$(get_platform_info "$platform")${NC}"
    echo -e "Código da plataforma: ${YELLOW}$platform${NC}"
    echo -e "Gerenciador de pacotes: ${YELLOW}$(get_package_manager "$platform")${NC}"
    echo -e "Diretório de armazenamento: ${YELLOW}$(get_platform_config "$platform" "storage_dir")${NC}"
    echo -e "Porta SSH: ${YELLOW}$(get_platform_config "$platform" "ssh_port")${NC}"
    echo -e "Diretório do projeto: ${YELLOW}$(get_platform_config "$platform" "project_dir")${NC}"
    echo
}

# --- Executar se chamado diretamente ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_platform_info
fi
