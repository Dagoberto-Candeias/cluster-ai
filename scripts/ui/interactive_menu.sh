#!/bin/bash
# =============================================================================
# Menu Interativo para o Cluster AI Manager
# =============================================================================
# Usa whiptail para fornecer uma interface de usuário baseada em texto.
# É chamado pelo 'manager.sh' quando nenhuma opção é fornecida.
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto para garantir que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT"

# --- Funções de Execução ---

run_command() {
    local cmd_description="$1"
    shift
    local cmd_args=("$@")

    # Executa o comando e captura a saída e código de saída
    local output exit_code
    output=$(./manager.sh "${cmd_args[@]}" 2>&1)
    exit_code=$?

    # Mostra barra de progresso enquanto "processa"
    echo "50" | whiptail --title "Executando" --gauge "$cmd_description..." 6 78 0

    if [ $exit_code -eq 0 ]; then
        whiptail --title "Sucesso" --msgbox "Comando executado com sucesso.\n\nSaída:\n$output" 20 78
    else
        whiptail --title "Erro" --msgbox "Ocorreu um erro ao executar o comando.\n\nSaída:\n$output" 20 78
    fi
}

# --- Funções de Menu ---

main_menu() {
    while true; do
        choice=$(whiptail --title "Cluster AI Manager" --menu "Selecione uma área de gerenciamento:" 20 78 10 \
        "1" "Gerenciamento do Cluster" \
        "2" "Saúde e Status" \
        "3" "Gerenciamento de Workers" \
        "4" "Manutenção do Sistema" \
        "5" "Executar Testes" \
        "0" "Sair" 3>&1 1>&2 2>&3)

        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            break # Sai se o usuário pressionar Esc ou Cancelar
        fi

        case "$choice" in
            1) cluster_menu ;;
            2) health_menu ;;
            3) worker_menu ;;
            4) system_menu ;;
            5) run_command "Executando testes do sistema" test ;;
            0) break ;;
        esac
    done
}

cluster_menu() {
    choice=$(whiptail --title "Gerenciamento do Cluster" --menu "Selecione uma ação:" 20 78 5 \
    "1" "Iniciar Cluster" \
    "2" "Parar Cluster" \
    "3" "Reiniciar Cluster" \
    "0" "Voltar" 3>&1 1>&2 2>&3)

    case "$choice" in
        1) run_command "Iniciando o cluster AI" start ;;
        2) run_command "Parando o cluster AI" stop ;;
        3) run_command "Reiniciando o cluster AI" restart ;;
        0) return ;;
    esac
}

health_menu() {
    choice=$(whiptail --title "Saúde e Status" --menu "Selecione uma ação:" 20 78 5 \
    "1" "Ver Status Detalhado" \
    "2" "Executar Diagnóstico Completo" \
    "3" "Visualizar Logs Recentes" \
    "0" "Voltar" 3>&1 1>&2 2>&3)

    case "$choice" in
        1) run_command "Verificando status dos serviços" status ;;
        2) run_command "Executando diagnóstico do sistema" diag ;;
        3) run_command "Visualizando logs do sistema" logs ;;
        0) return ;;
    esac
}

worker_menu() {
    choice=$(whiptail --title "Gerenciamento de Workers" --menu "Selecione uma ação:" 20 78 8 \
    "1" "Listar Workers" \
    "2" "Adicionar Worker" \
    "3" "Remover Worker" \
    ""  "--- Monitor ---" \
    "4" "Iniciar Monitor de Workers" \
    "5" "Parar Monitor de Workers" \
    "6" "Verificar Status do Monitor" \
    "7" "Forçar Atualização de Todos os Workers" \
    "0" "Voltar" 3>&1 1>&2 2>&3)

    case "$choice" in
        1) run_command "Listando workers configurados" worker list ;;
        2) run_command "Adicionando um novo worker" worker add ;;
        3) run_command "Removendo um worker existente" worker remove ;;
        4) run_command "Iniciando o monitor de workers" worker start-monitor ;;
        5) run_command "Parando o monitor de workers" worker stop-monitor ;;
        6) run_command "Verificando o status do monitor" worker status-monitor ;;
        7) run_command "Forçando atualização de todos os workers" worker update-all ;;
        0) return ;;
    esac
}

system_menu() {
    choice=$(whiptail --title "Manutenção do Sistema" --menu "Selecione uma ação:" 20 78 5 \
    "1" "Atualizar o Projeto (git pull)" \
    "2" "Otimizar Performance do Sistema" \
    "3" "Gerenciar Segurança" \
    "4" "Gerenciar VSCode" \
    "0" "Voltar" 3>&1 1>&2 2>&3)

    case "$choice" in
        1) run_command "Verificando e aplicando atualizações" system update ;;
        2) run_command "Executando otimizador de performance" system optimize ;;
        3) run_command "Acessando gerenciador de segurança" system security help ;; # Mostra ajuda como exemplo
        4) run_command "Acessando gerenciador do VSCode" system vscode help ;; # Mostra ajuda como exemplo
        0) return ;;
    esac
}

# --- Ponto de Entrada ---
main_menu

clear
echo "Obrigado por usar o Cluster AI Manager!"