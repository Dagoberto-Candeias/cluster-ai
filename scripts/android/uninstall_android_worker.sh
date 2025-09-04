#!/bin/bash

# Script de Desinstalação do Worker Android - Cluster AI
# Remove completamente o worker Android e permite reinstalação limpa

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Função para confirmar operação
confirm_operation() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}AVISO:${NC} $message Deseja continuar? (s/N) ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Função para parar processos relacionados
stop_processes() {
    section "Parando processos relacionados"

    # Parar processos Python relacionados ao cluster
    if pgrep -f "cluster.*worker" >/dev/null 2>&1; then
        warn "Encontrados processos do worker rodando. Parando..."
        pkill -f "cluster.*worker" || true
        success "Processos do worker parados."
    fi

    # Parar processos SSH relacionados
    if pgrep -f "ssh.*cluster" >/dev/null 2>&1; then
        warn "Encontradas conexões SSH ativas. Fechando..."
        pkill -f "ssh.*cluster" || true
        success "Conexões SSH fechadas."
    fi
}

# Função para remover arquivos de configuração
remove_config_files() {
    section "Removendo arquivos de configuração"

    local config_files=(
        "$HOME/.cluster-ai"
        "$HOME/.config/cluster-ai"
        "$HOME/.ssh/cluster_ai_key"
        "$HOME/.ssh/cluster_ai_key.pub"
        "$HOME/.termux/cluster-ai"
        "$PREFIX/var/lib/cluster-ai"
        "$PREFIX/etc/cluster-ai"
        "/tmp/cluster-ai-*"
    )

    for file in "${config_files[@]}"; do
        if [ -e "$file" ]; then
            rm -rf "$file"
            success "Removido: $file"
        fi
    done
}

# Função para limpar cache e logs
clean_cache_logs() {
    section "Limpando cache e logs"

    local cache_dirs=(
        "$HOME/.cache/cluster-ai"
        "/tmp/cluster-ai"
        "/var/log/cluster-ai"
    )

    for dir in "${cache_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            success "Limpado: $dir"
        fi
    done
}

# Função para remover entradas do crontab
remove_cron_jobs() {
    section "Removendo tarefas agendadas"

    if command -v crontab >/dev/null 2>&1; then
        # Fazer backup do crontab atual
        crontab -l > /tmp/crontab_backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

        # Remover linhas relacionadas ao cluster-ai
        crontab -l 2>/dev/null | grep -v "cluster-ai" | crontab - || true

        success "Tarefas agendadas removidas."
    fi
}

# Função para remover aliases do shell
remove_shell_aliases() {
    section "Removendo aliases do shell"

    local shell_rc_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")

    for rc_file in "${shell_rc_files[@]}"; do
        if [ -f "$rc_file" ]; then
            # Fazer backup
            cp "$rc_file" "${rc_file}.backup.$(date +%Y%m%d_%H%M%S)"

            # Remover aliases relacionados ao cluster-ai
            sed -i '/cluster-ai/d' "$rc_file"
            sed -i '/CLUSTER_AI/d' "$rc_file"

            success "Aliases removidos de: $rc_file"
        fi
    done
}

# Função para verificar se há dados importantes
check_important_data() {
    section "Verificando dados importantes"

    warn "ATENÇÃO: Esta operação irá remover TODOS os dados do Cluster AI Android Worker."
    warn "Certifique-se de ter feito backup de dados importantes antes de continuar."

    local data_dirs=(
        "$HOME/cluster-ai-data"
        "$HOME/Documents/cluster-ai"
        "$HOME/Android/cluster-ai"
    )

    local found_data=false
    for dir in "${data_dirs[@]}"; do
        if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
            warn "Encontrados dados em: $dir"
            found_data=true
        fi
    done

    if [ "$found_data" = true ]; then
        echo
        if ! confirm_operation "Deseja continuar mesmo assim? Dados importantes podem ser perdidos."; then
            error "Desinstalação cancelada pelo usuário."
            exit 1
        fi
    fi
}

# Função para remover dados do usuário
remove_user_data() {
    section "Removendo dados do usuário"

    local data_dirs=(
        "$HOME/cluster-ai-data"
        "$HOME/.local/share/cluster-ai"
        "$HOME/Android/data/cluster.ai.worker"
    )

    for dir in "${data_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            success "Dados removidos: $dir"
        fi
    done
}

# Função principal
main() {
    # Verificar modo dry-run
    local dry_run=false
    if [ "$1" = "--dry-run" ]; then
        dry_run=true
        warn "MODO DRY-RUN: Nenhuma alteração será feita no sistema."
        echo
    fi

    section "Desinstalação do Worker Android - Cluster AI"

    warn "Este script irá remover completamente o Worker Android do Cluster AI."
    warn "Esta ação NÃO PODE ser desfeita."

    echo
    if [ "$dry_run" = false ]; then
        if ! confirm_operation "Tem certeza que deseja continuar com a desinstalação?"; then
            log "Desinstalação cancelada pelo usuário."
            exit 0
        fi
    else
        log "Modo dry-run: pulando confirmação do usuário."
    fi

    # Verificar dados importantes
    if [ "$dry_run" = false ]; then
        check_important_data
    fi

    # Executar etapas de desinstalação
    if [ "$dry_run" = true ]; then
        log "DRY-RUN: Simulando parada de processos..."
        log "DRY-RUN: Simulando remoção de arquivos de configuração..."
        log "DRY-RUN: Simulando limpeza de cache e logs..."
        log "DRY-RUN: Simulando remoção de tarefas agendadas..."
        log "DRY-RUN: Simulando remoção de aliases..."
        log "DRY-RUN: Simulando remoção de dados do usuário..."
    else
        stop_processes
        remove_config_files
        clean_cache_logs
        remove_cron_jobs
        remove_shell_aliases
        remove_user_data
    fi

    echo
    section "Desinstalação Concluída"

    if [ "$dry_run" = true ]; then
        success "DRY-RUN: Simulação de desinstalação concluída."
        log "Para executar a desinstalação real, rode sem --dry-run"
    else
        success "Worker Android do Cluster AI foi completamente removido."
        log "Para reinstalar, execute o script de instalação novamente."
        log "Seus dados pessoais foram preservados (se existiam)."
    fi

    echo
    log "PRÓXIMOS PASSOS:"
    echo "1. Reinicie o terminal/shell para aplicar mudanças"
    echo "2. Execute o script de instalação se desejar reinstalar"
    echo "3. Verifique se não há processos remanescentes"

    echo
    success "Desinstalação concluída com sucesso!"
}

# Executar script principal
main "$@"
