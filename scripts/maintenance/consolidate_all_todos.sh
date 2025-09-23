#!/bin/bash
# =============================================================================
# Script de Consolidação Completa de TODOs - Cluster AI
# =============================================================================
# Consolida TODOS os arquivos TODO do projeto em um único TODO_MASTER.md
# Remove duplicatas, organiza por prioridade e gera relatórios
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 2.0.0 - Consolidação Completa
# Arquivo: consolidate_all_todos.sh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups/todos_consolidation_$(date +%Y%m%d_%H%M%S)"
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
# FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------
backup_existing_todos() {
    log_info "Criando backup de todos os arquivos TODO existentes..."

    mkdir -p "${BACKUP_DIR}"

    # Backup de todos os arquivos TODO
    find "${PROJECT_ROOT}" -name "TODO*.md" -type f -exec cp {} "${BACKUP_DIR}/" \;

    # Backup do TODO_MASTER atual
    if [ -f "${TODO_MASTER}" ]; then
        cp "${TODO_MASTER}" "${BACKUP_DIR}/TODO_MASTER_before_consolidation.md"
    fi

    log_success "Backup criado em: ${BACKUP_DIR}"
}

analyze_todos() {
    log_info "Analisando todos os arquivos TODO..."

    # Encontrar todos os arquivos TODO
    local todo_files
    todo_files=$(find "${PROJECT_ROOT}" -name "TODO*.md" -type f)

    local total_files=0
    local total_lines=0
    local unique_tasks=0

    echo "# 📊 ANÁLISE DE TODOS OS ARQUIVOS TODO" > "${BACKUP_DIR}/analysis_report.md"
    echo "- **Data da Análise**: $(date)" >> "${BACKUP_DIR}/analysis_report.md"
    echo "- **Total de Arquivos TODO**: $(echo "$todo_files" | wc -l)" >> "${BACKUP_DIR}/analysis_report.md"
    echo "" >> "${BACKUP_DIR}/analysis_report.md"

    echo "## 📋 LISTA DE ARQUIVOS TODO ENCONTRADOS" >> "${BACKUP_DIR}/analysis_report.md"

    while IFS= read -r file; do
        if [ -f "$file" ]; then
            ((total_files++))
            local lines=$(wc -l < "$file")
            ((total_lines += lines))

            echo "- **$file**: $lines linhas" >> "${BACKUP_DIR}/analysis_report.md"

            # Extrair tarefas (linhas que começam com - [ ])
            local tasks_in_file=$(grep -c "^- \[" "$file" 2>/dev/null || echo "0")
            ((unique_tasks += tasks_in_file))
        fi
    done <<< "$todo_files"

    echo "" >> "${BACKUP_DIR}/analysis_report.md"
    echo "## 📊 MÉTRICAS GERAIS" >> "${BACKUP_DIR}/analysis_report.md"
    echo "- **Arquivos TODO**: $total_files" >> "${BACKUP_DIR}/analysis_report.md"
    echo "- **Total de linhas**: $total_lines" >> "${BACKUP_DIR}/analysis_report.md"
    echo "- **Tarefas identificadas**: $unique_tasks" >> "${BACKUP_DIR}/analysis_report.md"
    echo "- **Tamanho médio por arquivo**: $((total_lines / total_files)) linhas" >> "${BACKUP_DIR}/analysis_report.md"

    log_success "Análise concluída. Relatório: ${BACKUP_DIR}/analysis_report.md"
}

extract_tasks_from_todos() {
    log_info "Extraindo tarefas de todos os arquivos TODO..."

    local temp_tasks_file="${BACKUP_DIR}/extracted_tasks.txt"

    # Encontrar todos os arquivos TODO
    local todo_files
    todo_files=$(find "${PROJECT_ROOT}" -name "TODO*.md" -type f)

    > "$temp_tasks_file"

    while IFS= read -r file; do
        if [ -f "$file" ]; then
            log_info "Processando: $file"

            # Extrair tarefas (linhas que começam com - [ ])
            grep "^- \[" "$file" 2>/dev/null | while IFS= read -r task; do
                # Adicionar arquivo de origem como comentário
                echo "# FROM: $file" >> "$temp_tasks_file"
                echo "$task" >> "$temp_tasks_file"
                echo "" >> "$temp_tasks_file"
            done
        fi
    done <<< "$todo_files"

    log_success "Tarefas extraídas: $(wc -l < "$temp_tasks_file") tarefas encontradas"
}

