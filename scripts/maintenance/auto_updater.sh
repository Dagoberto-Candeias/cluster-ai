#!/bin/bash
# =============================================================================
# Sistema de Atualização Automática - Cluster AI
# =============================================================================
# Aplica atualizações de forma segura com rollback automático
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: auto_updater.sh
# =============================================================================

set -euo pipefail

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/../lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/../lib/common.sh"

# Carregar configuração
UPDATE_CONFIG="${PROJECT_ROOT}/config/update.conf"
if [ ! -f "$UPDATE_CONFIG" ]; then
    error "Arquivo de configuração não encontrado: $UPDATE_CONFIG"
    exit 1
fi

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
UPDATE_LOG="${LOG_DIR}/auto_updater.log"
BACKUP_DIR="${PROJECT_ROOT}/backups/auto_update"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

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
    esac
}

# Função para obter configuração
get_update_config() {
    get_config_value "$1" "$2" "$UPDATE_CONFIG" "$3"
}

# Função para verificar se é seguro atualizar
check_update_safety() {
    log_update "INFO" "Verificando segurança para atualização..."

    # Verificar se há containers críticos rodando
    if command_exists docker; then
        local critical_containers=("open-webui" "nginx")
        for container in "${critical_containers[@]}"; do
            if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
                log_update "WARN" "Container crítico rodando: $container"
                if [[ "$(get_update_config "GENERAL" "AUTO_ROLLBACK")" != "true" ]]; then
                    log_update "ERROR" "Container crítico rodando e rollback não habilitado"
                    return 1
                fi
            fi
        done
    fi

    # Verificar espaço em disco
    local available_space
    available_space=$(df . | tail -1 | awk '{print $4}')
    if [[ $available_space -lt 1048576 ]]; then # Menos de 1GB
        log_update "ERROR" "Espaço insuficiente em disco: ${available_space}KB"
        return 1
    fi

    log_update "INFO" "Verificação de segurança concluída"
    return 0
}

# Função para fazer backup antes da atualização
pre_update_backup() {
    log_update "INFO" "Criando backup antes da atualização..."

    if [[ "$(get_update_config "GENERAL" "AUTO_BACKUP")" == "true" ]]; then
        if bash "${SCRIPT_DIR}/../backup_manager.sh" create pre_update; then
            log_update "INFO" "Backup pré-atualização criado com sucesso"
            return 0
        else
            log_update "ERROR" "Falha ao criar backup pré-atualização"
            return 1
        fi
    else
        log_update "DEBUG" "Backup automático desabilitado"
        return 0
    fi
}

# Função para atualizar Git
update_git() {
    log_update "INFO" "Atualizando repositório Git..."

    # Verificar se há mudanças locais não commitadas
    if [[ -n "$(git status --porcelain)" ]]; then
        log_update "WARN" "Há mudanças locais não commitadas"
        if confirm_operation "Deseja continuar mesmo com mudanças locais?"; then
            log_update "INFO" "Fazendo stash das mudanças locais"
            git stash push -m "auto-stash-$(date +%Y%m%d_%H%M%S)"
        else
            log_update "INFO" "Pulando atualização Git"
            return 0
        fi
    fi

    # Fazer pull das atualizações
    if git pull origin "$(git rev-parse --abbrev-ref HEAD)"; then
        log_update "INFO" "Repositório Git atualizado com sucesso"

        # Verificar se há mudanças significativas
        if [[ -n "$(git log --oneline -10)" ]]; then
            log_update "INFO" "Novos commits aplicados:"
            git log --oneline -5 | while read -r line; do
                log_update "INFO" "  $line"
            done
        fi

        return 0
    else
        log_update "ERROR" "Falha ao atualizar repositório Git"
        return 1
    fi
}

# Função para atualizar containers Docker
update_docker_containers() {
    local container_name="$1"
    log_update "INFO" "Atualizando container Docker: $container_name"

    if ! command_exists docker; then
        log_update "ERROR" "Docker não está instalado"
        return 1
    fi

    # Verificar se container existe
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_update "WARN" "Container não encontrado: $container_name"
        return 0
    fi

    # Parar container
    log_update "INFO" "Parando container: $container_name"
    if docker stop "$container_name" 2>/dev/null; then
        log_update "DEBUG" "Container parado: $container_name"
    fi

    # Remover container
    log_update "INFO" "Removendo container: $container_name"
    if docker rm "$container_name" 2>/dev/null; then
        log_update "DEBUG" "Container removido: $container_name"
    fi

    # Fazer pull da nova imagem
    local current_image
    current_image=$(docker ps -a --filter "name=$container_name" --format '{{.Image}}' | head -1)

    if [[ -n "$current_image" ]]; then
        log_update "INFO" "Baixando nova imagem: $current_image"
        if docker pull "$current_image"; then
            log_update "INFO" "Nova imagem baixada com sucesso"

            # Recriar container
            log_update "INFO" "Recriando container: $container_name"
            if docker run -d --name "$container_name" --restart unless-stopped "$current_image"; then
                log_update "INFO" "Container recriado com sucesso: $container_name"
                return 0
            else
                log_update "ERROR" "Falha ao recriar container: $container_name"
                return 1
            fi
        else
            log_update "ERROR" "Falha ao baixar nova imagem: $current_image"
            return 1
        fi
    else
        log_update "WARN" "Não foi possível obter imagem do container: $container_name"
        return 1
    fi
}

