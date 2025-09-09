#!/bin/bash
# =============================================================================
# Cluster AI - Módulo de Interface do Usuário
# =============================================================================
# Este arquivo contém funções para menus interativos, interface do usuário
# e apresentação de informações de forma organizada.

set -euo pipefail

# Carregar módulos dependentes
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/security.sh"

# =============================================================================
# CONFIGURAÇÃO DE INTERFACE
# =============================================================================

# Configurações de display
readonly UI_WIDTH=80
readonly UI_HEIGHT=24
readonly MENU_TIMEOUT=300  # 5 minutos

# Cores para interface
readonly MENU_COLOR='\033[1;36m'    # Cyan brilhante
readonly SELECT_COLOR='\033[1;32m'  # Verde brilhante
readonly ERROR_COLOR='\033[1;31m'   # Vermelho brilhante
readonly WARNING_COLOR='\033[1;33m' # Amarelo brilhante
readonly INFO_COLOR='\033[0;36m'    # Cyan normal
readonly RESET_COLOR='\033[0m'

# =============================================================================
# FUNÇÕES DE FORMATAÇÃO DE TEXTO
# =============================================================================

# Centralizar texto com largura específica
center_ui_text() {
    local text="$1"
    local width="${2:-$UI_WIDTH}"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# Criar linha separadora
ui_separator() {
    local char="${1:--}"
    local width="${2:-$UI_WIDTH}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# Criar cabeçalho
ui_header() {
    local title="$1"
    local subtitle="${2:-}"

    clear
    echo -e "${MENU_COLOR}"
    ui_separator "="
    center_ui_text "$title"
    if [[ -n "$subtitle" ]]; then
        center_ui_text "$subtitle"
    fi
    ui_separator "="
    echo -e "${RESET_COLOR}"
    echo
}

# Criar seção
ui_section() {
    local title="$1"
    echo -e "${MENU_COLOR}┌─ $title ${RESET_COLOR}"
}

# Criar subseção
ui_subsection() {
    local title="$1"
    echo -e "${INFO_COLOR}├─ $title${RESET_COLOR}"
}

# Criar item de menu
ui_menu_item() {
    local number="$1"
    local text="$2"
    local description="${3:-}"

    printf "  ${SELECT_COLOR}%2d${RESET_COLOR}) %s" "$number" "$text"
    if [[ -n "$description" ]]; then
        printf " ${INFO_COLOR}- %s${RESET_COLOR}" "$description"
    fi
    echo
}

# Criar item selecionado
ui_selected_item() {
    local text="$1"
    echo -e "  ${SELECT_COLOR}▶  $text${RESET_COLOR}"
}

# Criar rodapé
ui_footer() {
    local text="${1:-}"
    echo
    if [[ -n "$text" ]]; then
        echo -e "${INFO_COLOR}$text${RESET_COLOR}"
    fi
    ui_separator "-"
}

# =============================================================================
# FUNÇÕES DE INPUT DO USUÁRIO
# =============================================================================

# Ler entrada do usuário com validação
read_user_input() {
    local prompt="$1"
    local default="${2:-}"
    local validation_func="${3:-}"
    local max_attempts="${4:-3}"

    local input
    local attempt=1

    while (( attempt <= max_attempts )); do
        if [[ -n "$default" ]]; then
            read -p "$prompt [$default]: " input
            input="${input:-$default}"
        else
            read -p "$prompt: " input
        fi

        # Se não há função de validação, aceitar qualquer entrada
        if [[ -z "$validation_func" ]]; then
            echo "$input"
            return 0
        fi

        # Executar validação
        if $validation_func "$input"; then
            echo "$input"
            return 0
        else
            ((attempt++))
            if (( attempt <= max_attempts )); then
                echo -e "${ERROR_COLOR}Entrada inválida. Tente novamente (${attempt}/${max_attempts}).${RESET_COLOR}"
            fi
        fi
    done

    error "Número máximo de tentativas excedido"
    return 1
}

# Menu de seleção simples
select_menu_option() {
    local title="$1"
    shift
    local options=("$@")

    local choice
    local valid_options=""

    while true; do
        ui_header "$title"

        for i in "${!options[@]}"; do
            ui_menu_item "$((i + 1))" "${options[$i]}"
        done

        ui_footer "Digite o número da opção desejada"

        read -r choice

        # Verificar se é um número válido
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "$((choice - 1))"
            return 0
        else
            echo -e "${ERROR_COLOR}Opção inválida. Escolha um número entre 1 e ${#options[@]}.${RESET_COLOR}"
            sleep 2
        fi
    done
}

# Menu de múltipla escolha
select_multiple_options() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")

    local selected=()
    local choice

    while true; do
        ui_header "$title"

        echo -e "${INFO_COLOR}$prompt${RESET_COLOR}"
        echo
        echo "Opções disponíveis:"
        for i in "${!options[@]}"; do
            local marker=" "
            if [[ " ${selected[*]} " =~ " $i " ]]; then
                marker="✓"
            fi
            printf "  ${SELECT_COLOR}%2d${RESET_COLOR}) [%s] %s\n" "$((i + 1))" "$marker" "${options[$i]}"
        done

        echo
        echo "Comandos:"
        echo "  [número] - Selecionar/deselecionar opção"
        echo "  'done'   - Finalizar seleção"
        echo "  'clear'  - Limpar seleção"
        echo "  'all'    - Selecionar todas"

        read -r choice

        case "$choice" in
            done)
                if (( ${#selected[@]} > 0 )); then
                    echo "${selected[@]}"
                    return 0
                else
                    echo -e "${WARNING_COLOR}Nenhuma opção selecionada.${RESET_COLOR}"
                    sleep 1
                fi
                ;;
            clear)
                selected=()
                ;;
            all)
                selected=()
                for i in "${!options[@]}"; do
                    selected+=("$i")
                done
                ;;
            [0-9]*)
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
                    local index=$((choice - 1))
                    if [[ " ${selected[*]} " =~ " $index " ]]; then
                        # Remover da seleção
                        selected=("${selected[@]/$index}")
                    else
                        # Adicionar à seleção
                        selected+=("$index")
                    fi
                else
                    echo -e "${ERROR_COLOR}Número inválido.${RESET_COLOR}"
                    sleep 1
                fi
                ;;
            *)
                echo -e "${ERROR_COLOR}Comando inválido.${RESET_COLOR}"
                sleep 1
                ;;
        esac
    done
}

