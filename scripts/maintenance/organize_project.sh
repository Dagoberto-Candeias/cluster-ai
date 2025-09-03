#!/bin/bash

# 🗂️ SISTEMA DE ORGANIZAÇÃO DO PROJETO
# Analisa, organiza e identifica documentação desnecessária no GitHub

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
ANALYSIS_DIR="$PROJECT_ROOT/project_analysis"
GITHUB_DOCS_DIR="$PROJECT_ROOT/docs/github_only"
SERVER_DOCS_DIR="$PROJECT_ROOT/docs/server_only"
REPORTS_DIR="$ANALYSIS_DIR/reports"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Funções de Análise ---

# Analisar estrutura atual do projeto
analyze_project_structure() {
    subsection "🔍 Analisando Estrutura Atual do Projeto"

    echo "=== ESTRUTURA DE DIRETÓRIOS ==="
    find "$PROJECT_ROOT" -type d -name ".*" -prune -o -type d -print | sort | while read -r dir; do
        local depth=$(echo "$dir" | tr -cd '/' | wc -c)
        local indent=""
        for ((i=1; i<depth; i++)); do indent+="  "; done

        local dir_name=$(basename "$dir")
        local file_count=$(find "$dir" -maxdepth 1 -type f | wc -l)
        local subdir_count=$(find "$dir" -maxdepth 1 -type d | wc -l)
        ((subdir_count--))  # Remove o próprio diretório

        printf "%s📁 %s (%d arquivos, %d subdirs)\n" "$indent" "$dir_name" "$file_count" "$subdir_count"
    done
    echo

    echo "=== ESTATÍSTICAS GERAIS ==="
    local total_files=$(find "$PROJECT_ROOT" -type f | wc -l)
    local total_dirs=$(find "$PROJECT_ROOT" -type d | wc -l)
    local total_size=$(du -sh "$PROJECT_ROOT" | cut -f1)

    echo "Total de arquivos: $total_files"
    echo "Total de diretórios: $total_dirs"
    echo "Tamanho total: $total_size"
    echo

    echo "=== TIPOS DE ARQUIVO MAIS COMUNS ==="
    find "$PROJECT_ROOT" -type f -name ".*" -prune -o -type f -print | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -10
}

# Analisar arquivos de documentação
analyze_documentation() {
    subsection "📚 Analisando Documentação"

    echo "=== ARQUIVOS DE DOCUMENTAÇÃO ENCONTRADOS ==="

    # Procurar arquivos de documentação
    local doc_files=()
    while IFS= read -r -d '' file; do
        doc_files+=("$file")
    done < <(find "$PROJECT_ROOT" -type f \( -name "*.md" -o -name "*.txt" -o -name "*.rst" -o -name "README*" -o -name "*GUIDE*" -o -name "*MANUAL*" \) -print0)

    printf "Total de arquivos de documentação: %d\n\n" "${#doc_files[@]}"

    for file in "${doc_files[@]}"; do
        local filename=$(basename "$file")
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        local size_kb=$((size / 1024))

        printf "📄 %s (%d KB) - %s\n" "$filename" "$size_kb" "${file#$PROJECT_ROOT/}"
    done
    echo

    echo "=== ANÁLISE DE CONTEÚDO ==="
    echo "Documentação por categoria:"
    echo

    local readme_count=$(find "$PROJECT_ROOT" -name "README*" | wc -l)
    local guide_count=$(find "$PROJECT_ROOT" -name "*GUIDE*" -o -name "*GUIA*" | wc -l)
    local manual_count=$(find "$PROJECT_ROOT" -name "*MANUAL*" | wc -l)
    local todo_count=$(find "$PROJECT_ROOT" -name "*TODO*" | wc -l)
    local test_count=$(find "$PROJECT_ROOT" -name "*TEST*" | wc -l)

    echo "README files: $readme_count"
    echo "Guides/Manuais: $guide_count"
    echo "Manuais específicos: $manual_count"
    echo "TODO files: $todo_count"
    echo "Test plans: $test_count"
}

