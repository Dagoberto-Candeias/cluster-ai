#!/bin/bash
# Script otimizado para instalação do VSCode com extensões essenciais
# Focado em desenvolvimento Python, IA, Dask e qualidade de código

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

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    error "Não foi possível detectar o sistema operacional."
    exit 1
fi

# Lista de extensões essenciais (25 no total)
EXTENSOES_ESSENCIAIS=(
    # Python Core (6 extensões)
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.debugpy"
    "ms-python.pylint"
    "ms-python.autopep8"
    "kevinrose.vsc-python-indent"
    
    # Jupyter (1 extensão)
    "ms-toolsai.jupyter"
    
    # IA Assistants (4 extensões)
    "github.copilot"
    "github.copilot-chat"
    "blackboxapp.blackbox"
    "sourcegraph.cody-ai"
    
    # Git (2 extensões)
    "eamodio.gitlens"
    "github.vscode-pull-request-github"
    
    # Docker (2 extensões)
    "ms-azuretools.vscode-docker"
    "ms-vscode-remote.remote-containers"
    
    # Code Quality (4 extensões)
    "streetsidesoftware.code-spell-checker"
    "streetsidesoftware.code-spell-checker-portuguese-brazilian"
    "usernamehw.errorlens"
    "aaron-bond.better-comments"
    
    # Documentation (3 extensões)
    "yzhang.markdown-all-in-one"
    "bierner.markdown-preview-github-styles"
    "njpwerner.autodocstring"
    
    # UI/Themes (2 extensões)
    "dracula-theme.theme-dracula"
    "pkief.material-icon-theme"
    
    # Live Share (1 extensão - opcional mas muito útil)
    "ms-vsliveshare.vsliveshare"
)

install_vscode() {
    log "Instalando Visual Studio Code..."
    
    if command_exists code; then
        log "VSCode já está instalado."
        return 0
    fi
    
    case $OS in
        ubuntu|debian)
            # Baixar e adicionar chave GPG
            wget --timeout=30 --tries=2 --timeout=30 --tries=2 -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            
            # Adicionar repositório
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            
            # Atualizar e instalar
            sudo apt update
            sudo apt install -y --no-install-recommends --no-install-recommends code
            
            # Limpar arquivo temporário
            rm -f packages.microsoft.gpg
            ;;
            
        manjaro|arch)
            sudo pacman -S --noconfirm code
            ;;
            
        centos|rhel|fedora)
            # Adicionar repositório RPM
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            
            # Instalar
            if command_exists dnf; then
                sudo dnf install -y --setopt=install_weak_deps=False --setopt=install_weak_deps=False code
            else
                sudo yum install -y code
            fi
            ;;
            
        *)
            warn "Distribuição não suportada automaticamente: $OS"
            warn "Por favor, instale o VSCode manualmente e execute este script novamente."
            return 1
            ;;
    esac
    
    if command_exists code; then
        log "VSCode instalado com sucesso."
        return 0
    else
        error "Falha ao instalar VSCode."
        return 1
    fi
}

