#!/bin/bash

# 🧹 SISTEMA DE CONSOLIDAÇÃO DE TODOS
# Analisa, consolida e organiza todos os arquivos TODO do projeto

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Constantes ---
BACKUP_DIR="$PROJECT_ROOT/backups/todos_before_consolidation"
MASTER_TODO="$PROJECT_ROOT/TODO_MASTER.md"
ANALYSIS_FILE="$PROJECT_ROOT/TODO_ANALYSIS.md"

# --- Funções de Análise ---

# Encontrar todos os arquivos TODO
find_todo_files() {
    subsection "🔍 Procurando Arquivos TODO"

    local todo_files=()

    # Procurar arquivos que contenham "TODO" no nome
    while IFS= read -r -d '' file; do
        todo_files+=("$file")
    done < <(find "$PROJECT_ROOT" -name "*[Tt][Oo][Dd][Oo]*" -type f -print0)

    # Procurar arquivos que contenham "TODO" no conteúdo
    while IFS= read -r -d '' file; do
        if [[ ! " ${todo_files[*]} " =~ " $file " ]]; then
            todo_files+=("$file")
        fi
    done < <(grep -rl "TODO\|FIXME\|XXX" "$PROJECT_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=__pycache__ -print0 2>/dev/null || true)

    echo "${todo_files[@]}"
}

# Analisar conteúdo de um arquivo TODO
analyze_todo_file() {
    local file="$1"
    local filename=$(basename "$file")

    echo "## 📄 $filename"
    echo "**Localização:** $file"
    echo

    # Contar tarefas
    local total_tasks=$(grep -c "^\s*[-*]\s*\[.*\]" "$file" 2>/dev/null || echo "0")
    local completed_tasks=$(grep -c "^\s*[-*]\s*\[x\]" "$file" 2>/dev/null || echo "0")
    local pending_tasks=$((total_tasks - completed_tasks))

    echo "**Estatísticas:**"
    echo "- Total de tarefas: $total_tasks"
    echo "- Concluídas: $completed_tasks"
    echo "- Pendentes: $pending_tasks"
    echo

    # Mostrar tarefas pendentes
    if [ "$pending_tasks" -gt 0 ]; then
        echo "**Tarefas Pendentes:**"
        grep "^\s*[-*]\s*\[[^x]\]" "$file" 2>/dev/null | sed 's/^\s*//' | while read -r task; do
            echo "- $task"
        done
        echo
    fi

    # Mostrar seções principais
    echo "**Seções:**"
    grep "^#" "$file" | head -10 | while read -r section; do
        echo "- $section"
    done
    echo
    echo "---"
    echo
}

# --- Funções de Consolidação ---

# Criar backup dos TODOs atuais
backup_todos() {
    subsection "💾 Criando Backup dos TODOs Atuais"

    mkdir -p "$BACKUP_DIR"

    local todo_files
    mapfile -t todo_files < <(find_todo_files)

    for file in "${todo_files[@]}"; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            cp "$file" "$BACKUP_DIR/$filename"
            log "Backup criado: $filename"
        fi
    done

    success "✅ Backup criado em: $BACKUP_DIR"
}

# Normaliza uma linha de tarefa para comparação
normalize_task_line() {
    echo "$1" | sed 's/^\s*-\s*\[.\]\s*//' | sed 's/^\s*//;s/\s*$//' | tr '[:upper:]' '[:lower:]'
}

# Carrega tarefas existentes do TODO_MASTER para evitar duplicatas
load_existing_tasks() {
    local existing_tasks_file="$1"
    if [ -f "$MASTER_TODO" ]; then
        # Extrai o texto de tarefas pendentes e concluídas, normaliza e salva no arquivo temporário
        grep -E '^\s*-\s*\[[ x]\]' "$MASTER_TODO" | while IFS= read -r line; do normalize_task_line "$line"; done > "$existing_tasks_file"
    fi
}

# Consolidar tarefas por categoria
consolidate_tasks() {
    subsection "🔄 Consolidando Tarefas"

    local consolidated_tasks=""

    # Definir categorias
    local categories=(
        "INSTALAÇÃO:Instalação e Setup"
        "MANUTENÇÃO:Manutenção e Reparo"
        "DOCUMENTAÇÃO:Documentação"
        "SEGURANÇA:Segurança"
        "PERFORMANCE:Performance e Otimização"
        "TESTES:Testes e Validação"
        "DEPLOYMENT:Deployment e Configuração"
        "ANDROID:Android Workers"
        "OUTROS:Outros"
    )

    # Arquivo temporário para rastrear tarefas já adicionadas nesta execução
    local temp_existing_tasks; temp_existing_tasks=$(mktemp)
    trap 'rm -f "$temp_existing_tasks"' RETURN
    load_existing_tasks "$temp_existing_tasks"

    for category in "${categories[@]}"; do
        local cat_key cat_name
        cat_key=$(echo "$category" | cut -d: -f1)
        cat_name=$(echo "$category" | cut -d: -f2)

        consolidated_tasks+=$'\n'"### $cat_name"$'\n'

        # Procurar tarefas relacionadas nesta categoria
        local todo_files
        mapfile -t todo_files < <(find_todo_files)

        local found_tasks=false
        for file in "${todo_files[@]}"; do
            if [ -f "$file" ]; then
                # Procurar tarefas relacionadas à categoria
                local pattern=""
                case "$cat_key" in
                    "INSTALAÇÃO") pattern="(install|setup|configur)" ;;
                    "MANUTENÇÃO") pattern="(repair|maintenance|fix|bug)" ;;
                    "DOCUMENTAÇÃO") pattern="(doc|readme|manual|guide)" ;;
                    "SEGURANÇA") pattern="(security|auth|encrypt|ssl)" ;;
                    "PERFORMANCE") pattern="(performance|optimize|speed|memory)" ;;
                    "TESTES") pattern="(test|validate|check|verify)" ;;
                    "DEPLOYMENT") pattern="(deploy|worker|cluster|node)" ;;
                    "ANDROID") pattern="(android|termux|mobile)" ;;
                    "OUTROS") pattern=".*" ;;
                esac

                if [ -n "$pattern" ]; then
                    local tasks
                    tasks=$(grep -i "$pattern" "$file" | grep -v "^#" | grep -v "^\s*$" | sed 's/^\s*//' | head -5 2>/dev/null || true)

                    if [ -n "$tasks" ]; then
                        consolidated_tasks+=$'\n'"**Fonte: $(basename "$file")**"$'\n'
                        while IFS= read -r task; do
                            local normalized_task
                            normalized_task=$(normalize_task_line "$task")
                            if [ -n "$normalized_task" ] && ! grep -qFx "$normalized_task" "$temp_existing_tasks"; then
                                # Adiciona a tarefa ao resultado e ao controle de duplicatas
                                consolidated_tasks+="- [ ] $(echo "$task" | sed 's/^\s*-\s*\[.\]\s*//')"$'\n'
                                echo "$normalized_task" >> "$temp_existing_tasks"
                                found_tasks=true # Marca que encontrou pelo menos uma tarefa nova
                            fi
                        done <<< "$(echo "$tasks" | sed 's/^\s*//')" # Remove leading spaces from tasks
                        consolidated_tasks+=$'\n'
                    fi
                fi
            fi
        done

        if [ "$found_tasks" = false ]; then
            consolidated_tasks+="- Nenhuma tarefa específica encontrada"$'\n'$'\n'
        fi
    done

    echo "$consolidated_tasks"
}

