#!/bin/bash
# Script para limpar arquivos temporários, logs antigos e PIDs órfãos.
# Ajuda a manter o sistema organizado e a liberar espaço em disco.

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/scripts/lib"

# Carregar funções comuns
if [ ! -f "${LIB_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em $LIB_DIR."
    exit 1
fi
source "${LIB_DIR}/common.sh"

# --- Constantes de Limpeza ---
LOGS_DIR="${PROJECT_ROOT}/logs"
RUN_DIR="${PROJECT_ROOT}/run"
TMP_DIR="/tmp"
DRY_RUN=false           # Flag para modo de simulação (dry run)
LOG_RETENTION_DAYS=7 # Manter logs por 7 dias
NON_INTERACTIVE=false # Flag para modo não interativo

# =============================================================================
# FUNÇÕES DE LIMPEZA
# =============================================================================

cleanup_logs() {
    subsection "Limpando Logs Antigos (mais de $LOG_RETENTION_DAYS dias)"

    if ! dir_exists "$LOGS_DIR"; then
        info "Diretório de logs não encontrado. Nada a fazer."
        return
    fi

    local old_logs
    old_logs=$(find "$LOGS_DIR" -name "*.log" -type f -mtime +"$LOG_RETENTION_DAYS")

    if [ -z "$old_logs" ]; then
        info "Nenhum arquivo de log antigo para limpar."
        return
    fi

    progress "Encontrados os seguintes logs antigos para remover:"
    echo "$old_logs"

    if [ "$DRY_RUN" = true ]; then
        info "[DRY RUN] Os seguintes arquivos de log seriam removidos."
        echo "$old_logs"
        return
    fi

    if [ "$NON_INTERACTIVE" = true ] || confirm_operation "Deseja remover estes arquivos de log?"; then
        # Usar 'xargs -r' para não executar rm se a lista estiver vazia
        echo "$old_logs" | xargs -r rm -f
        success "Logs antigos removidos com sucesso."
    else
        warn "Limpeza de logs cancelada."
    fi
}

cleanup_pids() {
    subsection "Limpando Arquivos PID Órfãos"

    if ! dir_exists "$RUN_DIR"; then
        info "Diretório de PIDs ($RUN_DIR) não encontrado. Nada a fazer."
        return
    fi

    local pid_files
    pid_files=$(find "$RUN_DIR" -name "*.pid" -type f)

    if [ -z "$pid_files" ]; then
        info "Nenhum arquivo PID encontrado."
        return
    fi

    for pid_file in $pid_files; do
        local pid
        pid=$(cat "$pid_file")

        if [ -z "$pid" ]; then
            warn "Arquivo PID vazio, removendo: $pid_file"
            rm -f "$pid_file"
            continue
        fi

        # Verifica se o processo com o PID não existe
        if ! ps -p "$pid" > /dev/null; then
            info "PID órfão encontrado: $pid (de $pid_file). Processo não está rodando."
            if [ "$DRY_RUN" = true ]; then
                info "[DRY RUN] O arquivo PID órfão '$pid_file' seria removido."
                continue
            fi

            if [ "$NON_INTERACTIVE" = true ] || confirm_operation "Remover arquivo PID órfão '$pid_file'?"; then
                rm -f "$pid_file"
                success "Arquivo PID órfão removido."
            fi
        else
            info "PID ativo: $pid (de $pid_file). Mantendo."
        fi
    done
}

cleanup_tmp_files() {
    subsection "Limpando Arquivos Temporários do Projeto em $TMP_DIR"

    # Padrões de arquivos temporários que o projeto pode criar
    local patterns=("dask_*.log" "ollama*.log" "openwebui*.log" "start_dask.sh")
    local files_to_remove=()

    for pattern in "${patterns[@]}"; do
        # Encontra arquivos que correspondem ao padrão e adiciona ao array
        while IFS= read -r file; do
            files_to_remove+=("$file")
        done < <(find "$TMP_DIR" -maxdepth 1 -name "$pattern" -type f 2>/dev/null)
    done

    if [ ${#files_to_remove[@]} -eq 0 ]; then
        info "Nenhum arquivo temporário do projeto encontrado em $TMP_DIR."
        return
    fi

    progress "Encontrados os seguintes arquivos temporários para remover:"
    printf " - %s\n" "${files_to_remove[@]}"

    if [ "$DRY_RUN" = true ]; then
        info "[DRY RUN] Os seguintes arquivos temporários seriam removidos."
        printf " - %s\n" "${files_to_remove[@]}"
        return
    fi

    if [ "$NON_INTERACTIVE" = true ] || confirm_operation "Deseja remover estes arquivos temporários?"; then
        rm -f "${files_to_remove[@]}"
        success "Arquivos temporários removidos."
    else
        warn "Limpeza de arquivos temporários cancelada."
    fi
}

cleanup_package_cache() {
    subsection "Limpando Cache do Gerenciador de Pacotes do Sistema"

    if [ "$NON_INTERACTIVE" = false ]; then
        if ! confirm_operation "Deseja limpar o cache de pacotes do sistema? (requer sudo)"; then
            warn "Limpeza de cache de pacotes cancelada."
            return
        fi
    fi

    local pm
    pm=$(detect_package_manager)

    if [ -z "$pm" ]; then
        error "Não foi possível detectar o gerenciador de pacotes do seu sistema."
        return
    fi

    progress "Limpando cache usando '$pm'..."
    case "$pm" in
        apt|apt-get)
            if [ "$DRY_RUN" = true ]; then
                info "[DRY RUN] Simularia a execução de 'sudo apt-get autoremove' e 'sudo apt-get clean'."
                return
            fi
            if sudo apt-get autoremove -y >/dev/null 2>&1 && sudo apt-get clean >/dev/null 2>&1; then
                success "Cache do apt limpo com sucesso."
            else
                error "Falha ao limpar o cache do apt."
            fi
            ;;
        dnf|yum)
            if [ "$DRY_RUN" = true ]; then
                info "[DRY RUN] Simularia a execução de 'sudo $pm clean all'."
                return
            fi
            if sudo "$pm" clean all >/dev/null 2>&1; then
                success "Cache do $pm limpo com sucesso."
            else
                error "Falha ao limpar o cache do $pm."
            fi
            ;;
        pacman)
            if [ "$DRY_RUN" = true ]; then
                info "[DRY RUN] Simularia a execução de 'sudo pacman -Scc --noconfirm'."
                return
            fi
            if sudo pacman -Scc --noconfirm >/dev/null 2>&1; then
                success "Cache do pacman limpo com sucesso."
            else
                error "Falha ao limpar o cache do pacman."
            fi
            ;;
        *)
            warn "Limpeza de cache não suportada para o gerenciador '$pm'."
            ;;
    esac
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Análise de argumentos
    for arg in "$@"; do
        case $arg in
            --yes|-y)
                NON_INTERACTIVE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
        esac
    done

    [ "$NON_INTERACTIVE" = true ] && info "Executando em modo não interativo. Todas as confirmações serão automáticas."
    [ "$DRY_RUN" = true ] && warn "Executando em modo de simulação (DRY RUN). Nenhuma alteração será feita."
    section "🧹 Limpeza de Arquivos do Cluster AI"

    cleanup_logs
    cleanup_pids
    cleanup_tmp_files
    cleanup_package_cache

    echo
    success "Processo de limpeza concluído!"
}

main "$@"
