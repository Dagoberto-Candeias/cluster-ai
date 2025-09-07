#!/data/data/com.termux/files/usr/bin/bash
# Script Robusto para configurar Worker Android - Cluster AI
# Versão melhorada com timeout, progresso e tratamento de erros

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
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# --- Verificações iniciais ---
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
    fi
    success "Termux detectado"
}

check_connectivity() {
    log "Verificando conectividade com internet..."
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        success "Conectividade OK"
    else
        warn "Sem conectividade com internet"
        warn "Verifique sua conexão Wi-Fi e tente novamente"
        exit 1
    fi
}

# --- Função com timeout seguro ---
run_with_timeout() {
    local timeout_duration="$1"
    local command="$2"
    local description="$3"

    log "$description..."

    if timeout "$timeout_duration" bash -c "$command" 2>&1; then
        success "$description concluída"
        return 0
    else
        warn "Timeout em: $description"
        return 1
    fi
}

# --- Instalação de dependências ---
install_deps() {
    log "=== FASE 1: ATUALIZAÇÃO DE PACOTES ==="
    log "Isso pode levar alguns minutos na primeira vez..."

    # Atualizar lista de pacotes
    if ! run_with_timeout 180 "pkg update -y" "Atualizando lista de pacotes"; then
        warn "Continuando sem atualização completa..."
    fi

    # Atualizar pacotes instalados
    if ! run_with_timeout 300 "pkg upgrade -y" "Atualizando pacotes instalados"; then
        warn "Continuando com pacotes desatualizados..."
    fi

    log "=== FASE 2: INSTALANDO DEPENDÊNCIAS ==="

    # Instalar dependências essenciais
    if run_with_timeout 300 "pkg install -y openssh python git ncurses-utils curl" "Instalando dependências"; then
        success "Dependências instaladas com sucesso"
    else
        error "Falha ao instalar dependências essenciais"
    fi
}

# --- Configuração SSH ---
setup_ssh() {
    log "=== FASE 3: CONFIGURANDO SSH ==="

    # Criar diretório SSH
    mkdir -p "$HOME/.ssh"

    # Gerar chave SSH se não existir
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        run_with_timeout 30 "ssh-keygen -t rsa -b 2048 -N '' -f '$HOME/.ssh/id_rsa' -C 'android-worker-$(date +%s)'" "Gerando chave SSH"
    else
        success "Chave SSH já existe"
    fi

    # Iniciar SSH daemon
    if run_with_timeout 10 "sshd" "Iniciando servidor SSH"; then
        success "Servidor SSH iniciado na porta 8022"
    else
        warn "Servidor SSH pode já estar rodando"
    fi
}

# --- Clonar projeto ---
clone_project() {
    log "=== FASE 4: BAIXANDO PROJETO CLUSTER AI ==="

    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar SSH primeiro (para repositórios privados)
        log "Tentando clonar via SSH..."
        if run_with_timeout 120 "git clone git@github.com:Dagoberto-Candeias/cluster-ai.git '$HOME/Projetos/cluster-ai'" "Clonando via SSH"; then
            success "Projeto clonado via SSH"
        else
            warn "SSH falhou, tentando via HTTPS..."
            # Fallback para HTTPS
            if run_with_timeout 120 "git clone https://github.com/Dagoberto-Candeias/cluster-ai.git '$HOME/Projetos/cluster-ai'" "Clonando via HTTPS"; then
                success "Projeto clonado via HTTPS"
            else
                error "Falha ao clonar repositório"
            fi
        fi
    else
        log "Projeto já existe, verificando atualizações..."
        cd "$HOME/Projetos/cluster-ai"
        if run_with_timeout 60 "git pull" "Atualizando projeto"; then
            success "Projeto atualizado"
        else
            warn "Falha ao atualizar, continuando com versão existente"
        fi
    fi
}

# --- Exibir informações de conexão ---
show_connection_info() {
    echo
    echo "=================================================="
    echo "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "=================================================="
    echo
    echo "📱 Seu dispositivo Android está pronto para ser worker!"
    echo
    echo "🔑 CHAVE SSH PÚBLICA (copie tudo abaixo):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "🌐 INFORMAÇÕES DE CONEXÃO:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo 'Verifique Wi-Fi')"
    echo "   Porta SSH: 8022"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Copie a chave SSH acima"
    echo "2. No seu servidor principal, execute: ./manager.sh"
    echo "3. Escolha: Gerenciar Workers Remotos (SSH)"
    echo "4. Configure um worker Android (Termux)"
    echo "5. Cole a chave SSH quando solicitado"
    echo "6. Digite o IP do seu Android e porta 8022"
    echo
    echo "🧪 Para testar: bash ~/Projetos/cluster-ai/scripts/android/test_android_worker.sh"
    echo
    echo "💡 DICAS:"
    echo "• Mantenha o Termux aberto em background"
    echo "• Use Wi-Fi estável na mesma rede"
    echo "• Monitore a bateria (>20%)"
    echo
}

# --- Função principal ---
main() {
    echo
    echo "🤖 CLUSTER AI - CONFIGURADOR ROBUSTO DE WORKER ANDROID"
    echo "======================================================"
    echo
    echo "Versão: Melhorada com timeout e tratamento de erros"
    echo "Tempo estimado: 3-8 minutos"
    echo

    check_termux
    check_connectivity

    # Executar fases
    install_deps
    setup_ssh
    clone_project
    show_connection_info

    echo "🎊 Pronto! Seu Android agora é um worker do Cluster AI!"
    echo
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
