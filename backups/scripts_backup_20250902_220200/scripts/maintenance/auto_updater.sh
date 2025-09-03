#!/bin/bash
# Script para atualizar o projeto Cluster AI para a versão mais recente do GitHub.
# Descrição: Baixa as últimas alterações do repositório Git e aplica ações pós-atualização.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
VENV_PATH="$HOME/cluster_env" # Usando o venv do home, pode ser ajustado

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Funções ---

# Verifica se o git está instalado e se o diretório é um repositório git
check_git() {
    if ! command_exists git; then
        error "Comando 'git' não encontrado. A atualização automática não é possível."
        return 1
    fi
    if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        error "O diretório do projeto não é um repositório Git. A atualização não é possível."
        return 1
    fi
    return 0
}

# Verifica se há alterações locais não salvas
check_local_changes() {
    if ! git -C "$PROJECT_ROOT" diff-index --quiet HEAD --; then
        warn "Você possui alterações locais não salvas (uncommitted)."
        if confirm_operation "Deseja guardá-las temporariamente (git stash) para prosseguir com a atualização?"; then
            git -C "$PROJECT_ROOT" stash
            return 0 # Stashed
        else
            error "Atualização cancelada. Por favor, salve (commit) ou descarte suas alterações."
            return 1 # Aborted
        fi
    fi
    return 2 # Clean
}

# Executa ações pós-atualização
run_post_update_actions() {
    subsection "Executando Ações Pós-Atualização"
    
    # Lista de arquivos alterados na última atualização
    local changed_files
    changed_files=$(git -C "$PROJECT_ROOT" diff-tree --no-commit-id --name-only -r HEAD@{1} HEAD)

    # 1. Reinstalar dependências Python se requirements.txt mudou
    if echo "$changed_files" | grep -q "requirements.txt"; then
        log "O arquivo 'requirements.txt' foi atualizado."
        if [ -d "$VENV_PATH" ]; then
            if confirm_operation "Deseja reinstalar as dependências Python agora?"; then
                log "Ativando ambiente virtual e instalando dependências..."
                source "$VENV_PATH/bin/activate"
                pip install -r "${PROJECT_ROOT}/requirements.txt"
                deactivate
                success "Dependências Python atualizadas."
            fi
        else
            warn "Ambiente virtual não encontrado em $VENV_PATH. Pule a atualização de dependências."
        fi
    fi

    # 2. Avisar sobre atualização do instalador
    if echo "$changed_files" | grep -q "install.sh"; then
        warn "O script de instalação principal ('install.sh') foi atualizado."
        info "Pode ser necessário executá-lo novamente para garantir que todas as dependências do sistema estejam corretas."
    fi

    # 3. Garantir que todos os scripts sejam executáveis
    log "Atualizando permissões de execução para todos os scripts .sh..."
    find "$PROJECT_ROOT" -type f -name "*.sh" -exec chmod +x {} \;
    success "Permissões dos scripts atualizadas."
}

# Função principal de atualização
do_update() {
    section "Atualizador Automático do Cluster AI"
    if ! check_git; then return 1; fi

    local stash_result
    check_local_changes
    stash_result=$?
    if [ "$stash_result" -eq 1 ]; then return 1; fi # Aborted by user

    log "Buscando atualizações do repositório remoto (git fetch)..."
    git -C "$PROJECT_ROOT" fetch origin

    local local_hash; local_hash=$(git -C "$PROJECT_ROOT" rev-parse @)
    local remote_hash; remote_hash=$(git -C "$PROJECT_ROOT" rev-parse '@{u}')

    if [ "$local_hash" == "$remote_hash" ]; then
        success "🎉 Você já está com a versão mais recente do projeto!"
        # Se guardou algo, restaurar
        if [ "$stash_result" -eq 0 ]; then
            log "Restaurando suas alterações locais (git stash pop)..."
            git -C "$PROJECT_ROOT" stash pop
        fi
        return 0
    fi

    warn "Nova versão encontrada! Iniciando atualização (git pull)..."
    if git -C "$PROJECT_ROOT" pull --rebase; then
        success "Projeto atualizado com sucesso!"
        run_post_update_actions

        # Se guardou algo, restaurar
        if [ "$stash_result" -eq 0 ]; then
            log "Restaurando suas alterações locais (git stash pop)..."
            git -C "$PROJECT_ROOT" stash pop || warn "Não foi possível restaurar o stash automaticamente. Use 'git stash pop' manualmente."
        fi
    else
        error "Falha ao atualizar o projeto com 'git pull'."
        info "Pode haver conflitos que precisam ser resolvidos manualmente."
        if [ "$stash_result" -eq 0 ]; then
            warn "Suas alterações ainda estão guardadas. Use 'git stash pop' para restaurá-las após resolver os conflitos."
        fi
        return 1
    fi
}

# --- Menu Principal ---
main() {
    do_update
}

main "$@"