#!/bin/bash
# Script de Setup para a IDE PyCharm
# Instala o PyCharm Community Edition no sistema.

# Carregar funções comuns para logging e cores
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Carregar script de verificação pré-instalação
PRE_INSTALL_CHECK_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../installation" && pwd)/pre_install_check.sh"
if [ ! -f "$PRE_INSTALL_CHECK_PATH" ]; then
    error "Script de verificação pré-instalação não encontrado em $PRE_INSTALL_CHECK_PATH"
    exit 1
fi

# Carregar script de verificação de gerenciadores de pacotes
PACKAGE_MANAGERS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/check_package_managers.sh"
if [ ! -f "$PACKAGE_MANAGERS_PATH" ]; then
    error "Script de verificação de gerenciadores não encontrado em $PACKAGE_MANAGERS_PATH"
    exit 1
fi

install_pycharm() {
    local pycharm_cmd="pycharm-community"

    # Check 1: Command exists in PATH
    if command_exists "$pycharm_cmd"; then
        success "PyCharm já está instalado e disponível no PATH."
        return 0
    fi

    # Check 2: Snap is installed but command not in PATH
    if command_exists snap && snap list 2>/dev/null | grep -q "pycharm-community"; then
        success "PyCharm (snap) já está instalado."
        warn "O comando '$pycharm_cmd' não foi encontrado no seu PATH."
        warn "Pode ser necessário reiniciar sua sessão (logout/login) ou adicionar '/snap/bin' ao seu PATH."
        warn "Exemplo: export PATH=\$PATH:/snap/bin"
        # Considera sucesso para o propósito do script, pois o software está no sistema.
        return 0
    fi

    log "Instalando PyCharm Community Edition..."

    local OS=$(detect_os)
    local install_success=false
    
    case $OS in
        ubuntu|debian)
            # Verificar e instalar snap se necessário
            source "$PACKAGE_MANAGERS_PATH"
            install_snap
            if sudo snap install pycharm-community --classic; then
                install_success=true
            fi
            ;;
        manjaro|arch)
            if command_exists pamac; then
                if sudo pamac install -y pycharm-community; then
                    install_success=true
                fi
            else
                if sudo pacman -S --noconfirm pycharm-community; then
                    install_success=true
                fi
            fi
            ;;
        centos|fedora|rhel)
            # Verificar e instalar snap se necessário
            source "$PACKAGE_MANAGERS_PATH"
            install_snap
            if sudo snap install pycharm-community --classic; then
                install_success=true
            fi
            ;;
        *)
            warn "Distribuição '$OS' não suportada para instalação do PyCharm."
            return 1
            ;;
    esac

    # Atualiza a tabela de hash de comandos para encontrar os recém-instalados
    hash -r 2>/dev/null

    if [ "$install_success" = true ]; then
        success "PyCharm instalado com sucesso."
        if ! command_exists "$pycharm_cmd"; then
            warn "Pode ser necessário reiniciar sua sessão (logout/login) para que o comando '$pycharm_cmd' fique disponível."
        fi
        log "Para iniciar o PyCharm, execute: $pycharm_cmd"
    else
        error "Falha na instalação do PyCharm."
        warn "Tente instalar manualmente:"
        warn "Ubuntu/Debian: sudo snap install pycharm-community --classic"
        warn "Manjaro/Arch: sudo pacman -S pycharm-community"
        warn "CentOS/Fedora: Instale snap primeiro, depois: sudo snap install pycharm-community --classic"
        return 1
    fi
}

create_pycharm_shortcut() {
    local shortcut_dir="$HOME/.local/share/applications"
    local shortcut_file="$shortcut_dir/cluster-ai-pycharm.desktop"
    local project_root_from_script="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    log "Criando atalho de menu para o PyCharm..."
    mkdir -p "$shortcut_dir"

    tee "$shortcut_file" > /dev/null << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=PyCharm (Cluster AI)
Comment=Abre o projeto Cluster AI no PyCharm Community
Exec=pycharm-community "$project_root_from_script"
Icon=pycharm-community
Terminal=false
Categories=Development;IDE;
EOL

    chmod +x "$shortcut_file"
    success "Atalho criado em: $shortcut_file"
}

main() {
    section "Configurando PyCharm IDE"
    
    # Executar verificação pré-instalação
    log "Executando verificação pré-instalação..."
    if ! bash "$PRE_INSTALL_CHECK_PATH"; then
        warn "Alguns requisitos não foram atendidos, mas prosseguindo com a instalação..."
    fi
    
    install_pycharm

    # Criar atalho no menu
    create_pycharm_shortcut
    
    # Verifica se o comando existe OU se o pacote snap está instalado como fallback
    if command_exists pycharm-community || (command_exists snap && snap list 2>/dev/null | grep -q "pycharm-community"); then
        success "✅ Configuração do PyCharm concluída com sucesso!"
    else
        error "❌ Falha na configuração do PyCharm."
        exit 1
    fi
}

main
