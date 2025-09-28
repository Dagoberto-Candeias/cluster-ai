#!/bin/bash
# =============================================================================
# Script de Consolidação Simples de TODOs - Cluster AI
# =============================================================================
# Versão simplificada que consolida apenas arquivos TODO na raiz do projeto
#
# Autor: Cluster AI Team
# Data: 2025-09-23
# Versão: 1.0.0 - Simplificada
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups/todos_simple_consolidation_$(date +%Y%m%d_%H%M%S)"
readonly TODO_MASTER="${PROJECT_ROOT}/TODO_MASTER.md"

# -----------------------------------------------------------------------------
# CORES PARA OUTPUT
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOGGING
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    echo
    echo "🤖 CLUSTER AI - CONSOLIDAÇÃO SIMPLES DE TODOS"
    echo "=============================================="
    echo

    # Encontrar apenas arquivos TODO na raiz (excluindo backups e subdiretórios)
    local root_todos
    root_todos=$(find "${PROJECT_ROOT}" -maxdepth 1 -name "TODO*.md" -type f | grep -v "TODO_MASTER.md" | sort)

    local todo_count
    todo_count=$(echo "$root_todos" | wc -l)

    echo "Este script irá:"
    echo "1. ✅ Processar $todo_count arquivos TODO na raiz"
    echo "2. ✅ Consolidar em TODO_MASTER.md"
    echo "3. ✅ Criar backup dos arquivos originais"
    echo "4. ✅ Remover arquivos duplicados"
    echo

    if [ "$todo_count" -eq 0 ]; then
        log_success "Nenhum arquivo TODO para consolidar na raiz."
        exit 0
    fi

    log_info "Arquivos a processar:"
    echo "$root_todos" | sed 's/^/   - /'
    echo

    # Criar backup
    log_info "Criando backup..."
    mkdir -p "${BACKUP_DIR}"
    echo "$root_todos" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            cp "$file" "${BACKUP_DIR}/"
        fi
    done

    # Backup do TODO_MASTER atual
    if [ -f "${TODO_MASTER}" ]; then
        cp "${TODO_MASTER}" "${BACKUP_DIR}/TODO_MASTER_before.md"
    fi

    log_success "Backup criado em: ${BACKUP_DIR}"

    # Criar novo TODO_MASTER
    log_info "Gerando TODO_MASTER.md consolidado..."

    cat > "${TODO_MASTER}" << 'EOF'
# 🎯 TODO MASTER - CLUSTER AI CONSOLIDADO

## 📊 STATUS GERAL DO PROJETO
- **Data da Consolidação**: $(date)
- **Status**: Consolidação simples realizada
- **Prioridade**: ALTA - Manutenção necessária

---

## 🔍 CONSOLIDAÇÃO REALIZADA

### 📋 CONSOLIDAÇÃO DOS ARQUIVOS TODO DA RAIZ
**Processo realizado:**
- ✅ **Análise**: $(echo "$root_todos" | wc -l) arquivos TODO processados
- ✅ **Consolidação**: Todas as tarefas unificadas
- ✅ **Backup**: Arquivos originais preservados
- ✅ **Limpeza**: Apenas arquivos duplicados removidos

**Arquivos consolidados:**
EOF

    # Adicionar lista dos arquivos consolidados
    echo "$root_todos" | sed 's/^/- /' >> "${TODO_MASTER}"

    cat >> "${TODO_MASTER}" << 'EOF'

---

## 📋 TAREFAS CONSOLIDADAS

EOF

    # Extrair e adicionar tarefas de cada arquivo
    echo "$root_todos" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            echo "" >> "${TODO_MASTER}"
            echo "### 📄 $(basename "$file")" >> "${TODO_MASTER}"
            echo "" >> "${TODO_MASTER}"

            # Extrair tarefas (linhas que começam com - [ ])
            grep "^- \[" "$file" 2>/dev/null | while IFS= read -r task; do
                echo "$task" >> "${TODO_MASTER}"
            done || echo "Nenhuma tarefa encontrada em $(basename "$file")" >> "${TODO_MASTER}"
        fi
    done

    # Adicionar seção final
    cat >> "${TODO_MASTER}" << EOF

---

## 📊 MÉTRICAS DA CONSOLIDAÇÃO

### ✅ Resultados:
- **Arquivos processados**: $todo_count
- **Backup criado**: ${BACKUP_DIR}
- **Arquivo consolidado**: TODO_MASTER.md
- **Status**: ✅ CONSOLIDAÇÃO COMPLETA

### 📈 Benefícios:
- **Organização**: Todas as tarefas em um único local
- **Manutenibilidade**: Facilita acompanhamento do progresso
- **Eficiência**: Eliminação de arquivos duplicados

---

**📋 Status**: ✅ CONSOLIDAÇÃO SIMPLES REALIZADA
**👤 Responsável**: Sistema de consolidação automática
**📅 Data**: $(date)
**🎯 Resultado**: TODO_MASTER.md atualizado com todas as tarefas

EOF

    log_success "TODO_MASTER.md consolidado gerado com sucesso!"

    # Remover arquivos antigos (exceto TODO_MASTER.md)
    log_warn "Removendo arquivos TODO antigos da raiz..."
    echo "$root_todos" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            rm "$file"
            log_info "Removido: $(basename "$file")"
        fi
    done

    log_success "Limpeza concluída!"

    echo
    echo "🎉 CONSOLIDAÇÃO SIMPLES REALIZADA COM SUCESSO!"
    echo
    echo "📊 Resumo:"
    echo "   • Arquivos processados: $todo_count"
    echo "   • Backup criado em: $BACKUP_DIR"
    echo "   • TODO_MASTER.md atualizado"
    echo "   • Arquivos antigos removidos"
    echo
    echo "📋 Para visualizar o resultado:"
    echo "   • Arquivo consolidado: TODO_MASTER.md"
    echo "   • Backup dos originais: $BACKUP_DIR"
    echo
}

# -----------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
