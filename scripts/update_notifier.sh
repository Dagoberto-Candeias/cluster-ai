#!/bin/bash
# =============================================================================
# Sistema de Notificação de Atualizações - Cluster AI
# =============================================================================
# Apresenta atualizações disponíveis e permite ao usuário aprovar/rejeitar
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: update_notifier.sh
# =============================================================================

set -euo pipefail

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/lib/common.sh"

# Carregar configuração
UPDATE_CONFIG="${PROJECT_ROOT}/config/update.conf"
if [ ! -f "$UPDATE_CONFIG" ]; then
    error "Arquivo de configuração não encontrado: $UPDATE_CONFIG"
    exit 1
fi

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
STATUS_FILE="${LOG_DIR}/update_status.json"
NOTIFICATION_LOG="${LOG_DIR}/update_notifications.log"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"

# --- Cores para interface ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Funções ---

# Função para log detalhado
log_notification() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$NOTIFICATION_LOG"

    case "$level" in
        "INFO")
            info "$message" ;;
        "WARN")
            warn "$message" ;;
        "ERROR")
            error "$message" ;;
    esac
}

# Função para obter configuração
get_update_config() {
    get_config_value "$1" "$2" "$UPDATE_CONFIG" "$3"
}

# Função para mostrar cabeçalho
show_header() {
    clear
    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│              🚀 SISTEMA DE AUTO ATUALIZAÇÃO                │${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Função para verificar se há atualizações
check_for_updates() {
    if [[ ! -f "$STATUS_FILE" ]]; then
        log_notification "WARN" "Arquivo de status não encontrado"
        return 1
    fi

    local has_updates
    has_updates=$(jq -r '.updates_available' "$STATUS_FILE" 2>/dev/null || echo "false")

    if [[ "$has_updates" != "true" ]]; then
        log_notification "INFO" "Nenhuma atualização disponível"
        return 1
    fi

    return 0
}

# Função para mostrar atualizações disponíveis
show_updates() {
    show_header

    echo -e "${BOLD}${BLUE}📋 ATUALIZAÇÕES DISPONÍVEIS${NC}"
    echo

    local timestamp
    timestamp=$(jq -r '.timestamp' "$STATUS_FILE" 2>/dev/null || echo "Desconhecido")

    echo -e "${GRAY}Última verificação: $timestamp${NC}"
    echo

    # Mostrar componentes com atualizações
    jq -r '.components[] | "  \(.type): \(.description) - \(if .commits_ahead then "Commits: \(.commits_ahead)" elif .packages then "Pacotes: \(.packages)" elif .container then "Container: \(.container)" elif .name then "Modelo: \(.name)" else "Atualização disponível" end)"' "$STATUS_FILE" 2>/dev/null || echo "  Erro ao ler informações de atualização"

    echo
}

# Função para mostrar detalhes de um componente
show_component_details() {
    local component_type="$1"

    echo -e "${BOLD}${YELLOW}Detalhes do componente: $component_type${NC}"
    echo

    case "$component_type" in
        "git")
            echo -e "${CYAN}Tipo:${NC} Atualização do repositório Git"
            echo -e "${CYAN}Descrição:${NC} Novas funcionalidades, correções de bugs e melhorias de segurança"
            echo -e "${CYAN}Impacto:${NC} Pode incluir mudanças significativas no código"
            echo -e "${CYAN}Tempo estimado:${NC} 2-5 minutos"
            echo -e "${CYAN}Requer restart:${NC} Sim (serviços podem ser reiniciados)"
            ;;
        "docker")
            echo -e "${CYAN}Tipo:${NC} Atualização de container Docker"
            echo -e "${CYAN}Descrição:${NC} Nova versão da imagem do container"
            echo -e "${CYAN}Impacto:${NC} Containers serão recriados com a nova imagem"
            echo -e "${CYAN}Tempo estimado:${NC} 5-10 minutos"
            echo -e "${CYAN}Requer restart:${NC} Sim (containers serão reiniciados)"
            ;;
        "system")
            echo -e "${CYAN}Tipo:${NC} Atualização do sistema operacional"
            echo -e "${CYAN}Descrição:${NC} Pacotes do sistema, correções de segurança"
            echo -e "${CYAN}Impacto:${NC} Requer restart do sistema em alguns casos"
            echo -e "${CYAN}Tempo estimado:${NC} 10-30 minutos"
            echo -e "${CYAN}Requer restart:${NC} Possível (depende dos pacotes)"
            ;;
        "model")
            echo -e "${CYAN}Tipo:${NC} Atualização de modelo de IA"
            echo -e "${CYAN}Descrição:${NC} Nova versão do modelo com melhorias"
            echo -e "${CYAN}Impacto:${NC} Modelo será baixado novamente"
            echo -e "${CYAN}Tempo estimado:${NC} 5-15 minutos"
            echo -e "${CYAN}Requer restart:${NC} Não"
            ;;
    esac

    echo
}

# Função para obter política de atualização
get_update_policy() {
    local component_type="$1"

    case "$component_type" in
        "git")
            get_update_config "REPOSITORY" "GIT_UPDATE_POLICY" "ask" ;;
        "docker")
            get_update_config "DOCKER" "DOCKER_UPDATE_POLICY" "ask" ;;
        "system")
            get_update_config "SYSTEM" "SYSTEM_UPDATE_POLICY" "ask" ;;
        "model")
            get_update_config "MODELS" "MODELS_UPDATE_POLICY" "ask" ;;
        *)
            echo "ask" ;;
    esac
}

