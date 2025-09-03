#!/bin/bash
# Sistema de Rollback para Instalação do Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
BACKUP_DIR="${PROJECT_ROOT}/backups/rollback"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/rollback_$(date +%Y%m%d_%H%M%S).log"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Criar diretórios necessários
mkdir -p "$BACKUP_DIR" "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# ==================== VARIÁVEIS DE CONTROLE ====================

ROLLBACK_ACTIONS=()
ROLLBACK_SUCCESS=0
ROLLBACK_FAILED=0

# ==================== FUNÇÕES DE ROLLBACK ====================

# Função para registrar ação de rollback
register_rollback_action() {
    local action="$1"
    local description="$2"
    ROLLBACK_ACTIONS+=("$action|$description")
    log "Registrada ação de rollback: $description"
}

# Função para executar rollback de arquivo
rollback_file() {
    local action="$1"
    local target="$2"
    local backup="$3"

    if [ -f "$backup" ]; then
        if cp "$backup" "$target" 2>/dev/null; then
            success "Arquivo restaurado: $target"
            ((ROLLBACK_SUCCESS++))
            return 0
        else
            error "Falha ao restaurar arquivo: $target"
            ((ROLLBACK_FAILED++))
            return 1
        fi
    else
        warn "Backup não encontrado para: $target"
        return 1
    fi
}

