#!/data/data/com.termux/files/usr/bin/bash
# Script para configurar autenticação GitHub no Termux
# Suporte para SSH e Token de Acesso Pessoal

set -euo pipefail

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções auxiliares ---
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# --- Verificar Termux ---
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

# --- Configurar SSH para GitHub ---
setup_ssh_github() {
    log "Configurando SSH para GitHub..."

    # Criar diretório .ssh se não existir
    mkdir -p "$HOME/.ssh"

    # Gerar chave SSH se não existir
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH..."
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "$(whoami)@termux"
    fi

    # Adicionar GitHub ao known_hosts
    if [ ! -f "$HOME/.ssh/known_hosts" ] || ! grep -q "github.com" "$HOME/.ssh/known_hosts"; then
        log "Adicionando GitHub aos hosts conhecidos..."
        ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
    fi

    # Configurar SSH config para GitHub
    if [ ! -f "$HOME/.ssh/config" ] || ! grep -q "Host github.com" "$HOME/.ssh/config"; then
        log "Configurando SSH config..."
        cat >> "$HOME/.ssh/config" << EOF

# GitHub SSH config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
EOF
    fi

    success "SSH configurado para GitHub"
}

# --- Configurar Token de Acesso Pessoal ---
setup_token_auth() {
    log "Configurando Token de Acesso Pessoal..."

    echo
    echo "🔑 CONFIGURAÇÃO DE TOKEN GITHUB"
    echo "================================"
    echo
    echo "Para usar token de acesso pessoal:"
    echo "1. Vá para: https://github.com/settings/tokens"
    echo "2. Clique em 'Generate new token (classic)'"
    echo "3. Selecione escopos: repo, workflow"
    echo "4. Copie o token gerado"
    echo
    read -p "Digite seu token GitHub (ou pressione Enter para pular): " GITHUB_TOKEN

    if [ -n "$GITHUB_TOKEN" ]; then
        # Salvar token em arquivo seguro
        echo "export GITHUB_TOKEN='$GITHUB_TOKEN'" >> "$HOME/.bashrc"
        echo "export GITHUB_TOKEN='$GITHUB_TOKEN'" >> "$HOME/.bash_profile"

        # Testar token
        log "Testando token..."
        if curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/user" | grep -q "login"; then
            success "Token configurado e testado com sucesso"
        else
            error "Token inválido ou sem permissões"
            return 1
        fi
    else
        warn "Token não configurado"
    fi
}

# --- Testar autenticação ---
test_auth() {
    log "Testando autenticação GitHub..."

    echo
    echo "🧪 TESTANDO AUTENTICAÇÃO"
    echo "========================"

    # Testar SSH
    echo "Testando SSH..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        success "SSH funcionando!"
    else
        warn "SSH não configurado ou chave não adicionada ao GitHub"
        echo "  Adicione esta chave ao GitHub: https://github.com/settings/keys"
        echo "  Chave pública:"
        echo "  $(cat $HOME/.ssh/id_rsa.pub)"
        echo
    fi

    # Testar Token
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo "Testando Token..."
        if curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/user" | grep -q "login"; then
            success "Token funcionando!"
        else
            warn "Token não funcionando"
        fi
    else
        warn "Token não configurado"
    fi
}

# --- Mostrar instruções finais ---
show_instructions() {
    echo
    echo "🎯 PRÓXIMOS PASSOS"
    echo "=================="
    echo
    echo "1. Se configurou SSH:"
    echo "   - Adicione a chave ao GitHub: https://github.com/settings/keys"
    echo "   - Chave: $(cat $HOME/.ssh/id_rsa.pub)"
    echo
    echo "2. Execute novamente a instalação:"
    echo "   ./setup_android_worker_simple.sh"
    echo
    echo "3. Ou use o script robusto:"
    echo "   ./setup_android_worker_robust.sh"
    echo
}

# --- Menu principal ---
show_menu() {
    echo
    echo "🔐 CONFIGURAÇÃO DE AUTENTICAÇÃO GITHUB"
    echo "======================================"
    echo
    echo "Escolha o método de autenticação:"
    echo "1. SSH (Recomendado - mais seguro)"
    echo "2. Token de Acesso Pessoal"
    echo "3. Ambos"
    echo "4. Apenas testar configuração atual"
    echo
    read -p "Opção (1-4): " choice

    case $choice in
        1)
            setup_ssh_github
            test_auth
            ;;
        2)
            setup_token_auth
            test_auth
            ;;
        3)
            setup_ssh_github
            setup_token_auth
            test_auth
            ;;
        4)
            test_auth
            ;;
        *)
            error "Opção inválida"
            exit 1
            ;;
    esac
}

# --- Função principal ---
main() {
    check_termux
    show_menu
    show_instructions

    echo "🎉 Configuração de autenticação concluída!"
    echo
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
