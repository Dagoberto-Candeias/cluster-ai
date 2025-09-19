#!/bin/bash
# =============================================================================
# Script auxiliar para configurar SSH key no GitHub para Android Worker
# =============================================================================
# Script auxiliar para configurar SSH key no GitHub para Android Worker
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: setup_github_ssh.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# Script auxiliar para configurar SSH key no GitHub para Android Worker

set -euo pipefail

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções auxiliares ---
log() { echo -e "${BLUE}[SSH-SETUP]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# --- Verificar se está no Termux ---
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
}

# --- Verificar chave SSH ---
check_ssh_key() {
    if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        log "Gerando chave SSH..."
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "android-worker-$(date +%s)" >/dev/null 2>&1
        success "Chave SSH gerada"
    else
        success "Chave SSH já existe"
    fi
}

# --- Testar conexão SSH ---
test_ssh_connection() {
    log "Testando conexão SSH com GitHub..."

    # Adicionar GitHub ao known_hosts se necessário
    ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true

    if ssh -T git@github.com -o ConnectTimeout=10 2>&1 | grep -q "successfully authenticated"; then
        success "Conexão SSH com GitHub OK"
        return 0
    else
        warn "Conexão SSH falhou - chave pode não estar configurada no GitHub"
        return 1
    fi
}

# --- Mostrar instruções ---
show_instructions() {
    echo
    echo "=================================================="
    echo "🔑 CONFIGURAÇÃO SSH PARA GITHUB"
    echo "=================================================="
    echo
    echo "📋 PASSOS PARA CONFIGURAR:"
    echo
    echo "1️⃣ COPIE ESTA CHAVE SSH:"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "2️⃣ NO SEU NAVEGADOR (computador ou celular):"
    echo "   • Vá para: https://github.com/settings/keys"
    echo "   • Clique em: 'New SSH key'"
    echo "   • Título: 'Android Worker $(date +%d/%m/%Y)'"
    echo "   • Cole a chave acima no campo 'Key'"
    echo "   • Clique em: 'Add SSH key'"
    echo
    echo "3️⃣ APÓS CONFIGURAR, DIGITE 'test' PARA TESTAR:"
    echo "   test"
    echo
    echo "4️⃣ OU DIGITE 'continue' PARA PROSSEGUIR:"
    echo "   continue"
    echo
}

# --- Menu interativo ---
interactive_menu() {
    while true; do
        echo
        echo "🔧 OPÇÕES:"
        echo "  [1] Mostrar chave SSH novamente"
        echo "  [2] Testar conexão SSH"
        echo "  [3] Continuar com a instalação"
        echo "  [4] Sair"
        echo
        read -p "Escolha uma opção (1-4): " choice

        case $choice in
            1)
                echo
                echo "🔑 SUA CHAVE SSH PÚBLICA:"
                echo "--------------------------------------------------"
                cat "$HOME/.ssh/id_rsa.pub"
                echo "--------------------------------------------------"
                ;;
            2)
                test_ssh_connection
                ;;
            3)
                success "Continuando com a instalação..."
                return 0
                ;;
            4)
                log "Saindo..."
                exit 0
                ;;
            *)
                warn "Opção inválida. Tente novamente."
                ;;
        esac
    done
}

# --- Função principal ---
main() {
    echo
    echo "🔐 ASSISTENTE DE CONFIGURAÇÃO SSH - CLUSTER AI"
    echo "=============================================="
    echo

    check_termux
    check_ssh_key

    if test_ssh_connection; then
        success "SSH já está configurado! Pode continuar."
        exit 0
    fi

    show_instructions

    # Aguardar confirmação do usuário
    while true; do
        read -p "Digite 'test' para testar ou 'continue' para prosseguir: " action
        case $action in
            test)
                if test_ssh_connection; then
                    success "Conexão SSH funcionando! 🎉"
                    break
                else
                    warn "Ainda não está funcionando. Configure a chave no GitHub primeiro."
                    show_instructions
                fi
                ;;
            continue)
                warn "Continuando sem testar... pode falhar se SSH não estiver configurado."
                break
                ;;
            *)
                warn "Digite 'test' ou 'continue'"
                ;;
        esac
    done

    success "Pronto para continuar com a instalação!"
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