# Criar TODO_MASTER consolidado
create_master_todo() {
    subsection "📝 Criando TODO_MASTER Consolidado"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$MASTER_TODO" << EOF
# 🎯 TODO MASTER - CLUSTER AI CONSOLIDADO

**Última atualização:** $timestamp
**Status:** Consolidado automaticamente

## 📊 RESUMO DA CONSOLIDAÇÃO

- **Arquivos analisados:** $(find_todo_files | wc -w)
- **Backup criado em:** $BACKUP_DIR
- **Script de consolidação:** $(basename "$0")

---

## 📋 TAREFAS CONSOLIDADAS POR CATEGORIA

$(consolidate_tasks)

---

## 📈 PRÓXIMOS PASSOS

### Prioridade ALTA
- [ ] Revisar tarefas consolidadas
- [ ] Validar informações críticas
- [ ] Atualizar status das tarefas

### Prioridade MÉDIA
- [ ] Limpar arquivos TODO duplicados
- [ ] Atualizar documentação
- [ ] Testar funcionalidades

### Prioridade BAIXA
- [ ] Otimizar estrutura de arquivos
- [ ] Melhorar scripts de automação
- [ ] Documentar processo de consolidação

---

## 🔍 ANÁLISE DETALHADA DOS ARQUIVOS ORIGINAIS

EOF

    # Adicionar análise detalhada
    local todo_files
    mapfile -t todo_files < <(find_todo_files)

    for file in "${todo_files[@]}"; do
        if [ -f "$file" ]; then
            analyze_todo_file "$file" >> "$MASTER_TODO"
        fi
    done

    success "✅ TODO_MASTER criado: $MASTER_TODO"
}

# --- Funções de Limpeza ---

# Identificar arquivos duplicados
identify_duplicates() {
    subsection "🔍 Identificando Arquivos Duplicados"

    local todo_files
    mapfile -t todo_files < <(find_todo_files)

    echo "Arquivos TODO encontrados:"
    printf '%s\n' "${todo_files[@]}" | nl
    echo

    # Procurar por conteúdo similar
    echo "Análise de similaridade:"
    for i in "${!todo_files[@]}"; do
        for j in "${!todo_files[@]}"; do
            if [ "$i" -lt "$j" ] && [ -f "${todo_files[$i]}" ] && [ -f "${todo_files[$j]}" ]; then
                local similarity
                similarity=$(diff -u "${todo_files[$i]}" "${todo_files[$j]}" 2>/dev/null | wc -l 2>/dev/null || echo "0")
                if [ "$similarity" -gt 0 ]; then
                    echo "Similaridade entre $(basename "${todo_files[$i]}") e $(basename "${todo_files[$j]}"): $similarity linhas diferentes"
                fi
            fi
        done
    done
}

