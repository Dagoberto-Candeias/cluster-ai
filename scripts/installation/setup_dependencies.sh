#!/bin/bash
# Script de Setup para Dependências do Sistema
# Instala pacotes, atualiza o sistema e configura o Docker.

set -e

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# A variável $OS é exportada pelo script pai (install_universal.sh)

# Atualiza os pacotes do sistema
update_system_packages() {
    log "Atualizando pacotes do sistema para '$OS'..."
    case $OS in
        ubuntu|debian)
            sudo apt-get update && sudo apt-get upgrade -y
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            ;;
        centos)
            if command_exists dnf; then sudo dnf update -y; else sudo yum update -y; fi
            ;;
        *)
            warn "Gerenciador de pacotes não suportado para atualização automática."
            ;;
    esac
}

# Instala uma lista de pacotes de dependência
install_dependency_packages() {
    log "Instalando pacotes de dependência..."
    local packages_debian=(
        "curl" "git" "wget" "python3" "python3-pip" "python3-venv"
        "docker.io" "docker-compose-plugin" "openssh-server" "net-tools"
        "build-essential" "ca-certificates" "gnupg" "lsb-release" "apt-transport-https"
    )
    local packages_ubuntu=("${packages_debian[@]}" "software-properties-common")
    local packages_arch=(
        "curl" "git" "wget" "python" "python-pip" "python-virtualenv"
        "docker" "openssh" "net-tools" "base-devel" "which" "file" "grep" "sed" "awk"
    )
    local packages_centos=(
        "curl" "git" "wget" "python3" "python3-pip" "python3-virtualenv"
        "docker" "docker-compose" "openssh-server" "net-tools"
        "@development-tools" "which" "file" "grep" "sed" "awk"
    )

    case $OS in
        ubuntu) sudo apt-get install -y "${packages_ubuntu[@]}";;
        debian) sudo apt-get install -y "${packages_debian[@]}";;
        manjaro) sudo pacman -S --noconfirm "${packages_arch[@]}";;
        centos)
            if command_exists dnf; then sudo dnf install -y "${packages_centos[@]}"; else sudo yum install -y "${packages_centos[@]}"; fi
            ;;
        *) error "Distribuição '$OS' não suportada para instalação automática de pacotes."; return 1;;
    esac
}

# Configura o Docker pós-instalação
configure_docker() {
    if command_exists docker; then
        log "Configurando e iniciando serviço Docker..."
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker "$USER"
        success "Docker configurado. Pode ser necessário fazer logout e login para que a alteração de grupo tenha efeito."
    fi
}

# --- Função Principal ---
main() {
    section "Configurando Dependências do Sistema"
    update_system_packages
    install_dependency_packages
    configure_docker
    success "Setup de dependências do sistema concluído."
}

main