#!/bin/bash
# Manager Script - Cluster AI
# Control panel for managing cluster services and operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/scripts/lib/common.sh"
INSTALL_FUNCTIONS="${SCRIPT_DIR}/scripts/lib/install_functions.sh"

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "ERROR: Common functions script not found: $COMMON_SCRIPT"
    exit 1
fi

if [ ! -f "$INSTALL_FUNCTIONS" ]; then
    echo "ERROR: Install functions script not found: $INSTALL_FUNCTIONS"
    exit 1
fi

source "$COMMON_SCRIPT"
source "$INSTALL_FUNCTIONS"

show_menu() {
    echo "======================================"
    echo "        Cluster AI Manager"
    echo "======================================"
    echo "1) Start Services (Dask, Ollama)"
    echo "2) Stop Services (Dask, Ollama)"
    echo "3) Restart Services"
    echo "4) Show Status"
    echo "5) Run Health Check"
    echo "6) Run Backup"
    echo "7) Configure Cluster"
    echo "8) Exit"
    echo "======================================"
}

start_services() {
    section "Starting Services"
    # Start Dask Scheduler
    if ! pgrep -f dask-scheduler > /dev/null; then
        run_command "dask scheduler --port 8786 --dashboard-address :8787 > ${SCRIPT_DIR}/logs/dask_scheduler.log 2>&1 &" "Starting Dask Scheduler"
        sleep 2
    else
        info "Dask Scheduler already running"
    fi

    # Start Ollama service
    if systemctl is-active --quiet ollama; then
        info "Ollama service already running"
    else
        run_sudo "systemctl start ollama" "Starting Ollama service"
    fi
}

stop_services() {
    section "Stopping Services"
    pkill -f dask-scheduler || info "Dask Scheduler not running"
    pkill -f dask-worker || info "Dask Worker not running"
    run_sudo "systemctl stop ollama" "Stopping Ollama service"
}

restart_services() {
    stop_services
    start_services
}

show_status() {
    section "Cluster Status"
    echo "Dask Scheduler:"
    pgrep -fl dask-scheduler || echo "Not running"
    echo "Dask Workers:"
    pgrep -fl dask-worker || echo "Not running"
    echo "Ollama Service:"
    systemctl status ollama --no-pager
}

run_health_check() {
    section "Running Health Check"
    bash "${SCRIPT_DIR}/scripts/utils/health_check.sh"
}

run_backup() {
    section "Running Backup"
    bash "${SCRIPT_DIR}/scripts/backup/backup_manager.sh"
}

configure_cluster() {
    section "Configuring Cluster"
    bash "${SCRIPT_DIR}/install.sh" --configure
}

main() {
    while true; do
        show_menu
        read -p "Select an option [1-8]: " choice
        case $choice in
            1) start_services ;;
            2) stop_services ;;
            3) restart_services ;;
            4) show_status ;;
            5) run_health_check ;;
            6) run_backup ;;
            7) configure_cluster ;;
            8) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option";;
        esac
        echo ""
    done
}

main "$@"
