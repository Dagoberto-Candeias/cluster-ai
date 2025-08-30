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

# Verifica se o usuário tem privilégios sudo
check_sudo_privileges() {
    if ! sudo -n true 2>/dev/null; then
        warn "Privilégios sudo não disponíveis. Alguns pacotes podem não ser instalados."
        return 1
    fi
    return 0
}

# Instala pacotes individualmente com tratamento de erros
install_package_with_fallback() {
    local package="$1"
    local fallback_packages=("${@:2}")
    
    log "Instalando pacote: $package"
    
    case $OS in
        ubuntu|debian)
            if sudo apt-get install -y "$package" 2>/dev/null; then
                success "Pacote $package instalado com sucesso"
                return 0
            else
                warn "Falha ao instalar $package, tentando fallbacks..."
                for fallback in "${fallback_packages[@]}"; do
                    if sudo apt-get install -y "$fallback" 2>/dev/null; then
                        success "Pacote fallback $fallback instalado com sucesso"
                        return 0
                    fi
                done
                error "Não foi possível instalar $package ou fallbacks"
                return 1
            fi
            ;;
        manjaro)
            if sudo pacman -S --noconfirm "$package" 2>/dev/null; then
                success "Pacote $package instalado com sucesso"
                return 0
            else
                warn "Falha ao instalar $package"
                return 1
            fi
            ;;
        centos)
            if command_exists dnf; then
                if sudo dnf install -y "$package" 2>/dev/null; then
                    success "Pacote $package instalado com sucesso"
                    return 0
                else
                    warn "Falha ao instalar $package"
                    return 1
                fi
            else
                if sudo yum install -y "$package" 2>/dev/null; then
                    success "Pacote $package instalado com sucesso"
                    return 0
                else
                    warn "Falha ao instalar $package"
                    return 1
                fi
            fi
            ;;
        *) 
            warn "Distribuição '$OS' não suportada para instalação de $package"
            return 1
            ;;
    esac
}

# Instala uma lista de pacotes de dependência com tratamento de erros
install_dependency_packages() {
    log "Instalando pacotes de dependência..."
    
    # Verificar privilégios sudo antes de prosseguir
    if ! check_sudo_privileges; then
        warn "Instalação de pacotes do sistema será limitada devido à falta de privilégios sudo"
        return 0
    fi

    # Listas de pacotes com fallbacks
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

    local failed_packages=()
    
    case $OS in
        ubuntu)
            for package in "${packages_ubuntu[@]}"; do
                if ! install_package_with_fallback "$package"; then
                    failed_packages+=("$package")
                fi
            done
            ;;
        debian)
            for package in "${packages_debian[@]}"; do
                if ! install_package_with_fallback "$package"; then
                    failed_packages+=("$package")
                fi
            done
            ;;
        manjaro)
            for package in "${packages_arch[@]}"; do
                if ! install_package_with_fallback "$package"; then
                    failed_packages+=("$package")
                fi
            done
            ;;
        centos)
            for package in "${packages_centos[@]}"; do
                if ! install_package_with_fallback "$package"; then
                    failed_packages+=("$package")
                fi
            done
            ;;
        *) 
            error "Distribuição '$OS' não suportada para instalação automática de pacotes."
            return 1
            ;;
    esac

    # Relatório de pacotes que falharam
    if [ ${#failed_packages[@]} -gt 0 ]; then
        warn "Os seguintes pacotes falharam na instalação: ${failed_packages[*]}"
        info "Algumas funcionalidades podem estar limitadas"
    else
        success "Todos os pacotes de dependência foram instalados com sucesso"
    fi
    
    return 0
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