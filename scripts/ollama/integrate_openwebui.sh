#!/bin/bash

# 🔗 Integração OpenWebUI - Cluster AI
# Script para automatizar a integração das personas do Cluster AI no OpenWebUI

set -e

# --- Carregar Funções Comuns ---
PROJECT_ROOT=$(pwd)
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Definição de Caminhos ---
PERSONAS_FILE="${PROJECT_ROOT}/docs/guides/prompts/openwebui_personas.json"
OPENWEBUI_CONFIG_DIR="${HOME}/.open-webui"
BACKUP_DIR="${PROJECT_ROOT}/backups/openwebui"

# --- Verificar Dependências ---
check_dependencies() {
    subsection "Verificando dependências"

    # Verificar se jq está instalado
    if ! command_exists jq; then
        warn "jq não encontrado. Instalando..."
        if command_exists apt; then
            sudo apt update && sudo apt install -y jq
        elif command_exists yum; then
            sudo yum install -y jq
        elif command_exists dnf; then
            sudo dnf install -y jq
        else
            error "Não foi possível instalar jq automaticamente."
            info "Instale jq manualmente: https://stedolan.github.io/jq/"
            exit 1
        fi
        success "jq instalado."
    else
        success "jq encontrado."
    fi

    # Verificar arquivo de personas
    if [ ! -f "$PERSONAS_FILE" ]; then
        error "Arquivo de personas não encontrado: $PERSONAS_FILE"
        exit 1
    fi
    success "Arquivo de personas encontrado."
}

# --- Verificar OpenWebUI ---
check_openwebui() {
    subsection "Verificando OpenWebUI"

    # Verificar se OpenWebUI está rodando
    local openwebui_port="${OPENWEBUI_PORT:-3000}"
    if is_port_open "$openwebui_port"; then
        success "OpenWebUI está rodando na porta $openwebui_port"
    else
        warn "OpenWebUI não está rodando na porta $openwebui_port"
        info "Certifique-se de que o OpenWebUI está iniciado."
        info "Execute: docker start open-webui (ou o comando apropriado)"
        exit 1
    fi

    # Verificar se podemos acessar a API
    if curl -s "http://localhost:$openwebui_port/api/v1/auths" >/dev/null 2>&1; then
        success "API do OpenWebUI acessível."
    else
        warn "API do OpenWebUI não acessível."
        info "Verifique se o OpenWebUI está configurado corretamente."
    fi
}

# --- Fazer Backup ---
create_backup() {
    subsection "Criando backup"

    mkdir -p "$BACKUP_DIR"

    local backup_file="$BACKUP_DIR/personas_backup_$(date +%Y%m%d_%H%M%S).json"

    # Tentar fazer backup das personas existentes
    local openwebui_port="${OPENWEBUI_PORT:-3000}"
    if curl -s "http://localhost:$openwebui_port/api/v1/personas" -H "Content-Type: application/json" > "$backup_file" 2>/dev/null; then
        success "Backup das personas existentes criado: $backup_file"
    else
        warn "Não foi possível fazer backup das personas existentes."
        info "Continuando sem backup..."
    fi
}

# --- Importar Personas ---
import_personas() {
    subsection "Importando personas do Cluster AI"

    local openwebui_port="${OPENWEBUI_PORT:-3000}"
    local api_url="http://localhost:$openwebui_port/api/v1/personas"

    # Ler personas do arquivo JSON
    local personas_count=$(jq '.personas | length' "$PERSONAS_FILE")

    if [ "$personas_count" -eq 0 ]; then
        error "Nenhuma persona encontrada no arquivo."
        exit 1
    fi

    log "Encontradas $personas_count personas para importar."

    # Importar cada persona
    local imported=0
    local failed=0

    for i in $(seq 0 $(($personas_count - 1))); do
        local persona_name=$(jq -r ".personas[$i].name" "$PERSONAS_FILE")

        log "Importando persona: $persona_name"

        # Extrair dados da persona
        local persona_data=$(jq ".personas[$i]" "$PERSONAS_FILE")

        # Fazer POST para a API
        if curl -s -X POST "$api_url" \
            -H "Content-Type: application/json" \
            -d "$persona_data" >/dev/null 2>&1; then
            success "Persona '$persona_name' importada com sucesso."
            ((imported++))
        else
            error "Falha ao importar persona '$persona_name'."
            ((failed++))
        fi
    done

    echo
    success "Importação concluída: $imported personas importadas, $failed falhas."
}