# Confirmar ação com menu
confirm_action_menu() {
    local title="$1"
    local message="$2"
    local risk_level="${3:-medium}"

    local options=("Sim" "Não")

    case "$risk_level" in
        critical)
            options=("Não" "Sim")  # Inverter ordem para operações críticas
            ;;
        high)
            options=("Sim" "Não")
            ;;
        *)
            options=("Sim" "Não")
            ;;
    esac

    ui_header "$title"
    echo -e "${WARNING_COLOR}$message${RESET_COLOR}"
    echo

    local choice
    choice=$(select_menu_option "Confirmação" "${options[@]}")

    if [[ "$choice" == "0" ]]; then
        return 0  # Sim
    else
        return 1  # Não
    fi
}

# =============================================================================
# FUNÇÕES DE PROGRESSO E STATUS
# =============================================================================

# Barra de progresso para interface
ui_progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local message="${4:-Processando...}"

    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    printf "\r%s [%s%s] %d%%" \
           "$message" \
           "$(printf '█%.0s' $(seq 1 $filled))" \
           "$(printf '░%.0s' $(seq 1 $empty))" \
           "$percentage"
}

# Spinner para operações longas
ui_spinner() {
    local pid="$1"
    local message="${2:-Processando...}"
    local spinner_chars="/-\|"

    local i=0
    while process_running "$pid"; do
        printf "\r%s %s" "${spinner_chars:i%4:1}" "$message"
        sleep 0.1
        ((i++))
    done

    printf "\r%s\n" "$(printf ' %.0s' {1..50})" # Limpar linha
}

# Mostrar status com cores
ui_status() {
    local status="$1"
    local message="$2"

    case "$status" in
        success|ok)
            echo -e "${SELECT_COLOR}✅ $message${RESET_COLOR}"
            ;;
        error|fail)
            echo -e "${ERROR_COLOR}❌ $message${RESET_COLOR}"
            ;;
        warning|warn)
            echo -e "${WARNING_COLOR}⚠️  $message${RESET_COLOR}"
            ;;
        info)
            echo -e "${INFO_COLOR}ℹ️  $message${RESET_COLOR}"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
}

# =============================================================================
# MENUS PRINCIPAIS
# =============================================================================

