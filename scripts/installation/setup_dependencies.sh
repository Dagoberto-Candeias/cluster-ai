#!/bin/bash
# Script de Setup para Dependências do Sistema
# Instala pacotes, atualiza o sistema e configura o Docker.

set -euo pipefail

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Carregar utilitários de progresso
PROGRESS_UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/progress_utils.sh"
if [ ! -f "$PROGRESS_UTILS_PATH" ]; then
    echo "ERRO: Utilitários de progresso não encontrados em $PROGRESS_UTILS_PATH" >&2
    exit 1
fi
source "$PROGRESS_UTILS_PATH"

# Inicializar sistema de progresso
init_progress_system

# A variável $OS é exportada pelo script pai (install_universal.sh)

# Atualiza os pacotes do sistema com retry e progresso
update_system_packages() {
    subsection "Atualizando Pacotes do Sistema"

    case $OS in
        ubuntu|debian)
            log "Atualizando sistema Ubuntu/Debian..."

            # Executar atualização com retry e progresso
            if run_long_command "sudo apt-get update" "Atualizando lista de pacotes" 120; then
                success "Lista de pacotes atualizada"
            else
                warn "Falha ao atualizar lista de pacotes"
                return 1
            fi

            if run_long_command "sudo apt-get upgrade -y" "Atualizando pacotes instalados" 600; then
                success "Pacotes do sistema atualizados"
            else
                warn "Falha ao atualizar pacotes do sistema"
                return 1
            fi
            ;;
        manjaro)
            log "Atualizando sistema Manjaro..."

            if run_long_command "sudo pacman -Syu --noconfirm" "Atualizando sistema Manjaro" 600; then
                success "Sistema Manjaro atualizado"
            else
                warn "Falha ao atualizar sistema Manjaro"
                return 1
            fi
            ;;
        centos)
            log "Atualizando sistema CentOS..."

            if command_exists dnf; then
                if run_long_command "sudo dnf update -y" "Atualizando sistema CentOS (DNF)" 600; then
                    success "Sistema CentOS atualizado via DNF"
                else
                    warn "Falha ao atualizar sistema CentOS via DNF"
                    return 1
                fi
            else
                if run_long_command "sudo yum update -y" "Atualizando sistema CentOS (YUM)" 600; then
                    success "Sistema CentOS atualizado via YUM"
                else
                    warn "Falha ao atualizar sistema CentOS via YUM"
                    return 1
                fi
            fi
            ;;
        *)
            warn "Gerenciador de pacotes não suportado para atualização automática."
            return 1
            ;;
    esac

    success "Atualização do sistema concluída"
    return 0
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

# Instala uma lista de pacotes de dependência com tratamento de erros e progresso
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

    local packages=()
    local failed_packages=()

    # Selecionar lista de pacotes baseada na distribuição
    case $OS in
        ubuntu)
            packages=("${packages_ubuntu[@]}")
            ;;
        debian)
            packages=("${packages_debian[@]}")
            ;;
        manjaro)
            packages=("${packages_arch[@]}")
            ;;
        centos)
            packages=("${packages_centos[@]}")
            ;;
        *)
            error "Distribuição '$OS' não suportada para instalação automática de pacotes."
            return 1
            ;;
    esac

    local total=${#packages[@]}
    local current=0

    subsection "Instalando Pacotes do Sistema"

    for package in "${packages[@]}"; do
        ((current++))
        show_progress_bar "$current" "$total" 40 "Instalando pacotes"

        # Tentar instalar com retry
        if ! retry_command 2 1 "install_package_with_fallback '$package'" "instalação de $package"; then
            failed_packages+=("$package")
        fi
    done

    finish_progress_bar

    # Relatório de pacotes que falharam
    if [ ${#failed_packages[@]} -gt 0 ]; then
        warn "Os seguintes pacotes falharam na instalação: ${failed_packages[*]}"
        info "Algumas funcionalidades podem estar limitadas"
        return 1
    else
        success "Todos os pacotes de dependência foram instalados com sucesso"
        return 0
    fi
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