#!/bin/bash
# Instalação Otimizada do VSCode - Apenas 25 extensões essenciais

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[VSCODE-OPTIMIZED]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[VSCODE-WARN]${NC} $1"
}

error() {
    echo -e "${RED}[VSCODE-ERROR]${NC} $1"
    exit 1
}

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    error "Este script requer privilégios sudo"
fi

echo -e "${BLUE}=== INSTALAÇÃO OTIMIZADA DO VSCODE ===${NC}"

# Lista das 25 extensões essenciais otimizadas
EXTENSOES_ESSENCIAIS=(
    # Python e IA (6 extensões)
    "ms-python.python"
    "ms-toolsai.jupyter"
    "ms-python.vscode-pylance"
    "ms-python.pylint"
    "ms-python.debugpy"
    "donjayamanne.python-environment-manager"
    
    # Git e Versionamento (3 extensões)
    "eamodio.gitlens"
    "github.vscode-pull-request-github"
    "github.copilot"
    
    # Docker e Containers (2 extensões)
    "ms-azuretools.vscode-docker"
    "ms-vscode-remote.remote-containers"
    
    # Web Development (3 extensões)
    "esbenp.prettier-vscode"
    "bradlc.vscode-tailwindcss"
    "formulahendry.auto-close-tag"
    
    # Markdown e Documentação (2 extensões)
    "yzhang.markdown-all-in-one"
    "bierner.markdown-preview-github-styles"
    
    # Utilitários Essenciais (6 extensões)
    "njpwerner.autodocstring"
    "aaron-bond.better-comments"
    "streetsidesoftware.code-spell-checker"
    "streetsidesoftware.code-spell-checker-portuguese-brazilian"
    "editorconfig.editorconfig"
    "usernamehw.errorlens"
    
    # Temas (3 extensões)
    "dracula-theme.theme-dracula"
    "pkief.material-icon-theme"
    "ms-vscode.vscode-json"
)

# Função para instalar VSCode
install_vscode() {
    log "Instalando Visual Studio Code..."
    
    # Detectar distribuição
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        error "Não foi possível detectar o sistema operacional"
    fi
    
    case $OS in
        ubuntu|debian)
            # Instalar via pacote Microsoft
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
            apt update
            apt install -y code
            ;;
        arch|manjaro)
            # Instalar via AUR (usando yay se disponível)
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm visual-studio-code-bin
            else
                pacman -S --noconfirm code
            fi
            ;;
        fedora|centos|rhel)
            # Instalar via RPM
            rpm --import https://packages.microsoft.com/keys/microsoft.asc
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo
            dnf install -y code
            ;;
        *)
            warn "Distribuição não suportada. Tentando instalação genérica..."
            # Tentar instalar via snap se disponível
            if command -v snap >/dev/null 2>&1; then
                snap install code --classic
            else
                error "Não foi possível instalar o VSCode nesta distribuição"
            fi
            ;;
    esac
    
    log "VSCode instalado com sucesso"
}

# Função para instalar extensões
install_extensoes() {
    log "Instalando extensões otimizadas..."
    
    local instaladas=0
    local total=${#EXTENSOES_ESSENCIAIS[@]}
    
    for ext in "${EXTENSOES_ESSENCIAIS[@]}"; do
        if code --install-extension "$ext" --force 2>/dev/null; then
            log "✅ $ext instalada"
            ((instaladas++))
        else
            warn "⚠️  Falha ao instalar: $ext"
        fi
    done
    
    log "Extensões instaladas: $instaladas/$total"
}

# Função para configurar settings
configure_settings() {
    log "Configurando settings otimizados..."
    
    local SETTINGS_FILE="$HOME/.config/Code/User/settings.json"
    local SETTINGS_DIR=$(dirname "$SETTINGS_FILE")
    
    # Criar diretório se não existir
    mkdir -p "$SETTINGS_DIR"
    
    # Configurações otimizadas para performance
    cat > "$SETTINGS_FILE" << 'EOF'
{
    "workbench.colorTheme": "Dracula",
    "workbench.iconTheme": "material-icon-theme",
    "editor.fontSize": 14,
    "editor.fontFamily": "'Fira Code', 'Monospace', 'Droid Sans Mono', 'monospace'",
    "editor.fontLigatures": true,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "python.languageServer": "Pylance",
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.autoImportCompletions": true,
    "jupyter.notebookFileRoot": "${workspaceFolder}",
    "files.autoSave": "afterDelay",
    "explorer.confirmDelete": false,
    "git.confirmSync": false,
    "git.autofetch": true,
    "terminal.integrated.fontSize": 13,
    "emmet.triggerExpansionOnTab": true,
    "[python]": {
        "editor.defaultFormatter": "ms-python.python"
    },
    "[json]": {
        "editor.defaultFormatter": "vscode.json-language-features"
    },
    "[markdown]": {
        "editor.defaultFormatter": "yzhang.markdown-all-in-one"
    }
}
EOF
    
    log "Settings configurados com sucesso"
}

# Função principal
main() {
    # Instalar VSCode
    if ! command -v code >/dev/null 2>&1; then
        install_vscode
    else
        log "VSCode já está instalado"
    fi
    
    # Instalar extensões
    install_extensoes
    
    # Configurar settings
    configure_settings
    
    # Mensagem final
    echo -e "${GREEN}🎉 VSCode otimizado instalado com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}📋 CONFIGURAÇÃO:${NC}"
    echo "- 25 extensões essenciais instaladas"
    echo "- Tema Dracula + Material Icons"
    echo "- Configurações otimizadas para Python/IA"
    echo "- Performance melhorada"
    echo ""
    echo -e "${YELLOW}💡 DICA:${NC} Use 'code .' para abrir o VSCode no diretório atual"
}

# Executar
main "$@"
