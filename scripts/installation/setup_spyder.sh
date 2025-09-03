#!/bin/bash
# Local: scripts/installation/setup_spyder.sh
# Autor: Nome: Dagoberto Candeias. email: betoallnet@gmail.com telefone/whatsapp: +5511951754945
# Script para instalação do Spyder IDE
# Otimizado para desenvolvimento científico e integração com Cluster AI

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        error "Não foi possível detectar a distribuição Linux"
        exit 1
    fi
}

# Instalar Spyder
install_spyder() {
    log "Instalando Spyder IDE..."

    # Verificar se já está instalado
    if command_exists spyder; then
        success "Spyder já está instalado"
        return 0
    fi

    case $DISTRO in
        ubuntu|debian|linuxmint)
            log "Instalando via apt (Ubuntu/Debian)..."
            sudo apt update
            sudo apt install -y spyder python3-spyder-kernels
            ;;

        manjaro|arch)
            log "Instalando via pacman (Arch/Manjaro)..."
            sudo pacman -S --noconfirm spyder python-spyder-kernels
            ;;

        centos|rhel|fedora)
            log "Instalando via dnf/yum (CentOS/RHEL/Fedora)..."
            if command_exists dnf; then
                sudo dnf install -y spyder python3-spyder-kernels
            else
                sudo yum install -y spyder python3-spyder-kernels
            fi
            ;;

        *)
            warn "Distribuição não suportada automaticamente: $DISTRO"
            warn "Tentando instalação via pip..."
            pip install spyder spyder-kernels
            ;;
    esac

    # Verificar instalação
    if command_exists spyder; then
        success "Spyder instalado com sucesso"
    else
        error "Falha na instalação do Spyder"
        return 1
    fi
}

# Instalar kernels Spyder
install_spyder_kernels() {
    log "Instalando kernels Spyder..."

    pip install spyder-kernels

    # Instalar kernel no ambiente virtual se existir
    if [ -n "$VIRTUAL_ENV" ]; then
        log "Instalando kernel no ambiente virtual..."
        python -m spyder_kernels.console --matplotlib="inline" --ip="127.0.0.1"
    fi

    success "Kernels Spyder instalados"
}

# Configurar Spyder para Cluster AI
configure_spyder() {
    log "Configurando Spyder para Cluster AI..."

    # Criar arquivo de configuração personalizado
    SPYDER_CONFIG_DIR="$HOME/.config/spyder-py3"
    mkdir -p "$SPYDER_CONFIG_DIR"

    # Configurações básicas
    cat > "$SPYDER_CONFIG_DIR/spyder.ini" << 'EOL'
[main]
version = 5.4.0

[appearance]
interface_theme = automatic
icon_theme = spyder 3
font/family = "DejaVu Sans Mono"
font/size = 10
font/italic = False
font/bold = False

[editor]
wrap = True
tab_mode = True
show_class_func_dropdown = True
show_indent_guides = True
show_blanks = True
remove_trailing_spaces = True
auto_save = True
auto_save_interval = 60

[ipython_console]
startup/run_lines = 
    import numpy as np
    import pandas as pd
    import matplotlib.pyplot as plt
    import torch
    print("Cluster AI environment loaded")

[variable_explorer]
show_callable_attributes = True
show_special_attributes = True

[plots]
mute_inline_plotting = False
show_plot_outline = True

[help]
rich_text = True
show_source = True
EOL

    success "Spyder configurado para Cluster AI"
}

# Criar atalho no menu
create_menu_shortcut() {
    log "Criando atalho no menu do sistema..."

    DESKTOP_FILE="$HOME/.local/share/applications/spyder-cluster-ai.desktop"

    cat > "$DESKTOP_FILE" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Spyder (Cluster AI)
Comment=Scientific Python Development Environment for Cluster AI
Exec=spyder %F
Icon=spyder
Terminal=false
StartupWMClass=Spyder
Categories=Development;IDE;Science;
Keywords=python;scientific;development;cluster;ai;
EOL

    chmod +x "$DESKTOP_FILE"

    success "Atalho criado: Spyder (Cluster AI)"
}

# Testar instalação
test_installation() {
    log "Testando instalação do Spyder..."

    # Verificar versão
    spyder --version

    success "Teste do Spyder concluído"
}

# Função principal
main() {
    echo -e "${BLUE}=== INSTALAÇÃO SPYDER - CLUSTER AI ===${NC}"

    # Detectar distribuição
    detect_distro

    # Instalar Spyder
    if ! install_spyder; then
        error "Falha na instalação do Spyder"
        exit 1
    fi

    # Instalar kernels
    install_spyder_kernels

    # Configurar para Cluster AI
    configure_spyder

    # Criar atalho
    create_menu_shortcut

    # Testar instalação
    test_installation

    echo -e "\n${GREEN}✅ SPYDER INSTALADO COM SUCESSO!${NC}"
    echo -e "${CYAN}Resumo:${NC}"
    echo "- Spyder IDE instalado"
    echo "- Kernels configurados"
    echo "- Configurado para Cluster AI"
    echo "- Atalho criado no menu"
    echo ""
    echo -e "${YELLOW}Para usar:${NC}"
    echo "  spyder                    # Abrir Spyder"
    echo "  spyder ~/Projetos/cluster-ai  # Abrir projeto"
    echo ""
    echo -e "${YELLOW}Atalho no menu:${NC} Spyder (Cluster AI)"
}

# Executar instalação
main
