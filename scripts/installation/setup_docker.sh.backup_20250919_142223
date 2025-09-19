#!/bin/bash
# setup_docker.sh
# Instala o Docker Engine de forma segura e integrada ao projeto.

set -euo pipefail

# --- Carregar Funções Comuns ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# --- Funções ---

# Adiciona o usuário atual ao grupo 'docker' para evitar o uso de 'sudo'
add_user_to_docker_group() {
    if ! getent group docker >/dev/null; then
        info "Criando grupo 'docker'..."
        sudo groupadd docker
    fi

    if ! id -nG "$USER" | grep -qw "docker"; then
        info "Adicionando usuário '$USER' ao grupo 'docker'..."
        if sudo usermod -aG docker "$USER"; then
            success "Usuário adicionado ao grupo 'docker'."
            warn "Você precisa fazer logout e login novamente para que a alteração tenha efeito."
        else
            error "Falha ao adicionar usuário ao grupo 'docker'."
        fi
    else
        info "Usuário '$USER' já pertence ao grupo 'docker'."
    fi
}

# Instala o Docker em sistemas baseados em Debian/Ubuntu
install_docker_debian() {
    subsection "Instalando Docker para Debian/Ubuntu"

    progress "Atualizando lista de pacotes..."
    sudo apt-get update -qq >/dev/null

    progress "Instalando dependências necessárias..."
    sudo apt-get install -y -qq ca-certificates curl >/dev/null

    progress "Adicionando a chave GPG oficial do Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    else
        error "Falha ao baixar a chave GPG do Docker."
        return 1
    fi

    progress "Configurando o repositório do Docker..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    progress "Atualizando lista de pacotes com o novo repositório..."
    sudo apt-get update -qq >/dev/null

    progress "Instalando Docker Engine, CLI, containerd e plugins..."
    if sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null; then
        success "Docker instalado com sucesso."
    else
        error "Falha ao instalar os pacotes do Docker."
        return 1
    fi

    add_user_to_docker_group
}

# Função principal
main() {
    section "🐳 Configuração do Docker"

    if command_exists docker; then
        success "Docker já está instalado."
        info "Versão: $(docker --version)"
        add_user_to_docker_group
        return 0
    fi

    warn "Docker não encontrado."
    if ! confirm "Deseja instalar o Docker Engine agora?"; then
        warn "Instalação do Docker pulada."
        return 1
    fi

    local os_distro
    os_distro=$(detect_linux_distro)

    case "$os_distro" in
        ubuntu|debian)
            install_docker_debian
            ;;
        *)
            error "A instalação automática do Docker para a distribuição '$os_distro' não é suportada."
            info "Por favor, instale o Docker manualmente seguindo a documentação oficial:"
            info "https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac

    if command_exists docker; then
        success "Verificação final: Docker instalado e pronto para uso."
    else
        error "A instalação do Docker parece ter falhado."
    fi
}

main "$@"