# Função para atualizar sistema
update_system() {
    log_update "INFO" "Atualizando sistema operacional..."

    local pm
    pm=$(get_update_config "SYSTEM" "PACKAGE_MANAGER")

    if [[ "$pm" == "auto" ]]; then
        pm=$(detect_package_manager)
    fi

    if [[ -z "$pm" ]]; then
        log_update "ERROR" "Gerenciador de pacotes não detectado"
        return 1
    fi

    case "$pm" in
        "apt-get")
            log_update "INFO" "Atualizando lista de pacotes..."
            if sudo apt-get update -qq; then
                log_update "INFO" "Lista de pacotes atualizada"

                log_update "INFO" "Aplicando atualizações..."
                if sudo apt-get upgrade -y -qq; then
                    log_update "INFO" "Sistema atualizado com sucesso"
                    return 0
                else
                    log_update "ERROR" "Falha ao aplicar atualizações do sistema"
                    return 1
                fi
            else
                log_update "ERROR" "Falha ao atualizar lista de pacotes"
                return 1
            fi
            ;;
        "dnf"|"yum")
            log_update "INFO" "Aplicando atualizações..."
            if sudo dnf upgrade -y -q; then
                log_update "INFO" "Sistema atualizado com sucesso"
                return 0
            else
                log_update "ERROR" "Falha ao aplicar atualizações do sistema"
                return 1
            fi
            ;;
        "pacman")
            log_update "INFO" "Aplicando atualizações..."
            if sudo pacman -Syu --noconfirm; then
                log_update "INFO" "Sistema atualizado com sucesso"
                return 0
            else
                log_update "ERROR" "Falha ao aplicar atualizações do sistema"
                return 1
            fi
            ;;
        *)
            log_update "ERROR" "Gerenciador de pacotes não suportado: $pm"
            return 1
            ;;
    esac
}

# Função para atualizar modelos
update_models() {
    local model_name="$1"
    log_update "INFO" "Atualizando modelo: $model_name"

    if ! command_exists ollama; then
        log_update "ERROR" "Ollama não está instalado"
        return 1
    fi

    # Remover modelo antigo
    log_update "INFO" "Removendo modelo antigo: $model_name"
    if ollama rm "$model_name" 2>/dev/null; then
        log_update "DEBUG" "Modelo antigo removido: $model_name"
    fi

    # Baixar nova versão
    log_update "INFO" "Baixando nova versão do modelo: $model_name"
    if ollama pull "$model_name"; then
        log_update "INFO" "Modelo atualizado com sucesso: $model_name"
        return 0
    else
        log_update "ERROR" "Falha ao atualizar modelo: $model_name"
        return 1
    fi
}

# Função para rollback
rollback_update() {
    local update_type="$1"
    local update_value="$2"

    log_update "WARN" "Iniciando rollback para: $update_type:$update_value"

    case "$update_type" in
        "git")
            log_update "INFO" "Fazendo rollback do Git..."
            if git reset --hard HEAD~1 2>/dev/null; then
                log_update "INFO" "Rollback do Git concluído"
                return 0
            else
                log_update "ERROR" "Falha no rollback do Git"
                return 1
            fi
            ;;
        "docker")
            log_update "INFO" "Fazendo rollback do container Docker..."
            # TODO: Implementar rollback específico para Docker
            log_update "WARN" "Rollback de Docker não implementado"
            return 1
            ;;
        "system")
            log_update "INFO" "Fazendo rollback do sistema..."
            # TODO: Implementar rollback específico para sistema
            log_update "WARN" "Rollback de sistema não implementado"
            return 1
            ;;
        "model")
            log_update "INFO" "Fazendo rollback do modelo..."
            # TODO: Implementar rollback específico para modelos
            log_update "WARN" "Rollback de modelos não implementado"
            return 1
            ;;
        *)
            log_update "ERROR" "Tipo de rollback não suportado: $update_type"
            return 1
            ;;
    esac
}