# Limpar arquivos duplicados
cleanup_duplicates() {
    subsection "🧹 Limpando Arquivos Duplicados"

    warn "⚠️  Esta operação irá remover arquivos TODO duplicados"
    echo "Arquivos que serão mantidos:"
    echo "- TODO_MASTER.md (consolidado)"
    echo "- TODO.md (histórico)"
    echo

    if confirm_operation "Continuar com a limpeza?"; then
        local todo_files
        mapfile -t todo_files < <(find_todo_files)

        local removed=0
        for file in "${todo_files[@]}"; do
            local filename=$(basename "$file")
            # Não remover TODO_MASTER.md, TODO.md e este script
            if [[ "$filename" != "TODO_MASTER.md" && "$filename" != "TODO.md" && "$filename" != "$(basename "$0")" ]]; then
                if [ -f "$file" ]; then
                    rm -f "$file"
                    log "Removido: $filename"
                    ((removed++))
                fi
            fi
        done

        success "✅ $removed arquivos duplicados removidos"
    else
        warn "Limpeza cancelada"
    fi
}

# --- Funções de Relatório ---

# Gerar relatório final
generate_report() {
    subsection "📊 Gerando Relatório Final"

    local todo_files_before
    local todo_files_after

    todo_files_before=$(find "$BACKUP_DIR" -name "*TODO*" -type f 2>/dev/null | wc -l)
    todo_files_after=$(find_todo_files | wc -l)

    cat > "$ANALYSIS_FILE" << EOF
# 📊 ANÁLISE DE CONSOLIDAÇÃO DE TODOS

**Data:** $(date '+%Y-%m-%d %H:%M:%S')

## 📈 RESULTADOS

### Antes da Consolidação
- Arquivos TODO: $todo_files_before
- Localização: $BACKUP_DIR

### Após a Consolidação
- Arquivos TODO: $todo_files_after
- Arquivo principal: TODO_MASTER.md

### Estatísticas
- Redução: $((todo_files_before - todo_files_after)) arquivos
- Eficiência: $(( (todo_files_before - todo_files_after) * 100 / todo_files_before ))% de redução

## 📋 ARQUIVOS CONSERVADOS

### Essenciais
- \`TODO_MASTER.md\` - Consolidado principal
- \`TODO.md\` - Histórico e referência

### Removidos
$(ls -1 "$BACKUP_DIR" 2>/dev/null | grep -v "^$" | sed 's/^/- /' || echo "- Nenhum arquivo removido")

## ✅ PRÓXIMAS AÇÕES RECOMENDADAS

1. **Revisar TODO_MASTER.md** para validar tarefas
2. **Atualizar status** das tarefas concluídas
3. **Adicionar novas tarefas** conforme necessário
4. **Manter backup** em $BACKUP_DIR

## 🔍 VERIFICAÇÃO DE QUALIDADE

- [ ] Todas as tarefas foram migradas?
- [ ] Não há tarefas duplicadas?
- [ ] Informações críticas foram preservadas?
- [ ] Estrutura está clara e organizada?

---
*Relatório gerado automaticamente por $(basename "$0")*
EOF

    success "✅ Relatório criado: $ANALYSIS_FILE"
}

# --- Menu Interativo ---

show_menu() {
    echo
    echo "🧹 SISTEMA DE CONSOLIDAÇÃO DE TODOS"
    echo
    echo "1) 🔍 Analisar Arquivos TODO Existentes"
    echo "2) 💾 Criar Backup de Segurança"
    echo "3) 🔄 Consolidar Todos os TODOs"
    echo "4) 🧹 Limpar Arquivos Duplicados"
    echo "5) 📊 Gerar Relatório Final"
    echo "6) 📋 Mostrar TODO_MASTER Consolidado"
    echo "0) ❌ Sair"
    echo
}

# Mostrar análise dos TODOs
show_analysis() {
    subsection "🔍 Análise dos Arquivos TODO"

    local todo_files
    mapfile -t todo_files < <(find_todo_files)

    echo "Total de arquivos encontrados: ${#todo_files[@]}"
    echo

    for file in "${todo_files[@]}"; do
        if [ -f "$file" ]; then
            analyze_todo_file "$file"
        fi
    done
}

# Mostrar TODO_MASTER
show_master_todo() {
    subsection "📋 TODO_MASTER Consolidado"

    if [ -f "$MASTER_TODO" ]; then
        echo "Conteúdo do TODO_MASTER.md:"
        echo
        cat "$MASTER_TODO"
    else
        warn "TODO_MASTER.md não encontrado. Execute a consolidação primeiro."
    fi
}

# --- Script Principal ---

main() {
    while true; do
        show_menu
        read -p "Digite sua opção: " choice

        case $choice in
            1) show_analysis ;;
            2) backup_todos ;;
            3) create_master_todo ;;
            4) cleanup_duplicates ;;
            5) generate_report ;;
            6) show_master_todo ;;
            0)
                success "Sistema de consolidação finalizado!"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
    done
}

# Executar script principal
main "$@"