# --- Importar Templates ---
import_templates() {
    subsection "Importando templates"

    local openwebui_port="${OPENWEBUI_PORT:-3000}"
    local api_url="http://localhost:$openwebui_port/api/v1/templates"

    # Verificar se existem templates
    local templates_count=$(jq '.templates | length' "$PERSONAS_FILE" 2>/dev/null || echo 0)

    if [ "$templates_count" -eq 0 ]; then
        warn "Nenhum template encontrado no arquivo."
        return 0
    fi

    log "Encontrados $templates_count templates para importar."

    # Importar cada template
    local imported=0
    local failed=0

    for i in $(seq 0 $(($templates_count - 1))); do
        local template_name=$(jq -r ".templates[$i].name" "$PERSONAS_FILE")

        log "Importando template: $template_name"

        # Extrair dados do template
        local template_data=$(jq ".templates[$i]" "$PERSONAS_FILE")

        # Fazer POST para a API
        if curl -s -X POST "$api_url" \
            -H "Content-Type: application/json" \
            -d "$template_data" >/dev/null 2>&1; then
            success "Template '$template_name' importado com sucesso."
            ((imported++))
        else
            error "Falha ao importar template '$template_name'."
            ((failed++))
        fi
    done

    echo
    success "Importação de templates concluída: $imported importados, $failed falhas."
}

# --- Verificar Importação ---
verify_import() {
    subsection "Verificando importação"

    local openwebui_port="${OPENWEBUI_PORT:-3000}"
    local api_url="http://localhost:$openwebui_port/api/v1/personas"

    # Buscar personas importadas
    local response=$(curl -s "$api_url" 2>/dev/null)

    if [ -z "$response" ]; then
        warn "Não foi possível verificar as personas importadas."
        return 1
    fi

    # Contar personas relacionadas ao Cluster AI
    local cluster_personas=$(echo "$response" | jq '[.[] | select(.name | contains("Cluster-AI"))] | length' 2>/dev/null || echo 0)

    if [ "$cluster_personas" -gt 0 ]; then
        success "Encontradas $cluster_personas personas do Cluster AI no OpenWebUI."
    else
        warn "Nenhuma persona do Cluster AI encontrada no OpenWebUI."
        info "Verifique se a importação foi bem-sucedida."
    fi
}

# --- Mostrar Instruções ---
show_instructions() {
    section "Integração OpenWebUI - Cluster AI"

    echo "🎉 Integração concluída com sucesso!"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Acesse o OpenWebUI em: http://localhost:${OPENWEBUI_PORT:-3000}"
    echo "2. Vá para a seção 'Personas' no painel lateral"
    echo "3. Você deve ver as novas personas do Cluster AI disponíveis"
    echo "4. Selecione uma persona e comece a usar!"
    echo
    echo "🤖 PERSONAS DISPONÍVEIS:"
    jq -r '.personas[].name' "$PERSONAS_FILE" 2>/dev/null | while read -r name; do
        echo "   • $name"
    done
    echo
    echo "📚 PARA MAIS INFORMAÇÕES:"
    echo "   Consulte: docs/guides/prompts/openwebui_integration.md"
    echo
}

# --- Script Principal ---
main() {
    section "Integração OpenWebUI - Cluster AI"

    warn "Este script irá importar as personas do Cluster AI para o OpenWebUI."
    echo

    if confirm_operation "Continuar com a integração?"; then
        check_dependencies
        echo
        check_openwebui
        echo
        create_backup
        echo
        import_personas
        echo
        import_templates
        echo
        verify_import
        echo
        show_instructions
    else
        error "Integração cancelada pelo usuário."
        exit 1
    fi
}

# Executa o script principal
main
