#!/bin/bash
# Script de Setup para a IDE VSCode
# Instala e configura o Visual Studio Code com extensões essenciais

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

install_vscode() {
    if command_exists code; then
        success "VSCode já está instalado."
        return 0
    fi

    log "Instalando Visual Studio Code..."
    
    local OS=$(detect_os)
    
    case $OS in
        ubuntu|debian)
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt update
            sudo apt install -y code
            ;;
        manjaro|arch)
            sudo pacman -S --noconfirm code
            ;;
        centos|fedora|rhel)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            if command_exists dnf; then
                sudo dnf install -y code
            else
                sudo yum install -y code
            fi
            ;;
        *)
            warn "Distribuição '$OS' não suportada para instalação automática do VSCode"
            return 1
            ;;
    esac

    if command_exists code; then
        success "VSCode instalado com sucesso."
        log "Para iniciar o VSCode, execute: code ."
    else
        error "Falha na instalação do VSCode."
        warn "Tente instalar manualmente seguindo as instruções em:"
        warn "https://code.visualstudio.com/docs/setup/linux"
        return 1
    fi
}

install_extensions() {
    log "Instalando extensões essenciais do VSCode..."
    
    local extensions=(
        "ms-python.python"
        "ms-toolsai.jupyter"
        "ms-python.vscode-pylance"
        "ms-python.debugpy"
        "ms-python.pylint"
        "ms-python.autopep8"
        "kevinrose.vsc-python-indent"
        "github.copilot"
        "github.copilot-chat"
        "eamodio.gitlens"
        "ms-azuretools.vscode-docker"
        "ms-vscode-remote.remote-containers"
        "streetsidesoftware.code-spell-checker"
        "streetsidesoftware.code-spell-checker-portuguese-brazilian"
        "usernamehw.errorlens"
        "aaron-bond.better-comments"
        "yzhang.markdown-all-in-one"
        "njpwerner.autodocstring"
        "dracula-theme.theme-dracula"
        "pkief.material-icon-theme"
    )
    
    local installed=0
    local failed=0
    
    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            log "Extensão já instalada: $ext"
        else
            log "Instalando extensão: $ext"
            if code --install-extension "$ext" --force; then
                ((installed++))
            else
                warn "Falha ao instalar extensão: $ext"
                ((failed++))
            fi
        fi
    done
    
    success "Extensões instaladas: $installed novas, $failed falhas"
}

configure_settings() {
    log "Configurando settings do VSCode..."
    
    local settings_dir="$HOME/.config/Code/User"
    local settings_file="$settings_dir/settings.json"
    
    mkdir -p "$settings_dir"
    
    cat > "$settings_file" << 'EOL'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "'Fira Code', 'Monospace', 'Droid Sans Mono'",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.wordWrap": "on",
    "python.defaultInterpreterPath": "~/cluster_env/bin/python",
    "python.analysis.autoImportCompletions": true,
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.autoSearchPaths": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "autopep8",
    "python.formatting.autopep8Args": ["--max-line-length", "120"],
    "jupyter.interactiveWindow.creationMode": "perFile",
    "git.confirmSync": false,
    "git.autofetch": true,
    "terminal.integrated.fontSize": 13,
    "workbench.iconTheme": "material-icon-theme",
    "workbench.colorTheme": "Dracula",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true
    }
}
EOL
    
    success "Configurações do VSCode salvas em: $settings_file"
}

main() {
    section "Configurando Visual Studio Code"
    
    # Executar verificação pré-instalação
    log "Executando verificação pré-instalação..."
    if ! bash "$PRE_INSTALL_CHECK_PATH"; then
        warn "Alguns requisitos não foram atendidos, mas prosseguindo com a instalação..."
    fi
    
    install_vscode
    install_extensions
    configure_settings
    
    success "✅ Configuração do VSCode concluída com sucesso!"
    log "Para iniciar o VSCode, execute: code ."
    log "Para abrir o projeto Cluster AI: code ~/Projetos/cluster-ai"
}

main