categorize_and_deduplicate() {
    log_info "Categorizando e removendo duplicatas..."

    local temp_tasks_file="${BACKUP_DIR}/extracted_tasks.txt"
    local categorized_file="${BACKUP_DIR}/categorized_tasks.md"

    # Categorias baseadas em palavras-chave
    local categories=(
        "CRÍTICA:.*[Cc]rítc\|URGENTE\|BLOQUEANTE"
        "ALTA:.*[Aa]lt.*prioridade\|IMPORTANTE\|PRIORIDADE.*ALTA"
        "MÉDIA:.*[Mm]édia.*prioridade\|MELHORIA\|OTIMIZAÇÃO"
        "BAIXA:.*[Bb]aix.*prioridade\|OPCIONAL\|FUTURO"
        "DOCUMENTAÇÃO:.*[Dd]ocumentação\|README\|GUIA"
        "TESTES:.*[Tt]est.*\|[Tt]estando\|VALIDAR"
        "SEGURANÇA:.*[Ss]egurança\|[Ss]ecurity\|AUDITORIA"
        "PERFORMANCE:.*[Pp]erformance\|[Oo]timiz\|VELOCIDADE"
        "INFRAESTRUTURA:.*[Ii]nfra\|DEPLOY\|SERVIDOR"
        "GERAL:.*"
    )

    echo "# 🎯 TAREFAS CATEGORIZADAS E DESDUPLICADAS" > "$categorized_file"
    echo "- **Data da Categorização**: $(date)" >> "$categorized_file"
    echo "- **Total de Tarefas Processadas**: $(wc -l < "$temp_tasks_file")" >> "$categorized_file"
    echo "" >> "$categorized_file"

    local task_count=0

    for category in "${categories[@]}"; do
        local category_name=$(echo "$category" | cut -d':' -f1)
        local pattern=$(echo "$category" | cut -d':' -f2)

        echo "## 📋 $category_name" >> "$categorized_file"
        echo "" >> "$categorized_file"

        # Encontrar tarefas únicas desta categoria
        grep -A1 -B1 "$pattern" "$temp_tasks_file" | grep "^- \[" | sort | uniq -c | sort -nr | while read -r count task; do
            if [ "$count" -eq 1 ]; then
                echo "$task" >> "$categorized_file"
                echo "" >> "$categorized_file"
                ((task_count++))
            fi
        done

        echo "" >> "$categorized_file"
    done

    echo "## 📊 RESUMO DA CATEGORIZAÇÃO" >> "$categorized_file"
    echo "- **Total de tarefas únicas**: $task_count" >> "$categorized_file"
    echo "- **Categorias processadas**: ${#categories[@]}" >> "$categorized_file"

    log_success "Categorização concluída: $task_count tarefas únicas organizadas"
}