# Função para verificar integridade após atualização
check_integrity() {
    log_update "INFO" "Verificando integridade após atualização..."

    if [[ "$(get_update_config "ADVANCED" "INTEGRITY_CHECK_ENABLED")" != "true" ]]; then
        log_update "DEBUG" "Verificação de integridade desabilitada"
        return 0
    fi

    # Verificar conectividade
    if [[ "$(get_update_config "ADVANCED" "CONNECTIVITY_TEST_ENABLED")" == "true" ]]; then
        local test_urls
        IFS=',' read -ra test_urls <<< "$(get_update_config "ADVANCED" "CONNECTIVITY_TEST_URLS")"

        for url in "${test_urls[@]}"; do
            if curl -s --connect-timeout 10 "$url" >/dev/null 2>&1; then
                log_update "INFO" "Teste de conectividade OK: $url"
            else
                log_update "ERROR" "Falha no teste de conectividade: $url"
                return 1
            fi
        done
    fi

    # Verificar serviços críticos
    if command_exists docker; then
        local critical_containers=("open-webui")
        for container in "${critical_containers[@]}"; do
            if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
                log_update "INFO" "Container crítico OK: $container"
            else
                log_update "ERROR" "Container crítico não está rodando: $container"
                return 1
            fi
        done
    fi

    log_update "INFO" "Verificação de integridade concluída com sucesso"
    return 0
}

# Função principal
main() {
    section "Sistema de Atualização Automática - Cluster AI"

    # Verificar argumentos
    if [[ $# -eq 0 ]]; then
        error "Nenhum componente especificado para atualização"
        echo "Uso: $0 <componente1> [componente2] ..."
        echo "Componentes disponíveis: git, docker:<container>, system, model:<nome>"
        exit 1
    fi

    log_update "INFO" "Iniciando processo de atualização..."

    # Verificar segurança
    if ! check_update_safety; then
        error "Verificação de segurança falhou"
        exit 1
    fi

    # Fazer backup
    if ! pre_update_backup; then
        error "Falha no backup pré-atualização"
        exit 1
    fi

    local update_success=true
    local failed_updates=()

    # Processar cada componente
    for component in "$@"; do
        IFS=':' read -r update_type update_value <<< "$component"

        log_update "INFO" "Processando atualização: $update_type:$update_value"

        case "$update_type" in
            "git")
                if update_git; then
                    log_update "INFO" "Atualização Git concluída com sucesso"
                else
                    log_update "ERROR" "Falha na atualização Git"
                    update_success=false
                    failed_updates+=("$component")
                fi
                ;;
            "docker")
                if update_docker_containers "$update_value"; then
                    log_update "INFO" "Atualização Docker concluída com sucesso"
                else
                    log_update "ERROR" "Falha na atualização Docker"
                    update_success=false
                    failed_updates+=("$component")
                fi
                ;;
            "system")
                if update_system; then
                    log_update "INFO" "Atualização do sistema concluída com sucesso"
                else
                    log_update "ERROR" "Falha na atualização do sistema"
                    update_success=false
                    failed_updates+=("$component")
                fi
                ;;
            "model")
                if update_models "$update_value"; then
                    log_update "INFO" "Atualização do modelo concluída com sucesso"
                else
                    log_update "ERROR" "Falha na atualização do modelo"
                    update_success=false
                    failed_updates+=("$component")
                fi
                ;;
            *)
                log_update "ERROR" "Tipo de atualização não suportado: $update_type"
                update_success=false
                failed_updates+=("$component")
                ;;
        esac

        # Pequena pausa entre atualizações
        sleep 2
    done

    # Verificar integridade
    if ! check_integrity; then
        log_update "ERROR" "Verificação de integridade falhou"

        # Rollback se habilitado
        if [[ "$(get_update_config "GENERAL" "AUTO_ROLLBACK")" == "true" ]]; then
            log_update "WARN" "Iniciando rollback devido a falha de integridade"

            for failed_update in "${failed_updates[@]}"; do
                IFS=':' read -r update_type update_value <<< "$failed_update"
                rollback_update "$update_type" "$update_value"
            done
        fi

        error "Atualização falhou - verifique os logs"
        exit 1
    fi

    if [[ "$update_success" == "true" ]]; then
        success "Todas as atualizações aplicadas com sucesso!"
        log_update "INFO" "Processo de atualização concluído com sucesso"
    else
        warn "Algumas atualizações falharam - verifique os logs"
        log_update "WARN" "Processo de atualização concluído com algumas falhas"
        exit 1
    fi
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