# Identificar documentação desnecessária no GitHub
identify_github_unnecessary_docs() {
    subsection "🔍 Identificando Documentação Desnecessária no GitHub"

    echo "=== CRITÉRIOS PARA DOCUMENTAÇÃO NO SERVIDOR APENAS ==="
    echo
    echo "1. 📋 Documentação interna de desenvolvimento"
    echo "2. 🔧 Guias de troubleshooting específicos"
    echo "3. 📊 Relatórios de análise e métricas"
    echo "4. 🧪 Documentação de testes detalhados"
    echo "5. 📝 Notas pessoais e TODOs do desenvolvedor"
    echo "6. 🔒 Informações sensíveis (chaves, configurações)"
    echo "7. 📈 Logs e históricos de desenvolvimento"
    echo "8. 🏗️ Documentação de arquitetura interna"
    echo

    # Analisar arquivos candidatos para mover para servidor
    echo "=== ARQUIVOS CANDIDATOS PARA MOVER PARA SERVIDOR ==="

    local server_only_candidates=()

    # Procurar TODOs
    while IFS= read -r -d '' file; do
        server_only_candidates+=("$file")
    done < <(find "$PROJECT_ROOT" -name "*TODO*" -type f -print0 2>/dev/null || true)

    # Procurar arquivos de análise
    while IFS= read -r -d '' file; do
        server_only_candidates+=("$file")
    done < <(find "$PROJECT_ROOT" -name "*ANALISE*" -o -name "*ANALYSIS*" -type f -print0 2>/dev/null || true)

    # Procurar logs e históricos
    while IFS= read -r -d '' file; do
        server_only_candidates+=("$file")
    done < <(find "$PROJECT_ROOT" -name "*.log" -o -name "*LOG*" -type f -print0 2>/dev/null || true)

    # Procurar arquivos de backup
    while IFS= read -r -d '' file; do
        server_only_candidates+=("$file")
    done < <(find "$PROJECT_ROOT" -path "*/backups/*" -type f -print0 2>/dev/null || true)

    # Mostrar candidatos
    for file in "${server_only_candidates[@]}"; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            local size_kb=$((size / 1024))

            printf "📄 %s (%d KB) - %s\n" "$filename" "$size_kb" "${file#$PROJECT_ROOT/}"
        fi
    done

    echo
    printf "Total de candidatos para servidor: %d\n" "${#server_only_candidates[@]}"
}

# --- Funções de Organização ---

# Criar estrutura organizada
create_organized_structure() {
    subsection "📁 Criando Estrutura Organizada"

    echo "=== CRIANDO DIRETÓRIOS ORGANIZADOS ==="

    # Criar diretórios de análise
    mkdir -p "$ANALYSIS_DIR"
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$GITHUB_DOCS_DIR"
    mkdir -p "$SERVER_DOCS_DIR"

    success "✅ Estrutura de análise criada em: $ANALYSIS_DIR"
    success "✅ Documentação GitHub: $GITHUB_DOCS_DIR"
    success "✅ Documentação Servidor: $SERVER_DOCS_DIR"
}