# Função para perguntar sobre atualização
ask_for_update() {
    local component_type="$1"
    local component_name="$2"

    local policy
    policy=$(get_update_policy "$component_type")

    case "$policy" in
        "auto")
            echo -e "${GREEN}✓${NC} ${BOLD}Atualização automática habilitada${NC}"
            return 0 ;;
        "never")
            echo -e "${YELLOW}⚠${NC} ${BOLD}Atualização desabilitada por política${NC}"
            return 1 ;;
        "ask"|*)
            echo -e "${YELLOW}Deseja atualizar ${BOLD}$component_name${NC}?${NC}"
            echo -e "  ${CYAN}1${NC} - Sim, atualizar agora"
            echo -e "  ${CYAN}2${NC} - Não, pular esta atualização"
            echo -e "  ${CYAN}3${NC} - Lembrar mais tarde"
            echo -e "  ${CYAN}4${NC} - Ver detalhes"
            echo

            local choice
            read -p "Escolha uma opção (1-4): " choice

            case "$choice" in
                "1")
                    return 0 ;;
                "2")
                    return 1 ;;
                "3")
                    echo -e "${YELLOW}⏰${NC} Lembrete: execute novamente quando quiser atualizar"
                    return 1 ;;
                "4")
                    show_component_details "$component_type"
                    ask_for_update "$component_type" "$component_name" ;;
                *)
                    echo -e "${RED}✗${NC} Opção inválida"
                    ask_for_update "$component_type" "$component_name" ;;
            esac
            ;;
    esac
}

# Função para processar atualizações
process_updates() {
    show_header

    if ! check_for_updates; then
        echo -e "${GREEN}✓${NC} ${BOLD}Sistema já está atualizado!${NC}"
        echo
        echo -e "${GRAY}Pressione Enter para continuar...${NC}"
        read
        return 0
    fi

    show_updates

    # Obter lista de componentes
    local components
    components=$(jq -r '.components[].type' "$STATUS_FILE" 2>/dev/null || echo "")

    if [[ -z "$components" ]]; then
        error "Erro ao obter lista de componentes"
        return 1
    fi

    local updates_to_apply=()
    local updates_skipped=()

    # Processar cada componente
    while IFS=':' read -r component_type component_value; do
        [[ -z "$component_type" ]] && continue

        local component_name="$component_value"
        if [[ "$component_type" == "git" ]]; then
            component_name="Repositório Git"
        elif [[ "$component_type" == "system" ]]; then
            component_name="Sistema Operacional"
        elif [[ "$component_type" == "model" ]]; then
            component_name="Modelo: $component_value"
        fi

        echo -e "${BOLD}${PURPLE}Processando: $component_name${NC}"
        echo

        if ask_for_update "$component_type" "$component_name"; then
            updates_to_apply+=("$component_type:$component_value")
            echo -e "${GREEN}✓${NC} Marcado para atualização"
        else
            updates_skipped+=("$component_type:$component_value")
            echo -e "${YELLOW}⚠${NC} Pulado"
        fi

        echo
    done <<< "$components"

    # Mostrar resumo
    echo -e "${BOLD}${BLUE}RESUMO${NC}"
    echo

    if [[ ${#updates_to_apply[@]} -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} ${BOLD}Atualizações a aplicar:${NC}"
        for update in "${updates_to_apply[@]}"; do
            IFS=':' read -r comp_type comp_value <<< "$update"
            echo -e "  - $comp_type: $comp_value"
        done
        echo
    fi

    if [[ ${#updates_skipped[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠${NC} ${BOLD}Atualizações puladas:${NC}"
        for update in "${updates_skipped[@]}"; do
            IFS=':' read -r comp_type comp_value <<< "$update"
            echo -e "  - $comp_type: $comp_value"
        done
        echo
    fi

    # Confirmar aplicação
    if [[ ${#updates_to_apply[@]} -gt 0 ]]; then
        if confirm_operation "Deseja aplicar as atualizações selecionadas?"; then
            echo -e "${GREEN}🚀${NC} ${BOLD}Aplicando atualizações...${NC}"
            log_notification "INFO" "Iniciando aplicação de atualizações"

            # Chamar script de atualização
            if bash "${SCRIPT_DIR}/maintenance/auto_updater.sh" "${updates_to_apply[@]}"; then
                success "Atualizações aplicadas com sucesso!"
                log_notification "INFO" "Atualizações aplicadas com sucesso"
            else
                error "Falha ao aplicar atualizações"
                log_notification "ERROR" "Falha ao aplicar atualizações"
                return 1
            fi
        else
            warn "Aplicação de atualizações cancelada pelo usuário"
            log_notification "INFO" "Aplicação de atualizações cancelada pelo usuário"
        fi
    else
        info "Nenhuma atualização selecionada para aplicação"
        log_notification "INFO" "Nenhuma atualização selecionada"
    fi

    echo
    echo -e "${GRAY}Pressione Enter para continuar...${NC}"
    read
}

# Função para modo silencioso (para scripts)
silent_mode() {
    if ! check_for_updates; then
        echo "NO_UPDATES"
        return 0
    fi

    local components
    components=$(jq -r '.components[].type' "$STATUS_FILE" 2>/dev/null || echo "")

    if [[ -z "$components" ]]; then
        echo "ERROR"
        return 1
    fi

    echo "UPDATES_AVAILABLE"
    jq -c '.components[]' "$STATUS_FILE" 2>/dev/null || echo "ERROR"
}

# Função principal
main() {
    # Verificar argumentos
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "--silent"|"-s")
                silent_mode
                return ;;
            "--check"|"-c")
                check_for_updates
                return ;;
            *)
                echo "Uso: $0 [--silent|--check]"
                exit 1 ;;
        esac
    fi

    # Modo interativo
    process_updates
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