# Menu principal do Cluster AI
main_menu() {
    local title="Cluster AI Manager"
    local subtitle="Sistema de Gerenciamento de Cluster"

    while true; do
        ui_header "$title" "$subtitle"

        ui_menu_item 1 "Gerenciar Serviços" "Iniciar/parar/reiniciar serviços"
        ui_menu_item 2 "Gerenciar Workers" "Configurar workers remotos"
        ui_menu_item 3 "Monitoramento" "Status e logs do sistema"
        ui_menu_item 4 "Manutenção" "Backup, limpeza e otimização"
        ui_menu_item 5 "Configuração" "Configurações do sistema"
        ui_menu_item 6 "Ferramentas" "Utilitários diversos"
        ui_menu_item 0 "Sair" "Encerrar o programa"

        ui_footer "Escolha uma opção (0-6)"

        local choice
        read -r choice

        case "$choice" in
            1) services_menu ;;
            2) workers_menu ;;
            3) monitoring_menu ;;
            4) maintenance_menu ;;
            5) configuration_menu ;;
            6) tools_menu ;;
            0)
                ui_header "Encerrando" "Cluster AI Manager"
                ui_status "info" "Obrigado por usar o Cluster AI Manager!"
                echo
                exit 0
                ;;
            *)
                ui_status "error" "Opção inválida. Escolha um número entre 0 e 6."
                sleep 2
                ;;
        esac
    done
}

# Menu de serviços
services_menu() {
    while true; do
        ui_header "Gerenciamento de Serviços"

        ui_menu_item 1 "Status dos Serviços" "Verificar status de todos os serviços"
        ui_menu_item 2 "Gerenciar systemd" "Iniciar/parar serviços do sistema"
        ui_menu_item 3 "Gerenciar Docker" "Controlar containers Docker"
        ui_menu_item 4 "Processos em Background" "Gerenciar processos do cluster"
        ui_menu_item 0 "Voltar" "Retornar ao menu principal"

        ui_footer "Escolha uma opção (0-4)"

        local choice
        read -r choice

        case "$choice" in
            1) services_status_menu ;;
            2) systemd_services_menu ;;
            3) docker_services_menu ;;
            4) background_processes_menu ;;
            0) return ;;
            *)
                ui_status "error" "Opção inválida."
                sleep 2
                ;;
        esac
    done
}

# Menu de workers
workers_menu() {
    while true; do
        ui_header "Gerenciamento de Workers"

        ui_menu_item 1 "Listar Workers" "Ver todos os workers configurados"
        ui_menu_item 2 "Adicionar Worker" "Adicionar novo worker manualmente"
        ui_menu_item 3 "Testar Conectividade" "Verificar conexão com workers"
        ui_menu_item 4 "Descobrir Workers" "Encontrar workers na rede"
        ui_menu_item 5 "Remover Worker" "Remover worker da configuração"
        ui_menu_item 0 "Voltar" "Retornar ao menu principal"

        ui_footer "Escolha uma opção (0-5)"

        local choice
        read -r choice

        case "$choice" in
            1) list_workers_menu ;;
            2) add_worker_menu ;;
            3) test_workers_menu ;;
            4) discover_workers_menu ;;
            5) remove_worker_menu ;;
            0) return ;;
            *)
                ui_status "error" "Opção inválida."
                sleep 2
                ;;
        esac
    done
}

# Menu de monitoramento
monitoring_menu() {
    while true; do
        ui_header "Monitoramento do Sistema"

        ui_menu_item 1 "Status Geral" "Visão geral do sistema"
        ui_menu_item 2 "Logs do Sistema" "Visualizar logs de auditoria"
        ui_menu_item 3 "Recursos do Sistema" "Uso de CPU, memória, disco"
        ui_menu_item 4 "Status dos Workers" "Verificar saúde dos workers"
        ui_menu_item 0 "Voltar" "Retornar ao menu principal"

        ui_footer "Escolha uma opção (0-4)"

        local choice
        read -r choice

        case "$choice" in
            1) system_status_menu ;;
            2) system_logs_menu ;;
            3) system_resources_menu ;;
            4) workers_status_menu ;;
            0) return ;;
            *)
                ui_status "error" "Opção inválida."
                sleep 2
                ;;
        esac
    done
}

