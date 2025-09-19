#!/bin/bash
#
# 🧹 SCRIPT DE LIMPEZA DO .BASHRC
# Remove configurações obsoletas adicionadas por scripts antigos do Cluster AI.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Constantes ---
BASHRC_FILE="$HOME/.bashrc"
BACKUP_FILE="$HOME/.bashrc.backup-cluster-ai-$(date +%Y%m%d_%H%M%S)"

# --- Função Principal de Limpeza ---

main() {
    section "🧹 Limpeza de Configurações Obsoletas do ~/.bashrc"

    if [ ! -f "$BASHRC_FILE" ]; then
        warn "Arquivo ~/.bashrc não encontrado. Nenhuma ação necessária."
        exit 0
    fi

    # Padrões a serem removidos. Cada padrão é um marcador de início de um bloco obsoleto.
    local patterns_to_remove=(
        "# Otimizações para VSCode no Debian"
        "# Aliases para VS Code ultra-seguro"
        "# Aliases para VS Code manual"
        "# Aliases para VS Code anti-crash"
        "# Aliases para VS Code seguro"
        "# Alias para VS Code seguro" # Variação
    )

    local found_obsolete_config=false
    for pattern in "${patterns_to_remove[@]}"; do
        if grep -qF "$pattern" "$BASHRC_FILE"; then
            found_obsolete_config=true
            break
        fi
    done

    if ! $found_obsolete_config; then
        success "Nenhuma configuração obsoleta do Cluster AI encontrada em seu ~/.bashrc."
        exit 0
    fi

    info "Foram encontradas configurações antigas do Cluster AI em seu ~/.bashrc."
    if ! confirm "Deseja remover essas configurações agora? Um backup será criado."; then
        warn "Operação de limpeza cancelada."
        exit 0
    fi

    # 1. Criar backup
    progress "Criando backup do seu .bashrc em: $BACKUP_FILE"
    cp "$BASHRC_FILE" "$BACKUP_FILE"
    success "Backup criado com sucesso."

    # 2. Remover os blocos obsoletos
    progress "Removendo blocos de configuração obsoletos..."
    local temp_file; temp_file=$(mktemp)
    
    # Usa awk para filtrar o conteúdo. Quando um padrão de início de bloco é encontrado,
    # uma flag 'in_block' é ativada. As linhas são puladas até que uma linha em branco
    # seja encontrada, desativando a flag.
    awk '
        BEGIN { in_block=0 }
        /^# (Otimizações para VSCode no Debian|Aliases para VS Code)/ { in_block=1 }
        # Se estivermos em um bloco e encontrarmos uma linha em branco, saímos do bloco.
        in_block && /^\s*$/ { in_block=0; next }
        # Se estivermos em um bloco, pulamos a linha.
        in_block { next }
        # Caso contrário, imprimimos a linha.
        { print }
    ' "$BASHRC_FILE" > "$temp_file"

    # Substitui o arquivo original pelo arquivo limpo
    mv "$temp_file" "$BASHRC_FILE"
    success "Configurações obsoletas removidas."

    # 3. Instruções finais
    section "🎉 Limpeza Concluída!"
    info "Para aplicar as mudanças no seu terminal atual, execute o comando:"
    echo -e "${CYAN}source ~/.bashrc${NC}"
    echo
    warn "Se algo der errado, você pode restaurar o backup com o comando:"
    echo -e "${YELLOW}cp \"$BACKUP_FILE\" \"$BASHRC_FILE\"${NC}"
}

# Executar script principal
main "$@"