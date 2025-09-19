#!/bin/bash
# Script para verificar e instalar gerenciadores de pacotes (flatpak, snap)
# necessário para instalação de algumas IDEs

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Função para verificar e instalar snap
install_snap() {
    if command_exists snap; then
        log "Snap já está instalado"
        return 0
    fi
    
    warn "Snap não está instalado. Instalando..."
    
    case $(detect_os) in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap
            ;;
        manjaro|arch)
            sudo pacman -S --noconfirm snapd
            sudo systemctl enable --now snapd.socket
            ;;
        centos|fedora|rhel)
            if command_exists dnf; then
                sudo dnf install -y snapd
            else
                sudo yum install -y snapd
            fi
            sudo systemctl enable --now snapd.socket
            ;;
        *)
            warn "Distribuição não suportada para instalação automática do snap"
            return 1
            ;;
    esac
    
    if command_exists snap; then
        success "Snap instalado com sucesso"
        return 0
    else
        error "Falha ao instalar snap"
        return 1
    fi
}

# Função para verificar e instalar flatpak
install_flatpak() {
    if command_exists flatpak; then
        log "Flatpak já está instalado"
        return 0
    fi
    
    warn "Flatpak não está instalado. Instalando..."
    
    case $(detect_os) in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y flatpak
            ;;
        manjaro|arch)
            sudo pacman -S --noconfirm flatpak
            ;;
        centos|fedora|rhel)
            if command_exists dnf; then
                sudo dnf install -y flatpak
            else
                sudo yum install -y flatpak
            fi
            ;;
        *)
            warn "Distribuição não suportada para instalação automática do flatpak"
            return 1
            ;;
    esac
    
    if command_exists flatpak; then
        success "Flatpak instalado com sucesso"
        return 0
    else
        error "Falha ao instalar flatpak"
        return 1
    fi
}

# Função principal
main() {
    section "Verificando gerenciadores de pacotes"
    
    local needs_snap=false
    local needs_flatpak=false
    
    # Verificar se snap é necessário (PyCharm em algumas distros)
    case $(detect_os) in
        ubuntu|debian|centos|fedora|rhel)
            needs_snap=true
            ;;
    esac
    
    # Verificar se flatpak é necessário (opcional para algumas IDEs)
    needs_flatpak=false  # Pode ser ativado no futuro se necessário
    
    # Instalar snap se necessário
    if [ "$needs_snap" = true ]; then
        install_snap
    fi
    
    # Instalar flatpak se necessário
    if [ "$needs_flatpak" = true ]; then
        install_flatpak
    fi
    
    success "Verificação de gerenciadores de pacotes concluída"
}

# Executar apenas se chamado diretamente
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