# Mover documentação para servidor
move_docs_to_server() {
    subsection "🚚 Movendo Documentação para Servidor"

    warn "⚠️  Esta operação irá mover arquivos para $SERVER_DOCS_DIR"
    echo "Arquivos que serão movidos:"
    echo "- Todos os arquivos TODO (exceto TODO_MASTER.md)"
    echo "- Arquivos de análise e relatórios"
    echo "- Logs e históricos"
    echo "- Backups de desenvolvimento"
    echo

    if confirm_operation "Continuar com a movimentação?"; then
        local moved_count=0

        # Mover TODOs (exceto o master)
        while IFS= read -r -d '' file; do
            if [[ "$file" != *"/TODO_MASTER.md" ]]; then
                local filename=$(basename "$file")
                mv "$file" "$SERVER_DOCS_DIR/"
                log "Movido: $filename → $SERVER_DOCS_DIR/"
                ((moved_count++))
            fi
        done < <(find "$PROJECT_ROOT" -name "*TODO*" -type f -print0 2>/dev/null || true)

        # Mover arquivos de análise
        while IFS= read -r -d '' file; do
            local filename=$(basename "$file")
            mv "$file" "$SERVER_DOCS_DIR/"
            log "Movido: $filename → $SERVER_DOCS_DIR/"
            ((moved_count++))
        done < <(find "$PROJECT_ROOT" -name "*ANALISE*" -o -name "*ANALYSIS*" -type f -print0 2>/dev/null || true)

        # Mover logs
        while IFS= read -r -d '' file; do
            local filename=$(basename "$file")
            mv "$file" "$SERVER_DOCS_DIR/"
            log "Movido: $filename → $SERVER_DOCS_DIR/"
            ((moved_count++))
        done < <(find "$PROJECT_ROOT" -name "*.log" -o -name "*LOG*" -type f -print0 2>/dev/null || true)

        success "✅ $moved_count arquivos movidos para servidor"
    else
        warn "Movimentação cancelada"
    fi
}

# --- Funções de Relatório ---

