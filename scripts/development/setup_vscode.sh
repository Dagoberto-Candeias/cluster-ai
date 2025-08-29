#!/bin/bash
# Script de Setup do Visual Studio Code e Ferramentas de Desenvolvimento
# Instala o VSCode (se necessário) e as extensões listadas.

# Carregar funções comuns para logging e cores
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Função para instalar o VS Code usando o gerenciador de pacotes do sistema
install_vscode_package() {
    if command_exists code; then
        log "Visual Studio Code já está instalado."
        return 0
    fi

    log "Instalando VSCode via gerenciador de pacotes para a distro '$OS'..."
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y wget gpg
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/packages.microsoft.gpg > /dev/null
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y code
            ;;
        manjaro)
            sudo pacman -S --noconfirm code
            ;;
        centos)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
            if command_exists dnf; then
                sudo dnf install -y code
            else
                sudo yum install -y code
            fi
            ;;
        *)
            error "Instalação do VSCode não suportada para a distro '$OS'."
            return 1
            ;;
    esac
    log "VSCode instalado com sucesso."
}

# Função para instalar extensões a partir de uma lista
install_extensions() {
    local extensions_file="$(dirname "${BASH_SOURCE[0]}")/vscode_extensions.list"
    if [ ! -f "$extensions_file" ]; then
        warn "Arquivo de extensões '$extensions_file' não encontrado. Pulando instalação de extensões."
        return
    fi

    if ! command_exists code; then
        error "Comando 'code' não encontrado. Não é possível instalar extensões."
        return
    fi

    log "Instalando extensões do VSCode a partir de '$extensions_file'..."
    while IFS= read -r extension || [[ -n "$extension" ]]; do
        # Ignorar linhas vazias ou comentários
        if [[ -z "$extension" ]] || [[ "$extension" =~ ^# ]]; then
            continue
        fi
        log "Instalando: $extension"
        code --install-extension "$extension" --force
    done < "$extensions_file"

    success "Instalação de extensões concluída."
}

# --- Função Principal ---
main() {
    section "Configurando Ambiente de Desenvolvimento VSCode"
    install_vscode_package
    install_extensions
}

main