#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Documentation Consolidation Script
# Consolida documentação duplicada e organiza arquivos
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por consolidar documentação duplicada, organizar arquivos
#   em estrutura hierárquica e criar sistema de referência para o projeto Cluster AI.
#   Remove duplicatas, organiza READMEs e cria estrutura de documentação consolidada.
#
# Uso:
#   ./scripts/management/doc_consolidator.sh [comando]
#
# Dependências:
#   - bash
#   - find, sort, uniq, grep, wc
#   - mkdir, cp, rm
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
CONSOLIDATED_DIR="$DOCS_DIR/consolidated"

# Funções utilitárias
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

# Função para encontrar arquivos duplicados
find_duplicates() {
    log_info "Procurando arquivos duplicados..."

    # Criar lista de arquivos únicos com contagem
    find "$DOCS_DIR" -name "*.md" -exec basename {} \; | sort | uniq -c | sort -nr > /tmp/doc_duplicates.txt

    # Mostrar arquivos com múltiplas cópias
    echo "Arquivos com múltiplas cópias encontradas:"
    grep -E "^\s*[2-9]" /tmp/doc_duplicates.txt | while read count file; do
        echo "  $file: $count cópias"
    done
}

# Função para consolidar arquivos duplicados
consolidate_duplicates() {
    log_info "Consolidando arquivos duplicados..."

    local consolidated_count=0
    local removed_count=0

    # Para cada arquivo que aparece múltiplas vezes
    grep -E "^\s*[2-9]" /tmp/doc_duplicates.txt | while read count file; do
        log_info "Processando $file ($count cópias)"

        # Encontrar todas as localizações do arquivo
        find "$DOCS_DIR" -name "$file" -type f > /tmp/file_locations.txt

        # Manter apenas a versão mais organizada (preferir organized/ primeiro)
        local keep_file=""
        local remove_files=()

        while IFS= read -r location; do
            if [[ "$location" == *"/organized/"* ]]; then
                keep_file="$location"
                break
            fi
        done < /tmp/file_locations.txt

        # Se não encontrou na organized, manter a primeira ocorrência
        if [ -z "$keep_file" ]; then
            keep_file=$(head -1 /tmp/file_locations.txt)
        fi

        # Copiar para diretório consolidado
        local consolidated_file="$CONSOLIDATED_DIR/prompts/$file"
        if [ ! -f "$consolidated_file" ]; then
            mkdir -p "$(dirname "$consolidated_file")"
            cp "$keep_file" "$consolidated_file"
            log_success "Consolidado: $file"
            ((consolidated_count++))
        fi

        # Remover cópias desnecessárias
        while IFS= read -r location; do
            if [ "$location" != "$keep_file" ] && [ "$location" != "$consolidated_file" ]; then
                rm "$location"
                log_info "Removido duplicado: $location"
                ((removed_count++))
            fi
        done < /tmp/file_locations.txt
    done

    log_success "Consolidação concluída! $consolidated_count arquivos consolidados, $removed_count duplicados removidos."
}

# Função para organizar READMEs
organize_readmes() {
    log_info "Organizando arquivos README..."

    # Encontrar todos os READMEs
    find "$DOCS_DIR" -name "README*.md" -type f > /tmp/readme_files.txt

    local readme_count=$(wc -l < /tmp/readme_files.txt)
    if [ $readme_count -gt 1 ]; then
        log_info "Encontrados $readme_count arquivos README"

        # Manter apenas o principal na raiz docs/
        local main_readme="$DOCS_DIR/README.md"
        local consolidated_readme="$CONSOLIDATED_DIR/README.md"

        if [ -f "$main_readme" ]; then
            cp "$main_readme" "$consolidated_readme"
            log_success "README principal consolidado"
        fi

        # Remover outros READMEs duplicados
        while IFS= read -r readme_file; do
            if [ "$readme_file" != "$main_readme" ]; then
                rm "$readme_file"
                log_info "README duplicado removido: $readme_file"
            fi
        done < /tmp/readme_files.txt
    else
        log_info "Apenas um README encontrado, nenhuma ação necessária"
    fi
}

# Função para criar estrutura de referência
create_reference_structure() {
    log_info "Criando estrutura de referência..."

    # Criar arquivo de índice consolidado
    cat > "$CONSOLIDATED_DIR/README.md" << 'EOF'
# 📚 Documentação Consolidada - Cluster AI

Esta é a documentação consolidada e organizada do projeto Cluster AI.

## 📁 Estrutura da Documentação

### 🎯 Guias
- **Guides**: Guias práticos e tutoriais
- **Manuals**: Manuais detalhados de instalação e configuração
- **Prompts**: Prompts especializados para diferentes perfis de usuário

### 📖 Categorias

#### 🚀 Guias Rápidos
- [Quick Start](guides/quick-start.md)
- [Installation Guide](manuals/INSTALACAO.md)
- [Troubleshooting](guides/TROUBLESHOOTING.md)

#### 🔧 Manuais Técnicos
- [Configuration Manual](manuals/CONFIGURACAO.md)
- [Backup Manual](manuals/BACKUP.md)
- [Android Worker Guide](manuals/ANDROID.md)

#### 💡 Prompts Especializados
- [DevOps Prompts](prompts/prompts_devops_cluster_ai.md)
- [Security Prompts](prompts/prompts_seguranca_cluster_ai.md)
- [Business Prompts](prompts/prompts_negocios_cluster_ai.md)

## 🔍 Como Usar

1. **Para iniciantes**: Comece com os guias rápidos
2. **Para administradores**: Consulte os manuais técnicos
3. **Para usuários avançados**: Use os prompts especializados

## 📝 Contribuição

Para contribuir com a documentação:
1. Adicione novos arquivos na pasta apropriada
2. Atualize este índice
3. Mantenha a consistência de formato

---

*Documentação gerada automaticamente pelo sistema de consolidação*
EOF

    log_success "Estrutura de referência criada"
}

# Função para mostrar estatísticas
show_consolidation_stats() {
    log_info "Estatísticas da consolidação:"

    echo "Diretório consolidado: $CONSOLIDATED_DIR"
    echo "Tamanho total: $(du -sh "$CONSOLIDATED_DIR" 2>/dev/null | cut -f1)"

    echo -e "\nPor categoria:"
    for dir in "$CONSOLIDATED_DIR"/*/; do
        if [ -d "$dir" ]; then
            local dir_name=$(basename "$dir")
            local count=$(find "$dir" -name "*.md" | wc -l)
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "  $dir_name: $count arquivos ($size)"
        fi
    done

    local total_files=$(find "$CONSOLIDATED_DIR" -name "*.md" | wc -l)
    echo -e "\nTotal de arquivos consolidados: $total_files"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    case "${1:-help}" in
        "find")
            find_duplicates
            ;;
        "consolidate")
            find_duplicates
            consolidate_duplicates
            organize_readmes
            create_reference_structure
            ;;
        "stats")
            show_consolidation_stats
            ;;
        "all")
            find_duplicates
            consolidate_duplicates
            organize_readmes
            create_reference_structure
            show_consolidation_stats
            ;;
        "help"|*)
            echo "Cluster AI - Documentation Consolidation Script"
            echo ""
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  find        - Encontra arquivos duplicados"
            echo "  consolidate - Consolida arquivos duplicados"
            echo "  stats       - Mostra estatísticas da consolidação"
            echo "  all         - Executa consolidação completa"
            echo "  help        - Mostra esta mensagem de ajuda"
            echo ""
            echo "Exemplo:"
            echo "  $0 all"
            ;;
    esac
}

# Executar função principal
main "$@"
