#!/bin/bash
# =============================================================================
# Sistema de Verificação de Atualizações - Cluster AI
# =============================================================================
# Verifica automaticamente por atualizações disponíveis em diferentes componentes
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: update_checker.sh
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
UPDATE_LOG="${LOG_DIR}/update_checker.log"
STATUS_FILE="${PROJECT_ROOT}/logs/update_status.json"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"

# --- Funções ---

# Função para log detalhado
log_update() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$UPDATE_LOG"

    case "$level" in
        "INFO")
            info "$message" ;;
        "WARN")
            warn "$message" ;;
        "ERROR")
            error "$message" ;;
        "DEBUG")
            [[ "$(get_config_value "ADVANCED" "DEBUG_MODE" "$UPDATE_CONFIG")" == "true" ]] && log "$message" ;;
    esac
}

# Função para obter configuração
get_update_config() {
    get_config_value "$1" "$2" "$UPDATE_CONFIG" "$3"
}

# Função para verificar conectividade
check_connectivity() {
    local test_urls
    IFS=',' read -ra test_urls <<< "$(get_update_config "ADVANCED" "CONNECTIVITY_TEST_URLS")"

    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 10 "$url" >/dev/null 2>&1; then
            log_update "DEBUG" "Conectividade OK: $url"
            return 0
        fi
    done

    log_update "WARN" "Sem conectividade com URLs de teste"
    return 1
}

# Função para verificar atualizações do Git
check_git_updates() {
    log_update "INFO" "Verificando atualizações do Git..."

    if [[ "$(get_update_config "REPOSITORY" "GIT_CHECK_ENABLED")" != "true" ]]; then
        log_update "DEBUG" "Verificação Git desabilitada"
        return 0
    fi

    if [[ ! -d ".git" ]]; then
        log_update "WARN" "Diretório Git não encontrado"
        return 1
    fi

    # Buscar atualizações remotas
    if git fetch origin 2>/dev/null; then
        local local_commit
        local remote_commit
        local branch

        branch=$(git rev-parse --abbrev-ref HEAD)
        local_commit=$(git rev-parse HEAD)
        remote_commit=$(git rev-parse "origin/$branch")

        if [[ "$local_commit" != "$remote_commit" ]]; then
            local ahead_behind
            ahead_behind=$(git rev-list --count "$local_commit..$remote_commit" 2>/dev/null || echo "0")

            log_update "INFO" "Atualizações Git disponíveis: $ahead_behind commits"
            echo "git:$ahead_behind" >> "$STATUS_FILE.tmp"
            return 0
        else
            log_update "INFO" "Git está atualizado"
            return 0
        fi
    else
        log_update "ERROR" "Falha ao buscar atualizações Git"
        return 1
    fi
}

# Função para verificar atualizações de containers Docker
check_docker_updates() {
    log_update "INFO" "Verificando atualizações de containers Docker..."

    if [[ "$(get_update_config "DOCKER" "DOCKER_CHECK_ENABLED")" != "true" ]]; then
        log_update "DEBUG" "Verificação Docker desabilitada"
        return 0
    fi

    if ! command_exists docker; then
        log_update "WARN" "Docker não está instalado"
        return 1
    fi

    local containers
    IFS=',' read -ra containers <<< "$(get_update_config "DOCKER" "DOCKER_CONTAINERS")"

    local updates_available=0

    for container in "${containers[@]}"; do
        # Verificar se container existe
        if ! docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            log_update "DEBUG" "Container não encontrado: $container"
            continue
        fi

        # Obter imagem atual
        local current_image
        current_image=$(docker ps -a --filter "name=$container" --format '{{.Image}}' | head -1)

        if [[ -z "$current_image" ]]; then
            log_update "WARN" "Não foi possível obter imagem do container: $container"
            continue
        fi

        # Verificar se há versão mais recente
        if docker pull "$current_image" 2>/dev/null; then
            local new_image_id
            local current_image_id

            new_image_id=$(docker inspect "$current_image" --format '{{.Id}}' 2>/dev/null)
            current_image_id=$(docker inspect "$container" --format '{{.Image}}' 2>/dev/null)

            if [[ "$new_image_id" != "$current_image_id" ]]; then
                log_update "INFO" "Atualização disponível para container: $container"
                echo "docker:$container" >> "$STATUS_FILE.tmp"
                ((updates_available++))
            else
                log_update "DEBUG" "Container já está atualizado: $container"
            fi
        else
            log_update "WARN" "Falha ao verificar atualizações para: $container"
        fi
    done

    if [[ $updates_available -gt 0 ]]; then
        log_update "INFO" "Total de containers com atualizações: $updates_available"
        return 0
    else
        log_update "INFO" "Todos os containers Docker estão atualizados"
        return 0
    fi
}