# Função para executar rollback de diretório
rollback_directory() {
    local action="$1"
    local target="$2"
    local backup="$3"

    if [ -d "$backup" ]; then
        if cp -r "$backup"/* "$target" 2>/dev/null; then
            success "Diretório restaurado: $target"
            ((ROLLBACK_SUCCESS++))
            return 0
        else
            error "Falha ao restaurar diretório: $target"
            ((ROLLBACK_FAILED++))
            return 1
        fi
    else
        warn "Backup de diretório não encontrado: $target"
        return 1
    fi
}

# Função para executar rollback de pacote
rollback_package() {
    local action="$1"
    local package="$2"
    local os="$3"

    case $os in
        ubuntu|debian)
            if sudo apt-get remove -y "$package" 2>/dev/null; then
                success "Pacote removido: $package"
                ((ROLLBACK_SUCCESS++))
                return 0
            fi
            ;;
        manjaro)
            if sudo pacman -R --noconfirm "$package" 2>/dev/null; then
                success "Pacote removido: $package"
                ((ROLLBACK_SUCCESS++))
                return 0
            fi
            ;;
        centos)
            if command_exists dnf; then
                if sudo dnf remove -y "$package" 2>/dev/null; then
                    success "Pacote removido: $package"
                    ((ROLLBACK_SUCCESS++))
                    return 0
                fi
            else
                if sudo yum remove -y "$package" 2>/dev/null; then
                    success "Pacote removido: $package"
                    ((ROLLBACK_SUCCESS++))
                    return 0
                fi
            fi
            ;;
    esac

    error "Falha ao remover pacote: $package"
    ((ROLLBACK_FAILED++))
    return 1
}

# Função para executar rollback de serviço
rollback_service() {
    local action="$1"
    local service="$2"

    if sudo systemctl stop "$service" 2>/dev/null; then
        success "Serviço parado: $service"
        ((ROLLBACK_SUCCESS++))
    else
        warn "Serviço já parado ou inexistente: $service"
    fi

    if sudo systemctl disable "$service" 2>/dev/null; then
        success "Serviço desabilitado: $service"
        ((ROLLBACK_SUCCESS++))
    else
        warn "Serviço já desabilitado ou inexistente: $service"
    fi

    return 0
}

# Função para executar rollback de symlink
rollback_symlink() {
    local action="$1"
    local link="$2"

    if [ -L "$link" ]; then
        if rm "$link" 2>/dev/null; then
            success "Link simbólico removido: $link"
            ((ROLLBACK_SUCCESS++))
            return 0
        else
            error "Falha ao remover link simbólico: $link"
            ((ROLLBACK_FAILED++))
            return 1
        fi
    else
        warn "Link simbólico não existe: $link"
        return 0
    fi
}

# Função para executar rollback de variável de ambiente
rollback_env_var() {
    local action="$1"
    local var_name="$2"
    local file="$3"

    if [ -f "$file" ]; then
        # Remover linha da variável se existir
        if grep -q "^export $var_name=" "$file" 2>/dev/null; then
            sed -i "/^export $var_name=/d" "$file"
            success "Variável de ambiente removida: $var_name de $file"
            ((ROLLBACK_SUCCESS++))
        else
            warn "Variável de ambiente não encontrada: $var_name em $file"
        fi
    else
        warn "Arquivo de configuração não encontrado: $file"
    fi

    return 0
}

# Função para executar rollback personalizado
rollback_custom() {
    local action="$1"
    local command="$2"
    local description="$3"

    log "Executando rollback personalizado: $description"
    if eval "$command" 2>/dev/null; then
        success "Rollback personalizado executado: $description"
        ((ROLLBACK_SUCCESS++))
        return 0
    else
        error "Falha no rollback personalizado: $description"
        ((ROLLBACK_FAILED++))
        return 1
    fi
}

# ==================== FUNÇÕES DE GERENCIAMENTO ====================

# Função para salvar estado atual
save_current_state() {
    local state_file="$BACKUP_DIR/state_$(date +%Y%m%d_%H%M%S).txt"

    section "Salvando Estado Atual do Sistema"

    # Salvar lista de pacotes instalados
    case $(detect_os) in
        ubuntu|debian)
            dpkg --get-selections > "${state_file}.packages" 2>/dev/null || true
            ;;
        manjaro)
            pacman -Q > "${state_file}.packages" 2>/dev/null || true
            ;;
        centos)
            if command_exists dnf; then
                dnf list installed > "${state_file}.packages" 2>/dev/null || true
            else
                yum list installed > "${state_file}.packages" 2>/dev/null || true
            fi
            ;;
    esac

    # Salvar serviços ativos
    systemctl list-units --type=service --state=active > "${state_file}.services" 2>/dev/null || true

    # Salvar variáveis de ambiente
    env > "${state_file}.env" 2>/dev/null || true

    success "Estado do sistema salvo em: $state_file"
    echo "$state_file"
}

# Função para executar rollback completo
execute_rollback() {
    local rollback_file="$1"

    if [ ! -f "$rollback_file" ]; then
        error "Arquivo de rollback não encontrado: $rollback_file"
        return 1
    fi

    section "Executando Rollback"

    while IFS='|' read -r action description; do
        subsection "Executando: $description"

        case $action in
            file_restore)
                # Formato: file_restore|target|backup
                local target backup
                IFS='|' read -r _ target backup <<< "$action|$description"
                rollback_file "$action" "$target" "$backup"
                ;;
            dir_restore)
                # Formato: dir_restore|target|backup
                local target backup
                IFS='|' read -r _ target backup <<< "$action|$description"
                rollback_directory "$action" "$target" "$backup"
                ;;
            package_remove)
                # Formato: package_remove|package|os
                local package os
                IFS='|' read -r _ package os <<< "$action|$description"
                rollback_package "$action" "$package" "$os"
                ;;
            service_stop)
                # Formato: service_stop|service
                local service
                IFS='|' read -r _ service <<< "$action|$description"
                rollback_service "$action" "$service"
                ;;
            symlink_remove)
                # Formato: symlink_remove|link
                local link
                IFS='|' read -r _ link <<< "$action|$description"
                rollback_symlink "$action" "$link"
                ;;
            env_remove)
                # Formato: env_remove|var_name|file
                local var_name file
                IFS='|' read -r _ var_name file <<< "$action|$description"
                rollback_env_var "$action" "$var_name" "$file"
                ;;
            custom)
                # Formato: custom|command|description
                local command desc
                IFS='|' read -r _ command desc <<< "$action|$description"
                rollback_custom "$action" "$command" "$desc"
                ;;
            *)
                warn "Ação de rollback desconhecida: $action"
                ;;
        esac
    done < "$rollback_file"

    # Resultado final
    echo ""
    log "Resumo do Rollback:"
    log "  - Ações bem-sucedidas: $ROLLBACK_SUCCESS"
    log "  - Ações falhadas: $ROLLBACK_FAILED"

    if [ $ROLLBACK_FAILED -eq 0 ]; then
        success "✅ Rollback executado com sucesso!"
        return 0
    else
        warn "⚠️ Rollback executado com algumas falhas. Verifique o log para detalhes."
        return 1
    fi
}

# ==================== FUNÇÕES DE UTILITÁRIO ====================

# Função para listar rollbacks disponíveis
list_available_rollbacks() {
    section "Rollbacks Disponíveis"

    if [ ! -d "$BACKUP_DIR" ]; then
        warn "Diretório de backup não encontrado: $BACKUP_DIR"
        return 1
    fi

    local rollback_files
    mapfile -t rollback_files < <(find "$BACKUP_DIR" -name "rollback_*.txt" -type f 2>/dev/null | sort -r)

    if [ ${#rollback_files[@]} -eq 0 ]; then
        warn "Nenhum arquivo de rollback encontrado."
        return 1
    fi

    local count=1
    for rollback_file in "${rollback_files[@]}"; do
        local filename
        filename=$(basename "$rollback_file")
        local timestamp
        timestamp=$(stat -c %y "$rollback_file" 2>/dev/null | cut -d'.' -f1)
        local actions
        actions=$(wc -l < "$rollback_file")

        echo "$count. $filename"
        echo "   📅 Criado em: $timestamp"
        echo "   📋 Ações: $actions"
        echo ""

        ((count++))
    done
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [comando] [argumentos...]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  save-state           - Salva o estado atual do sistema"
    echo "  execute <arquivo>    - Executa rollback do arquivo especificado"
    echo "  list                 - Lista rollbacks disponíveis"
    echo "  auto-rollback        - Executa o rollback mais recente"
    echo "  help                 - Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 save-state"
    echo "  $0 execute /path/to/rollback_file.txt"
    echo "  $0 list"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    case "${1:-help}" in
        save-state)
            save_current_state
            ;;
        execute)
            if [ $# -lt 2 ]; then
                error "Arquivo de rollback não especificado."
                echo "Uso: $0 execute <arquivo_rollback>"
                exit 1
            fi
            execute_rollback "$2"
            ;;
        list)
            list_available_rollbacks
            ;;
        auto-rollback)
            local latest_rollback
            latest_rollback=$(find "$BACKUP_DIR" -name "rollback_*.txt" -type f 2>/dev/null | sort -r | head -n1)

            if [ -z "$latest_rollback" ]; then
                error "Nenhum arquivo de rollback encontrado para rollback automático."
                exit 1
            fi

            log "Executando rollback automático com arquivo mais recente: $latest_rollback"
            execute_rollback "$latest_rollback"
            ;;
        help|*)
            show_help
            ;;
    esac
}

main "$@"