# Gerar relatório de organização
generate_organization_report() {
    subsection "📊 Gerando Relatório de Organização"

    local report_file="$REPORTS_DIR/organization_report_$(date +%Y%m%d_%H%M%S).md"

    cat > "$report_file" << EOF
# 📊 RELATÓRIO DE ORGANIZAÇÃO DO PROJETO

**Data:** $(date '+%Y-%m-%d %H:%M:%S')
**Projeto:** Cluster AI
**Script:** $(basename "$0")

## 📈 ESTRUTURA ATUAL

### Estatísticas Gerais
- **Total de arquivos:** $(find "$PROJECT_ROOT" -type f | wc -l)
- **Total de diretórios:** $(find "$PROJECT_ROOT" -type d | wc -l)
- **Tamanho total:** $(du -sh "$PROJECT_ROOT" | cut -f1)

### Documentação
- **Arquivos README:** $(find "$PROJECT_ROOT" -name "README*" | wc -l)
- **Guias e Manuais:** $(find "$PROJECT_ROOT" -name "*GUIDE*" -o -name "*GUIA*" -o -name "*MANUAL*" | wc -l)
- **Arquivos TODO:** $(find "$PROJECT_ROOT" -name "*TODO*" | wc -l)
- **Planos de Teste:** $(find "$PROJECT_ROOT" -name "*TEST*" | wc -l)

## 📁 ESTRUTURA RECOMENDADA

### GitHub (Público)
\`\`\`
docs/
├── guides/           # Guias de usuário
├── manuals/          # Manuais técnicos
├── api/             # Documentação da API
└── README.md        # Documentação principal
\`\`\`

### Servidor (Privado)
\`\`\`
docs/server_only/
├── development/     # Notas de desenvolvimento
├── analysis/        # Relatórios de análise
├── logs/           # Logs do sistema
├── backups/        # Backups de configuração
└── internal/       # Documentação interna
\`\`\`

## ✅ AÇÕES REALIZADAS

### Movidos para Servidor
$(ls -1 "$SERVER_DOCS_DIR" 2>/dev/null | wc -l) arquivos movidos para documentação do servidor:

$(ls -1 "$SERVER_DOCS_DIR" 2>/dev/null | sed 's/^/- /' || echo "- Nenhum arquivo movido")

### Mantidos no GitHub
Documentação essencial para usuários e desenvolvedores externos.

## 🔍 RECOMENDAÇÕES

### Para GitHub
- [ ] Manter apenas documentação pública
- [ ] Focar em guias de instalação e uso
- [ ] Documentar APIs e interfaces
- [ ] Manter exemplos de código

### Para Servidor
- [ ] Armazenar documentação interna
- [ ] Manter logs de desenvolvimento
- [ ] Guardar backups de configuração
- [ ] Documentar arquitetura interna

## 📋 PRÓXIMAS AÇÕES

1. **Revisar documentação movida** para servidor
2. **Atualizar links** que apontavam para arquivos movidos
3. **Criar índice** da documentação do servidor
4. **Configurar backup** automático da documentação do servidor
5. **Documentar processo** de organização para futuras manutenções

---
*Relatório gerado automaticamente por $(basename "$0")*
EOF

    success "✅ Relatório criado: $report_file"
}

# --- Funções de Limpeza ---

# Limpar arquivos temporários
cleanup_temp_files() {
    subsection "🧹 Limpando Arquivos Temporários"

    local cleaned_count=0

    # Remover arquivos .tmp
    while IFS= read -r -d '' file; do
        rm -f "$file"
        log "Removido: $(basename "$file")"
        ((cleaned_count++))
    done < <(find "$PROJECT_ROOT" -name "*.tmp" -type f -print0 2>/dev/null || true)

    # Remover arquivos .bak
    while IFS= read -r -d '' file; do
        rm -f "$file"
        log "Removido: $(basename "$file")"
        ((cleaned_count++))
    done < <(find "$PROJECT_ROOT" -name "*.bak" -type f -print0 2>/dev/null || true)

    # Remover arquivos de cache Python
    while IFS= read -r -d '' file; do
        rm -rf "$file"
        log "Removido: $(basename "$file")"
        ((cleaned_count++))
    done < <(find "$PROJECT_ROOT" -name "__pycache__" -type d -print0 2>/dev/null || true)

    success "✅ $cleaned_count arquivos temporários removidos"
}

# --- Menu Interativo ---

show_menu() {
    echo
    echo "🗂️ SISTEMA DE ORGANIZAÇÃO DO PROJETO"
    echo
    echo "1) 🔍 Analisar Estrutura Atual"
    echo "2) 📚 Analisar Documentação"
    echo "3) 🔍 Identificar Docs Desnecessárias no GitHub"
    echo "4) 📁 Criar Estrutura Organizada"
    echo "5) 🚚 Mover Documentação para Servidor"
    echo "6) 🧹 Limpar Arquivos Temporários"
    echo "7) 📊 Gerar Relatório de Organização"
    echo "8) 📋 Mostrar Estrutura Final"
    echo "0) ❌ Sair"
    echo
}

# Mostrar estrutura final
show_final_structure() {
    subsection "📋 Estrutura Final do Projeto"

    echo "=== ESTRUTURA ATUAL ==="
    find "$PROJECT_ROOT" -type d -name ".*" -prune -o -type d -print | head -20 | sort

    echo
    echo "=== DOCUMENTAÇÃO NO GITHUB ==="
    find "$GITHUB_DOCS_DIR" -type f 2>/dev/null | wc -l || echo "0"
    ls -la "$GITHUB_DOCS_DIR" 2>/dev/null || echo "Diretório vazio"

    echo
    echo "=== DOCUMENTAÇÃO NO SERVIDOR ==="
    find "$SERVER_DOCS_DIR" -type f 2>/dev/null | wc -l || echo "0"
    ls -la "$SERVER_DOCS_DIR" 2>/dev/null || echo "Diretório vazio"
}

# --- Script Principal ---

main() {
    # Criar diretórios necessários
    mkdir -p "$ANALYSIS_DIR" "$REPORTS_DIR" "$GITHUB_DOCS_DIR" "$SERVER_DOCS_DIR"

    while true; do
        show_menu
        read -p "Digite sua opção: " choice

        case $choice in
            1) analyze_project_structure ;;
            2) analyze_documentation ;;
            3) identify_github_unnecessary_docs ;;
            4) create_organized_structure ;;
            5) move_docs_to_server ;;
            6) cleanup_temp_files ;;
            7) generate_organization_report ;;
            8) show_final_structure ;;
            0)
                success "Sistema de organização finalizado!"
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