# Menu de manutenção
maintenance_menu() {
    while true; do
        ui_header "Manutenção do Sistema"

        ui_menu_item 1 "Backup" "Criar backup do sistema"
        ui_menu_item 2 "Limpeza" "Limpar arquivos temporários e logs"
        ui_menu_item 3 "Otimização" "Otimizar performance do sistema"
        ui_menu_item 4 "Verificação" "Verificar integridade do sistema"
        ui_menu_item 0 "Voltar" "Retornar ao menu principal"

        ui_footer "Escolha uma opção (0-4)"

        local choice
        read -r choice

        case "$choice" in
            1) backup_menu ;;
            2) cleanup_menu ;;
            3) optimization_menu ;;
            4) verification_menu ;;
            0) return ;;
            *)
                ui_status "error" "Opção inválida."
                sleep 2
                ;;
        esac
    done
}

# Menu de configuração
configuration_menu() {
    while true; do
        ui_header "Configuração do Sistema"

        ui_menu_item 1 "Configurações Gerais" "Configurações básicas do cluster"
        ui_menu_item 2 "Configurações de Segurança" "Configurações de segurança"
        ui_menu_item 3 "Configurações de Rede" "Configurações de rede e conectividade"
        ui_menu_item 4 "Backup de Configuração" "Salvar/carregar configurações"
        ui_menu_item 0 "Voltar" "Retornar ao menu principal"

        ui_footer "Escolha uma opção (0-4)"

        local choice
        read -r choice

        case "$choice" in
            1) general_config_menu ;;
            2) security_config_menu ;;
            3) network_config_menu ;;
            4) config_backup_menu ;;
            0) return ;;
            *)
                ui_status "error" "Opção inválida."
                sleep 2
                ;;
        esac
    done
}

# Menu de ferramentas
tools_menu() {
    while true; do
        ui_header "Ferramentas e Utilitários"

        ui_menu_item 1 "Diagnóstico" "Ferramentas de diagnóstico"
        ui_menu_item 2 "Testes" "Executar testes do sistema"
        ui_menu_item 3 "Relatórios" "Gerar relatórios do sistema"
        ui_menu_item 4 "Shell Interativo" "Acesso ao shell do sistema"
        ui_menu_item 0 "Voltar" "Retornar ao menu principal"

        ui_footer "Escolha uma opção (0-4)"

        local choice
        read -r choice

        case "$choice" in
            1) diagnostic_tools_menu ;;
            2) testing_tools_menu ;;
            3) reports_menu ;;
            4) interactive_shell ;;
            0) return ;;
            *)
                ui_status "error" "Opção inválida."
                sleep 2
                ;;
        esac
    done
}

# =============================================================================
# MENUS ESPECÍFICOS (STUBS PARA IMPLEMENTAÇÃO FUTURA)
# =============================================================================

# Estes menus serão implementados quando os módulos específicos forem criados
services_status_menu() { ui_header "Status dos Serviços"; echo "Implementação em desenvolvimento..."; sleep 2; }
systemd_services_menu() { ui_header "Gerenciamento systemd"; echo "Implementação em desenvolvimento..."; sleep 2; }
docker_services_menu() { ui_header "Gerenciamento Docker"; echo "Implementação em desenvolvimento..."; sleep 2; }
background_processes_menu() { ui_header "Processos em Background"; echo "Implementação em desenvolvimento..."; sleep 2; }

list_workers_menu() { ui_header "Listar Workers"; echo "Implementação em desenvolvimento..."; sleep 2; }
add_worker_menu() { ui_header "Adicionar Worker"; echo "Implementação em desenvolvimento..."; sleep 2; }
test_workers_menu() { ui_header "Testar Workers"; echo "Implementação em desenvolvimento..."; sleep 2; }
discover_workers_menu() { ui_header "Descobrir Workers"; echo "Implementação em desenvolvimento..."; sleep 2; }
remove_worker_menu() { ui_header "Remover Worker"; echo "Implementação em desenvolvimento..."; sleep 2; }

system_status_menu() { ui_header "Status do Sistema"; echo "Implementação em desenvolvimento..."; sleep 2; }
system_logs_menu() { ui_header "Logs do Sistema"; echo "Implementação em desenvolvimento..."; sleep 2; }
system_resources_menu() { ui_header "Recursos do Sistema"; echo "Implementação em desenvolvimento..."; sleep 2; }
workers_status_menu() { ui_header "Status dos Workers"; echo "Implementação em desenvolvimento..."; sleep 2; }

