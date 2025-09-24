#!/bin/bash
# =============================================================================
# Gerenciador de Workers do Cluster AI
# =============================================================================
# Este script centraliza as funções para monitorar e atualizar os workers
# remotos do cluster. É chamado pelo 'manager.sh'.
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto para garantir que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT"

# Carregar funções comuns
# shellcheck source=../lib/common.sh
source "scripts/lib/common.sh"
PID_FILE="${PROJECT_ROOT}/.monitor_updates_pid"
WORKER_CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"

# =============================================================================
# FUNÇÕES DE GERENCIAMENTO DE WORKERS
# =============================================================================

start_worker_monitor() {
    section "INICIANDO MONITOR DE WORKERS"
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        warn "Monitor de workers já está rodando."
    else
        info "Iniciando monitor em segundo plano..."
        # O script monitor_worker_updates.sh gerencia seu próprio PID
        nohup bash scripts/monitor_worker_updates.sh start > logs/worker_monitor.log 2>&1 &
        success "Monitor de workers iniciado."
    fi
}

stop_worker_monitor() {
    section "PARANDO MONITOR DE WORKERS"
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        info "Enviando comando de parada para o monitor de workers..."
        # Chama o próprio script do monitor para um encerramento gracioso
        if bash scripts/monitor_worker_updates.sh stop; then
            success "Monitor de workers parado."
        else
            error "Falha ao parar o monitor de workers."
        fi
    else
        warn "Monitor de workers não está rodando."
    fi
}

check_worker_monitor() {
    section "STATUS DO MONITOR DE WORKERS"
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        info "Monitor de workers está ${GREEN}ATIVO${NC}."
        local pid
        pid=$(cat "$PID_FILE")
        echo "PID: $pid"
        echo "Log: $(pwd)/logs/worker_monitor.log"
    else
        info "Monitor de workers está ${RED}INATIVO${NC}."
        rm -f "$PID_FILE" # Limpa o arquivo de PID obsoleto
    fi
}

update_all_workers() {
    section "ATUALIZANDO TODOS OS WORKERS"
    info "Iniciando atualização manual de todos os workers..."
    if python3 scripts/utils/auto_worker_updates.py update; then
        success "Atualização dos workers concluída com sucesso."
    else
        error "Falha na atualização dos workers."
        exit 1
    fi
}

list_workers() {
    section "LISTANDO WORKERS CONFIGURADOS"
    if [ ! -f "$WORKER_CONFIG_FILE" ]; then
        warn "Arquivo de configuração de workers '$WORKER_CONFIG_FILE' não encontrado."
        return 1
    fi

    info "Lendo workers de '$WORKER_CONFIG_FILE'..."
    # Usa yq para ler e formatar a saída do YAML.
    if command -v yq >/dev/null; then
        yq e '.workers | to_entries | .[] | "Worker: " + .key + " | IP: " + .value.host + " | Usuário: " + .value.user + " | Porta: " + .value.port' "$WORKER_CONFIG_FILE"
    else
        error "Comando 'yq' não encontrado. Não é possível listar os workers."
        info "Instale com: sudo pip install yq"
    fi
}

add_worker() {
    section "ADICIONANDO NOVO WORKER"
    # Esta função é interativa e será chamada pelo menu.
    # Para uso em linha de comando, seriam necessários argumentos.
    local name
    name=$(whiptail --inputbox "Digite um nome único para o worker (ex: worker-01):" 8 78 --title "Adicionar Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

    local host
    host=$(whiptail --inputbox "Digite o endereço IP do worker:" 8 78 --title "Adicionar Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

    local user
    user=$(whiptail --inputbox "Digite o nome de usuário para a conexão SSH:" 8 78 "dcm" --title "Adicionar Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

    local port
    port=$(whiptail --inputbox "Digite a porta SSH do worker:" 8 78 "22" --title "Adicionar Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

    if (whiptail --title "Confirmar Adição" --yesno "Adicionar o worker '$name' com IP '$host'?" 8 78); then
        if command -v yq >/dev/null; then
            yq e -i ".workers[\"$name\"] = {\"host\": \"$host\", \"user\": \"$user\", \"port\": $port, \"enabled\": true}" "$WORKER_CONFIG_FILE"
            success "Worker '$name' adicionado a '$WORKER_CONFIG_FILE'."
        else
            error "Comando 'yq' não encontrado. Não é possível adicionar o worker."
        fi
    else
        warn "Adição cancelada."
    fi
}

remove_worker() {
    section "REMOVENDO WORKER"
    if ! command -v yq >/dev/null; then
        error "Comando 'yq' não encontrado. Não é possível remover workers."
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$WORKER_CONFIG_FILE")
    
    if [ ${#workers[@]} -eq 0 ]; then
        warn "Nenhum worker configurado para remover."
        return 1
    fi

    local menu_options=()
    for worker in "${workers[@]}"; do
        menu_options+=("$worker" "")
    done

    local choice
    choice=$(whiptail --menu "Selecione o worker para remover:" 20 78 10 "${menu_options[@]}" --title "Remover Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Remoção cancelada." && return 1

    if (whiptail --title "Confirmar Remoção" --yesno "Tem certeza que deseja remover o worker '$choice'?" 8 78); then
        yq e -i "del(.workers[\"$choice\"])" "$WORKER_CONFIG_FILE"
        success "Worker '$choice' removido de '$WORKER_CONFIG_FILE'."
    else
        warn "Remoção cancelada."
    fi
}

show_worker_help() {
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos de gerenciamento de workers:"
    echo -e "  ${GREEN}add${NC}             - Adiciona um novo worker (interativo)."
    echo -e "  ${GREEN}remove${NC}          - Remove um worker existente (interativo)."
    echo -e "  ${GREEN}list${NC}            - Lista todos os workers configurados."
    echo -e "  ${GREEN}start-monitor${NC}   - Inicia o monitor de workers em background."
    echo -e "  ${GREEN}stop-monitor${NC}    - Para o monitor de workers."
    echo -e "  ${GREEN}status-monitor${NC}  - Verifica o status do monitor de workers."
    echo -e "  ${GREEN}update-all${NC}      - Força a atualização de todos os workers."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    start-monitor) start_worker_monitor ;;
    stop-monitor) stop_worker_monitor ;;
    status-monitor) check_worker_monitor ;;
    update-all) update_all_workers ;;
    add) add_worker ;;
    remove) remove_worker ;;
    list) list_workers ;;
    *)
      show_worker_help
      exit 1
      ;;
esac