# Função para verificar atualizações do sistema
check_system_updates() {
    log_update "INFO" "Verificando atualizações do sistema..."

    if [[ "$(get_update_config "SYSTEM" "SYSTEM_CHECK_ENABLED")" != "true" ]]; then
        log_update "DEBUG" "Verificação de sistema desabilitada"
        return 0
    fi

    local pm
    pm=$(get_update_config "SYSTEM" "PACKAGE_MANAGER")

    if [[ "$pm" == "auto" ]]; then
        pm=$(detect_package_manager)
    fi

    if [[ -z "$pm" ]]; then
        log_update "WARN" "Gerenciador de pacotes não detectado"
        return 1
    fi

    local update_count=0

    case "$pm" in
        "apt-get")
            # Atualizar lista de pacotes
            if sudo apt-get update -qq 2>/dev/null; then
                update_count=$(apt-get upgrade --dry-run -qq 2>/dev/null | grep -c "^Inst " || echo "0")
                log_update "INFO" "Atualizações de sistema disponíveis: $update_count"
                if [[ $update_count -gt 0 ]]; then
                    echo "system:$update_count" >> "$STATUS_FILE.tmp"
                fi
            else
                log_update "ERROR" "Falha ao atualizar lista de pacotes"
                return 1
            fi
            ;;
        "dnf"|"yum")
            update_count=$(dnf check-update --quiet 2>/dev/null | wc -l || echo "0")
            update_count=$((update_count - 1)) # Subtrair header
            log_update "INFO" "Atualizações de sistema disponíveis: $update_count"
            if [[ $update_count -gt 0 ]]; then
                echo "system:$update_count" >> "$STATUS_FILE.tmp"
            fi
            ;;
        "pacman")
            update_count=$(pacman -Qu --quiet 2>/dev/null | wc -l || echo "0")
            log_update "INFO" "Atualizações de sistema disponíveis: $update_count"
            if [[ $update_count -gt 0 ]]; then
                echo "system:$update_count" >> "$STATUS_FILE.tmp"
            fi
            ;;
        *)
            log_update "WARN" "Gerenciador de pacotes não suportado: $pm"
            return 1
            ;;
    esac

    return 0
}

# Função para verificar atualizações de modelos
check_models_updates() {
    log_update "INFO" "Verificando atualizações de modelos..."

    if [[ "$(get_update_config "MODELS" "MODELS_CHECK_ENABLED")" != "true" ]]; then
        log_update "DEBUG" "Verificação de modelos desabilitada"
        return 0
    fi

    if ! command_exists ollama; then
        log_update "DEBUG" "Ollama não está instalado"
        return 0
    fi

    local models_dir
    models_dir=$(get_update_config "MODELS" "MODELS_DIR")

    # Verificar se há modelos instalados
    if ! ollama list >/dev/null 2>&1; then
        log_update "DEBUG" "Nenhum modelo instalado ou Ollama não está rodando"
        return 0
    fi

    local installed_models
    installed_models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo "")

    if [[ -z "$installed_models" ]]; then
        log_update "DEBUG" "Nenhum modelo encontrado"
        return 0
    fi

    local updates_found=0

    while IFS= read -r model; do
        [[ -z "$model" ]] && continue

        # Verificar se há versão mais recente do modelo
        if ollama pull "$model" 2>/dev/null; then
            log_update "INFO" "Modelo atualizado disponível: $model"
            echo "model:$model" >> "$STATUS_FILE.tmp"
            ((updates_found++))
        fi
    done <<< "$installed_models"

    if [[ $updates_found -gt 0 ]]; then
        log_update "INFO" "Modelos com atualizações disponíveis: $updates_found"
    else
        log_update "INFO" "Todos os modelos estão atualizados"
    fi

    return 0
}

# Função para gerar relatório de status
generate_status_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Criar arquivo de status temporário
    > "$STATUS_FILE.tmp"

    # Executar todas as verificações
    check_git_updates
    check_docker_updates
    check_system_updates
    check_models_updates

    # Verificar se há atualizações
    if [[ -s "$STATUS_FILE.tmp" ]]; then
        # Consolidar status
        {
            echo "{"
            echo "  \"timestamp\": \"$timestamp\","
            echo "  \"updates_available\": true,"
            echo "  \"components\": ["

            local first=true
            while IFS=':' read -r component value; do
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    echo ","
                fi

                case "$component" in
                    "git")
                        echo "    {\"type\": \"git\", \"commits_ahead\": $value, \"description\": \"Atualizações do repositório\"}" ;;
                    "docker")
                        echo "    {\"type\": \"docker\", \"container\": \"$value\", \"description\": \"Container Docker\"}" ;;
                    "system")
                        echo "    {\"type\": \"system\", \"packages\": $value, \"description\": \"Atualizações do sistema\"}" ;;
                    "model")
                        echo "    {\"type\": \"model\", \"name\": \"$value\", \"description\": \"Modelo de IA\"}" ;;
                esac
            done < "$STATUS_FILE.tmp"

            echo "  ]"
            echo "}"
        } > "$STATUS_FILE"

        log_update "INFO" "Relatório de status gerado com atualizações disponíveis"
        return 0
    else
        # Nenhum update disponível
        {
            echo "{"
            echo "  \"timestamp\": \"$timestamp\","
            echo "  \"updates_available\": false,"
            echo "  \"components\": []"
            echo "}"
        } > "$STATUS_FILE"

        log_update "INFO" "Relatório de status gerado - sistema atualizado"
        return 0
    fi
}

# Função principal
main() {
    section "Sistema de Verificação de Atualizações - Cluster AI"

    log_update "INFO" "Iniciando verificação de atualizações..."

    # Verificar conectividade
    if ! check_connectivity; then
        warn "Sem conectividade - pulando verificação de atualizações remotas"
    fi

    # Gerar relatório de status
    if generate_status_report; then
        success "Verificação de atualizações concluída com sucesso"

        # Mostrar resumo se houver atualizações
        if [[ -f "$STATUS_FILE" ]]; then
            local has_updates
            has_updates=$(jq -r '.updates_available' "$STATUS_FILE" 2>/dev/null || echo "false")

            if [[ "$has_updates" == "true" ]]; then
                info "Atualizações disponíveis encontradas!"
                info "Execute './scripts/update_notifier.sh' para ver detalhes e aprovar atualizações"
            else
                info "Sistema está atualizado"
            fi
        fi
    else
        error "Falha na verificação de atualizações"
        return 1
    fi

    log_update "INFO" "Verificação de atualizações finalizada"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