backup_menu() { ui_header "Backup"; echo "Implementação em desenvolvimento..."; sleep 2; }
cleanup_menu() { ui_header "Limpeza"; echo "Implementação em desenvolvimento..."; sleep 2; }
optimization_menu() { ui_header "Otimização"; echo "Implementação em desenvolvimento..."; sleep 2; }
verification_menu() { ui_header "Verificação"; echo "Implementação em desenvolvimento..."; sleep 2; }

general_config_menu() { ui_header "Configurações Gerais"; echo "Implementação em desenvolvimento..."; sleep 2; }
security_config_menu() { ui_header "Configurações de Segurança"; echo "Implementação em desenvolvimento..."; sleep 2; }
network_config_menu() { ui_header "Configurações de Rede"; echo "Implementação em desenvolvimento..."; sleep 2; }
config_backup_menu() { ui_header "Backup de Configuração"; echo "Implementação em desenvolvimento..."; sleep 2; }

diagnostic_tools_menu() { ui_header "Ferramentas de Diagnóstico"; echo "Implementação em desenvolvimento..."; sleep 2; }
testing_tools_menu() { ui_header "Ferramentas de Teste"; echo "Implementação em desenvolvimento..."; sleep 2; }
reports_menu() { ui_header "Relatórios"; echo "Implementação em desenvolvimento..."; sleep 2; }

# Shell interativo
interactive_shell() {
    ui_header "Shell Interativo"
    echo -e "${WARNING_COLOR}ATENÇÃO: Você está entrando no shell do sistema.${RESET_COLOR}"
    echo -e "${WARNING_COLOR}Digite 'exit' para retornar ao menu principal.${RESET_COLOR}"
    echo
    echo -e "${INFO_COLOR}Diretório atual: $(pwd)${RESET_COLOR}"
    echo -e "${INFO_COLOR}Usuário: $(whoami)${RESET_COLOR}"
    echo

    if confirm_action_menu "Shell Interativo" "Deseja continuar?"; then
        bash --rcfile <(echo "PS1='\[\033[1;36m\][Cluster AI Shell]\[\033[0m\] \w \$ '")
    fi
}

# =============================================================================
# FUNÇÕES DE DISPLAY AVANÇADO
# =============================================================================

# Mostrar tabela formatada
display_table() {
    local title="$1"
    shift
    local headers=("$@")

    ui_section "$title"

    # Calcular larguras das colunas
    local col_widths=()
    for header in "${headers[@]}"; do
        col_widths+=("${#header}")
    done

    # Imprimir cabeçalhos
    local header_line=""
    for i in "${!headers[@]}"; do
        header_line+="$(printf "%-${col_widths[$i]}s" "${headers[$i]}") "
    done
    echo "$header_line"

    # Imprimir separador
    local sep_line=""
    for width in "${col_widths[@]}"; do
        sep_line+="$(printf '%*s' "$width" '' | tr ' ' '-') "
    done
    echo "$sep_line"
}

# Mostrar métricas do sistema
display_system_metrics() {
    ui_section "Métricas do Sistema"

    # CPU
    local cpu_usage
    cpu_usage=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g' | awk '{print $1}')
    echo "CPU Load: $cpu_usage"

    # Memória
    local mem_info
    mem_info=$(free -h | awk 'NR==2{printf "%.1fGB usada de %.1fGB (%.1f%%)", $3/1024, $2/1024, $3*100/$2}')
    echo "Memória: $mem_info"

    # Disco
    local disk_info
    disk_info=$(df -h . | awk 'NR==2{print $4 " disponível de " $2}')
    echo "Disco: $disk_info"

    # Rede
    local net_info
    net_info=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' || echo "N/A")
    echo "Interface de Rede: $net_info"
}

# =============================================================================
# INICIALIZAÇÃO DO MÓDULO
# =============================================================================

# Inicializar módulo de interface
init_ui_module() {
    # Verificar tamanho do terminal
    if command_exists tput; then
        UI_HEIGHT=$(tput lines 2>/dev/null || echo "24")
        UI_WIDTH=$(tput cols 2>/dev/null || echo "80")
    fi

    # Configurar timeout do menu
    if command_exists timeout; then
        TMOUT=$MENU_TIMEOUT
    fi

    audit_log "UI_MODULE_INITIALIZED" "SUCCESS" "UI module loaded with ${UI_WIDTH}x${UI_HEIGHT} terminal"
}

# Verificar se módulo foi carregado corretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_environment
    init_security_module
    init_ui_module
    info "Módulo ui.sh carregado com sucesso"
fi