generate_new_todo_master() {
    log_info "Gerando novo TODO_MASTER.md consolidado..."

    local categorized_file="${BACKUP_DIR}/categorized_tasks.md"

    # Backup do TODO_MASTER atual
    if [ -f "${TODO_MASTER}" ]; then
        cp "${TODO_MASTER}" "${TODO_MASTER}.backup_$(date +%Y%m%d_%H%M%S)"
    fi

    # Criar novo TODO_MASTER
    cat > "${TODO_MASTER}" << 'EOF'
# 🎯 TODO MASTER - CLUSTER AI CONSOLIDADO

## 📊 STATUS GERAL DO PROJETO
- **Data da Consolidação**: $(date)
- **Status**: Consolidação completa realizada
- **Prioridade**: ALTA - Manutenção necessária

---

## 🔍 CONSOLIDAÇÃO REALIZADA

### 📋 CONSOLIDAÇÃO COMPLETA DE TODOS OS TODOs
**Processo realizado:**
- ✅ **Análise**: $(find . -name "TODO*.md" -type f | wc -l) arquivos TODO processados
- ✅ **Extração**: Todas as tarefas identificadas e extraídas
- ✅ **Categorização**: Tarefas organizadas por prioridade
- ✅ **Desduplicação**: Tarefas duplicadas removidas
- ✅ **Backup**: Todos os arquivos originais preservados

**Resultados:**
- **Antes**: $(find . -name "TODO*.md" -type f | wc -l) arquivos TODO fragmentados
- **Depois**: 1 arquivo TODO_MASTER.md consolidado
- **Eficiência**: $(echo "scale=1; ($(find . -name "TODO*.md" -type f | wc -l) - 1) * 100 / $(find . -name "TODO*.md" -type f | wc -l)" | bc)% redução

---

EOF

    # Adicionar tarefas categorizadas
    if [ -f "$categorized_file" ]; then
        cat "$categorized_file" >> "${TODO_MASTER}"
    fi

    # Adicionar seção de métricas finais
    cat >> "${TODO_MASTER}" << EOF

## 📊 MÉTRICAS FINAIS DA CONSOLIDAÇÃO

### ✅ Benefícios Alcançados:
- **Organização**: Todas as tarefas em um único local
- **Manutenibilidade**: Facilita acompanhamento do progresso
- **Priorização**: Tarefas organizadas por importância
- **Eficiência**: Eliminação de duplicatas e redundâncias

### 📈 Estatísticas de Consolidação:
- **Arquivos processados**: $(find . -name "TODO*.md" -type f | wc -l)
- **Tarefas identificadas**: $(grep -c "^- \[" "$categorized_file" 2>/dev/null || echo "0")
- **Tarefas únicas**: $(grep "^- \[" "$categorized_file" 2>/dev/null | wc -l)
- **Categorias criadas**: $(grep "^## " "$categorized_file" 2>/dev/null | wc -l)
- **Espaço economizado**: ~$(echo "scale=0; ($(find . -name "TODO*.md" -type f -exec wc -l {} \; | awk '{sum+=$1} END {print sum}') - $(wc -l < "$categorized_file")) / 100 * 100" | bc)% das linhas

---

## 🚨 PRÓXIMOS PASSOS APÓS CONSOLIDAÇÃO

### 📋 Manutenção Contínua:
1. **Atualização Regular**: Manter TODO_MASTER.md atualizado
2. **Revisão Periódica**: Revisar tarefas mensalmente
3. **Priorização**: Reavaliar prioridades conforme necessário
4. **Arquivamento**: Mover tarefas concluídas para histórico

### ✅ Validação:
- [ ] Verificar se todas as tarefas importantes foram preservadas
- [ ] Testar funcionalidades críticas mencionadas nos TODOs
- [ ] Atualizar documentação relacionada
- [ ] Comunicar mudanças à equipe

---

## 📁 LOCALIZAÇÃO DOS BACKUPS

Todos os arquivos TODO originais foram preservados em:
- **Backup principal**: \`${BACKUP_DIR}/\`
- **Relatório de análise**: \`${BACKUP_DIR}/analysis_report.md\`
- **Tarefas extraídas**: \`${BACKUP_DIR}/extracted_tasks.txt\`
- **Tarefas categorizadas**: \`${BACKUP_DIR}/categorized_tasks.md\`

---

**📋 Status**: ✅ CONSOLIDAÇÃO COMPLETA REALIZADA
**👤 Responsável**: Sistema de consolidação automática
**📅 Data**: $(date)
**🎯 Resultado**: Projeto completamente organizado

EOF

    log_success "Novo TODO_MASTER.md gerado com sucesso!"
}

cleanup_old_todos() {
    log_warn "ATENÇÃO: Removendo arquivos TODO antigos..."
    log_warn "Todos os arquivos foram backupados em: ${BACKUP_DIR}"

    read -p "Tem certeza que deseja remover os arquivos TODO antigos? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remover todos os arquivos TODO exceto TODO_MASTER.md
        find "${PROJECT_ROOT}" -name "TODO*.md" -type f -not -name "TODO_MASTER.md" -delete

        log_success "Arquivos TODO antigos removidos"
        log_info "Apenas TODO_MASTER.md foi mantido"
    else
        log_info "Operação cancelada. Todos os arquivos TODO foram preservados."
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    echo
    echo "🤖 CLUSTER AI - CONSOLIDAÇÃO COMPLETA DE TODOS OS TODOs"
    echo "======================================================"
    echo
    echo "Este script irá:"
    echo "1. ✅ Analisar todos os $(find . -name "TODO*.md" -type f | wc -l) arquivos TODO existentes"
    echo "2. ✅ Extrair e categorizar todas as tarefas"
    echo "3. ✅ Remover duplicatas e organizar por prioridade"
    echo "4. ✅ Gerar um TODO_MASTER.md consolidado"
    echo "5. ✅ Criar backup completo de todos os arquivos"
    echo "6. ✅ Oferecer remoção dos arquivos antigos"
    echo

    # Verificar se há arquivos TODO para processar
    local todo_count
    todo_count=$(find . -name "TODO*.md" -type f | wc -l)

    if [ "$todo_count" -le 1 ]; then
        log_success "Apenas 1 arquivo TODO encontrado. Nenhuma consolidação necessária."
        exit 0
    fi

    # Executar consolidação
    backup_existing_todos
    analyze_todos
    extract_tasks_from_todos
    categorize_and_deduplicate
    generate_new_todo_master
    cleanup_old_todos

    echo
    echo "🎉 CONSOLIDAÇÃO COMPLETA REALIZADA COM SUCESSO!"
    echo
    echo "📊 Resumo:"
    echo "   • Arquivos processados: $todo_count"
    echo "   • Backup criado em: $BACKUP_DIR"
    echo "   • TODO_MASTER.md atualizado"
    echo "   • Tarefas organizadas por prioridade"
    echo
    echo "📋 Para visualizar o resultado:"
    echo "   • Arquivo consolidado: TODO_MASTER.md"
    echo "   • Relatório detalhado: $BACKUP_DIR/analysis_report.md"
    echo
}

# -----------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