install_extensoes() {
    log "Instalando extensões essenciais do VSCode..."
    
    local total=${#EXTENSOES_ESSENCIAIS[@]}
    local instaladas=0
    local ja_instaladas=0
    
    for ext in "${EXTENSOES_ESSENCIAIS[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            echo "✅ Já instalada: $ext"
            ((ja_instaladas++))
        else
            echo "📦 Instalando: $ext"
            if code --install-extension "$ext" --force; then
                ((instaladas++))
            else
                warn "Falha ao instalar: $ext"
            fi
        fi
    done
    
    log "Extensões instaladas: $instaladas novas, $ja_instaladas já existentes"
    log "Total de extensões essenciais: $total"
}

configure_vscode_settings() {
    log "Configurando settings.json do VSCode..."
    
    local settings_dir="$HOME/.config/Code/User"
    local settings_file="$settings_dir/settings.json"
    
    # Criar diretório se não existir
    mkdir -p "$settings_dir"
    
    # Configurações padrão otimizadas para Python/IA
    cat > "$settings_file" << 'EOL'
{
    // Configurações gerais
    "editor.fontSize": 14,
    "editor.fontFamily": "'Fira Code', 'Monospace', 'Droid Sans Mono'",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.wordWrap": "on",
    
    // Python específico
    "python.defaultInterpreterPath": "~/cluster_env/bin/python",
    "python.analysis.autoImportCompletions": true,
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.autoSearchPaths": true,
    "python.analysis.diagnosticMode": "workspace",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "autopep8",
    "python.formatting.autopep8Args": ["--max-line-length", "120"],
    
    // Jupyter
    "jupyter.interactiveWindow.creationMode": "perFile",
    "jupyter.askForKernelRestart": false,
    
    // Git
    "git.confirmSync": false,
    "git.autofetch": true,
    "git.enableSmartCommit": true,
    
    // Terminal integrado
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.cursorBlinking": true,
    
    // Interface
    "workbench.iconTheme": "material-icon-theme",
    "workbench.colorTheme": "Dracula",
    "workbench.startupEditor": "none",
    "window.zoomLevel": 0,
    
    // Files
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/.mypy_cache": true,
        "**/.ruff_cache": true
    },
    
    // Extensões específicas
    "gitlens.hovers.currentLine.over": "line",
    "errorLens.enabled": true,
    "betterComments.highlightPlainText": true,
    
    // AI Assistants
    "cody.debug.enable": true,
    "cody.codebase.embeddings.enabled": true,
    
    // Performance
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.quickSuggestions": {
        "other": true,
        "comments": false,
        "strings": true
    }
}
EOL
    
    log "Configurações do VSCode salvas em: $settings_file"
}

install_fira_font() {
    log "Instalando fonte Fira Code (opcional)..."
    
    case $OS in
        ubuntu|debian)
            sudo apt install -y --no-install-recommends --no-install-recommends fonts-firacode
            ;;
        manjaro|arch)
            sudo pacman -S --noconfirm ttf-fira-code
            ;;
        centos|rhel|fedora)
            sudo dnf install -y --setopt=install_weak_deps=False --setopt=install_weak_deps=False fira-code-fonts || sudo yum install -y fira-code-fonts
            ;;
    esac
    
    log "Fonte Fira Code instalada (se disponível na distro)."
}

main() {
    echo -e "${BLUE}=== INSTALAÇÃO OTIMIZADA DO VS CODE ===${NC}"
    
    # Executar verificação pré-instalação
    log "Executando verificação pré-instalação..."
    PRE_INSTALL_CHECK_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pre_install_check.sh"
    if [ -f "$PRE_INSTALL_CHECK_PATH" ]; then
        if ! bash "$PRE_INSTALL_CHECK_PATH"; then
            warn "Alguns requisitos não foram atendidos, mas prosseguindo com a instalação..."
        fi
    else
        warn "Script de verificação pré-instalação não encontrado, prosseguindo sem verificação..."
    fi
    
    # Instalar VSCode
    if ! install_vscode; then
        error "Falha na instalação do VSCode. Abortando."
        exit 1
    fi
    
    # Instalar extensões
    install_extensoes
    
    # Configurar settings
    configure_vscode_settings
    
    # Instalar fonte opcional
    read -p "Deseja instalar a fonte Fira Code? (s/N): " install_font
    if [[ "$install_font" =~ ^[Ss]$ ]]; then
        install_fira_font
    fi
    
    echo -e "\n${GREEN}✅ CONFIGURAÇÃO DO VS CODE CONCLUÍDA!${NC}"
    echo -e "${CYAN}Resumo:${NC}"
    echo "- VSCode instalado/verificado"
    echo "- ${#EXTENSOES_ESSENCIAIS[@]} extensões essenciais configuradas"
    echo "- Settings otimizados para Python/IA"
    echo "- Pronto para desenvolvimento!"
    echo ""
    echo -e "${YELLOW}Para iniciar:${NC}"
    echo "  code .                          # Abrir diretório atual"
    echo "  code ~/Projetos/cluster-ai     # Abrir projeto Cluster AI"
    echo ""
    echo -e "${YELLOW}Extensões instaladas:${NC}"
    for ext in "${EXTENSOES_ESSENCIAIS[@]}"; do
        echo "  ✓ $ext"
    done
}

# Executar instalação
main
