#!/bin/bash

# =============================================================================
# CONSOLIDAÇÃO DE ARQUIVOS TODO - CLUSTER AI
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups/todos_consolidation_$(date +%Y%m%d_%H%M%S)"

# Função principal
main() {
    log_info "🚀 Iniciando consolidação de arquivos TODO"

    # Criar diretório de backup
    mkdir -p "$BACKUP_DIR"
    log_info "📁 Backup será salvo em: $BACKUP_DIR"

    # Encontrar todos os arquivos TODO
    TODO_FILES=$(find "$PROJECT_ROOT" -name "TODO*.md" -type f | grep -v "TODO_CRITICAL_FIXES.md" | sort)

    if [ -z "$TODO_FILES" ]; then
        log_warning "Nenhum arquivo TODO encontrado"
        exit 0
    fi

    log_info "📋 Arquivos TODO encontrados:"
    echo "$TODO_FILES" | nl

    # Fazer backup dos arquivos originais
    log_info "💾 Fazendo backup dos arquivos originais..."
    echo "$TODO_FILES" | xargs -I {} cp {} "$BACKUP_DIR/"

    # Criar arquivo consolidado
    create_consolidated_todo

    # Mostrar estatísticas
    show_statistics

    # Perguntar se deseja remover arquivos antigos
    cleanup_old_files

    log_success "✅ Consolidação concluída!"
}

# Criar arquivo TODO consolidado
create_consolidated_todo() {
    local output_file="${PROJECT_ROOT}/TODO_CONSOLIDATED.md"

    log_info "📝 Criando arquivo consolidado: $output_file"

    cat > "$output_file" << 'END_OF_FILE'
# 🎯 TODO CONSOLIDADO - CLUSTER AI

## 📊 STATUS GERAL DO PROJETO
- **Data da Consolidação**: $(date)
- **Status**: Arquivos TODO consolidados automaticamente
- **Fonte**: Consolidação de múltiplos arquivos TODO

---

## 📋 TAREFAS CONSOLIDADAS

END_OF_FILE

    # Processar cada arquivo TODO
    local file_count=0
    local total_tasks=0

    while IFS= read -r todo_file; do
        file_count=$((file_count + 1))
        filename=$(basename "$todo_file")
        relative_path=${todo_file#$PROJECT_ROOT/}

        log_info "📖 Processando: $filename"

        # Adicionar seção para este arquivo
        echo "## 📄 $filename" >> "$output_file"
        echo "**Arquivo**: \`$relative_path\`" >> "$output_file"
        echo "**Status**: Consolidado" >> "$output_file"
        echo "" >> "$output_file"

        # Extrair conteúdo do arquivo (removendo headers duplicados)
        if [ -f "$todo_file" ]; then
            # Contar tarefas neste arquivo
            if grep -q "^- \[" "$todo_file" 2>/dev/null; then
                tasks_in_file=$(grep -c "^- \[" "$todo_file")
            else
                tasks_in_file=0
            fi
            total_tasks=$((total_tasks + tasks_in_file))

            # Adicionar conteúdo (pulando headers duplicados)
            sed '1,/^---/d' "$todo_file" | grep -v "^#" | grep -v "^$" | sed 's/^/- /' >> "$output_file"
            echo "" >> "$output_file"
            echo "---" >> "$output_file"
            echo "" >> "$output_file"
        fi
    done <<< "$TODO_FILES"

    # Adicionar seção de estatísticas
    cat >> "$output_file" << EOF

---

## 📊 ESTATÍSTICAS DA CONSOLIDAÇÃO

### Arquivos Processados: $file_count
### Tarefas Totais Identificadas: $total_tasks
### Data da Consolidação: $(date)
### Backup Localizado: backups/todos_consolidation_$(date +%Y%m%d_%H%M%S)/

---

## 🎯 PRÓXIMOS PASSOS

1. **Revisar** o arquivo consolidado
2. **Priorizar** as tarefas mais importantes
3. **Executar** as tarefas críticas primeiro
4. **Atualizar** o status das tarefas conforme progresso
5. **Limpar** arquivos TODO antigos (opcional)

---

## 📋 LEGENDA DE STATUS

- ✅ **Concluída**: Tarefa finalizada com sucesso
- 🔄 **Em Andamento**: Tarefa sendo executada atualmente
- 🔄 **Pendente**: Tarefa aguardando execução
- ❌ **Cancelada**: Tarefa não será executada
- ❓ **Revisar**: Tarefa necessita análise adicional

---

**⚠️ IMPORTANTE**: Este arquivo foi gerado automaticamente. Revise o conteúdo antes de usar como referência principal.

EOF

    log_success "✅ Arquivo consolidado criado: $output_file"
}

# Mostrar estatísticas
show_statistics() {
    log_info "📊 Estatísticas da consolidação:"

    local total_files=$(echo "$TODO_FILES" | wc -l)
    local total_size=$(echo "$TODO_FILES" | xargs wc -l | tail -1 | awk '{print $1}')

    echo "  • Arquivos processados: $total_files"
    echo "  • Linhas totais: $total_size"
    echo "  • Backup criado: $BACKUP_DIR"
}

# Limpar arquivos antigos
cleanup_old_files() {
    echo ""
    log_warning "🔍 Os arquivos TODO originais foram mantidos para segurança."
    log_info "Para removê-los manualmente, execute:"
    echo "  rm $TODO_FILES 2>/dev/null || true"
    echo ""
    log_info "Ou use o arquivo consolidado como referência principal:"
    echo "  TODO_CONSOLIDATED.md"
}

# Executar função principal
main "$@"
EOF

chmod +x "$SCRIPT_DIR/consolidate_todos.sh"
log_success "✅ Script de consolidação criado: scripts/maintenance/consolidate_todos.sh"
