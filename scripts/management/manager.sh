#!/bin/bash
# Painel de Controle do Cluster AI - Versão Modular
#
# Este script serve como o ponto central para gerenciar todos os serviços
# do ecossistema Cluster AI, incluindo Ollama, Dask e OpenWebUI.
# Gerencia serviços, executa verificações e otimizações.

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

# --- VERIFICAÇÕES DE SEGURANÇA ---
# Verificar se está sendo executado como root (não recomendado)
if [ "$EUID" -eq 0 ]; then
    echo "ERRO DE SEGURANÇA: Este script não deve ser executado como root (sudo)."
    echo "Execute como usuário normal: ./scripts/management/manager.sh"
    echo ""
    echo "Razões de segurança:"
    echo "- Evita modificações acidentais no sistema"
    echo "- Previne exposição desnecessária de privilégios"
    echo "- Segue melhores práticas de segurança"
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
UTILS_DIR="${SCRIPTS_DIR}/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em ${UTILS_DIR}/common.sh"
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Log files
CLUSTER_AI_LOG_DIR="${PROJECT_ROOT}/logs"
CLUSTER_AI_LOG_FILE="$CLUSTER_AI_LOG_DIR/cluster_ai.log"
AUDIT_LOG_FILE="$CLUSTER_AI_LOG_DIR/audit.log"
mkdir -p "$CLUSTER_AI_LOG_DIR"

# --- Constantes de Serviço ---
OLLAMA_SERVICE_NAME="ollama"
DASK_SCHEDULER_PROCESS="dask-scheduler"
DASK_WORKER_PROCESS="dask-worker"
OPENWEBUI_CONTAINER_NAME="open-webui"

# ==================== FUNÇÕES DE GERENCIAMENTO ====================

audit_log() {
    local action="$1"
    local status="$2"
    local details="${3:-}"
    local user="${USER:-unknown}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ -n "$AUDIT_LOG_FILE" ] && [ -w "$(dirname "$AUDIT_LOG_FILE")" ]; then
        echo "[$timestamp] [AUDIT] [USER:$user] [ACTION:$action] [STATUS:$status] $details" >> "$AUDIT_LOG_FILE"
    fi
}

show_menu() {
    section "Painel de Controle - Cluster AI"
    echo "--- Ações em Massa ---"
    echo "1. 🚀 Iniciar TODOS os serviços"
    echo "2. 🛑 Parar TODOS os serviços"
    echo "3. 🔄 Reiniciar TODOS os serviços"
    echo "---"
    echo "4. 🧩 Gerenciar serviços locais individuais"
    echo "5. 🌐 Gerenciar Workers Remotos (SSH)"
    echo "--- Diagnóstico e Manutenção ---"
    echo "6. 📊 Mostrar status geral"
    echo "7. 🩺 Executar verificação de saúde (Health Check)"
    echo "8. 🛠️  Otimizador de Recursos"
    echo "9. 🧠 Instalar Modelos de IA (Ollama)"
    echo "10. 🗑️ Remover Modelos de IA (Ollama)"
    echo "11. 💾 Gerenciar Configurações de Otimização (Backup/Restore)"
    echo "12. ⚙️  Acessar instalador/configurador"
    echo "13. 📜 Ver log de auditoria"
    echo "14. 📡 Descobrir nós remotos na rede"
    echo "15. 🗄️ Rotacionar logs de auditoria"
    echo "16. ⏰ Agendar rotação de logs (Cron)"
    echo "17. 📺 Configurar serviço de monitoramento"
    echo "18. 📜 Gerar README.md dinâmico"
    echo "19.  Lint (verificar qualidade do código)"
    echo "20. 🔄 Atualizar o Cluster AI (via Git)"
    echo "21. 🗄️ Gerenciar Backups"
    echo "22. 📊 Gerar relatório de performance"
    echo "---"
    echo "23. 🚪 Sair"
}

stop_ollama() {
    if command_exists "$OLLAMA_SERVICE_NAME" && service_active "$OLLAMA_SERVICE_NAME"; then
        log "Parando serviço Ollama..."
        sudo systemctl stop "$OLLAMA_SERVICE_NAME" && success "Serviço Ollama parado." || { error "Falha ao parar serviço Ollama."; return 1; }
    else
        log "Serviço Ollama não estava ativo."
    fi
}

start_ollama() {
    if command_exists "$OLLAMA_SERVICE_NAME" && ! service_active "$OLLAMA_SERVICE_NAME"; then
        log "Iniciando serviço Ollama..."
        sudo systemctl start "$OLLAMA_SERVICE_NAME" && success "Serviço Ollama iniciado." || { error "Falha ao iniciar serviço Ollama."; return 1; }
    else
        log "Serviço Ollama já estava ativo."
    fi
}

start_dask() {
    if ! pgrep -f "$DASK_SCHEDULER_PROCESS" > /dev/null; then
        log "Iniciando Dask Scheduler..."
        # Ativar venv se existir
        [ -f "${PROJECT_ROOT}/.venv/bin/activate" ] && source "${PROJECT_ROOT}/.venv/bin/activate"
        
        # Inicia o scheduler em background e redireciona a saída para um log
        nohup dask-scheduler --port 8786 --dashboard-address :8787 > "${PROJECT_ROOT}/logs/dask_scheduler.log" 2>&1 &
        
        # Aguarda um momento para o processo iniciar antes de verificar
        sleep 2 
        
        if pgrep -f "$DASK_SCHEDULER_PROCESS" > /dev/null; then success "Dask Scheduler iniciado."; else { error "Falha ao iniciar Dask Scheduler. Verifique o log em: ${PROJECT_ROOT}/logs/dask_scheduler.log"; return 1; }; fi
    else
        success "Dask Scheduler já está em execução."
    fi
}

stop_dask() {
    # Verifica e para o scheduler
    if pgrep -f "$DASK_SCHEDULER_PROCESS" > /dev/null; then
        pkill -f "$DASK_SCHEDULER_PROCESS" && success "Dask Scheduler parado."
    else
        log "Dask Scheduler não estava em execução."
    fi
    # Verifica e para os workers
    if pgrep -f "$DASK_WORKER_PROCESS" > /dev/null; then
        pkill -f "$DASK_WORKER_PROCESS" && success "Dask Workers parados."
    else
        log "Dask Workers não estavam em execução."
    fi
}

start_openwebui() {
    # Verificação rigorosa de dependência: Ollama deve estar ativo.
    if ! service_active "$OLLAMA_SERVICE_NAME"; then
        error "Dependência não atendida: O serviço '$OLLAMA_SERVICE_NAME' precisa estar ativo para iniciar o OpenWebUI."
        return 1
    fi

    if command_exists docker && docker ps -a --format '{{.Names}}' | grep -q "$OPENWEBUI_CONTAINER_NAME"; then
        if ! docker ps --format '{{.Names}}' | grep -q "$OPENWEBUI_CONTAINER_NAME"; then
            log "Iniciando container OpenWebUI..."
            if docker start "$OPENWEBUI_CONTAINER_NAME"; then success "Container OpenWebUI iniciado."; else { error "Falha ao iniciar OpenWebUI."; return 1; }; fi
        else
            success "Container OpenWebUI já está em execução."
        fi
    else
        warn "Container '$OPENWEBUI_CONTAINER_NAME' não encontrado. Use o instalador para configurá-lo."
    fi
}

stop_openwebui() {
    if command_exists docker && docker ps --format '{{.Names}}' | grep -q "$OPENWEBUI_CONTAINER_NAME"; then
        log "Parando container OpenWebUI..."
        if docker stop "$OPENWEBUI_CONTAINER_NAME"; then success "Container OpenWebUI parado."; else { error "Falha ao parar OpenWebUI."; return 1; }; fi
    else
        log "Container OpenWebUI não estava em execução."
    fi
}


# --- Funções de Ações em Massa (Orquestradores) ---

start_all_services() {
    section "Iniciando TODOS os Serviços Locais"
    
    subsection "Iniciando serviço Ollama..."
    start_ollama || { error "Falha ao iniciar Ollama. Abortando."; return 1; }
    
    subsection "Iniciando cluster Dask..."
    start_dask || { error "Falha ao iniciar Dask. Abortando."; return 1; }
    
    subsection "Iniciando container OpenWebUI..."
    start_openwebui || { error "Falha ao iniciar OpenWebUI. Abortando."; return 1; }

    success "Todos os serviços locais foram iniciados."
}

stop_all_services() {
    local any_failed=false
    section "Parando TODOS os Serviços Locais"
    # Ordem de parada otimizada: dependentes primeiro
    subsection "Parando container OpenWebUI"
    stop_openwebui || any_failed=true
    subsection "Parando Cluster Dask"
    stop_dask # pkill não retorna erro se o processo não existe, então não precisa de ||
    subsection "Parando serviço Ollama"
    stop_ollama || any_failed=true

    if [ "$any_failed" = true ]; then
        warn "Um ou mais serviços não puderam ser parados corretamente. Verifique os logs."
        return 1
    else
        success "Todos os serviços locais foram parados."
        return 0
    fi
}

restart_all_services() {
    section "Reiniciando todos os serviços locais"
    stop_all_services || warn "Alguns serviços não puderam ser parados corretamente, mas a inicialização continuará."
    echo ""
    start_all_services || error "Falha ao reiniciar um ou mais serviços."
}

# --- Funções de Sub-Menu ---

show_service_management_menu() {
    subsection "Gerenciamento de Serviços Locais Individuais"
    
    # Status do Ollama
    if service_active "$OLLAMA_SERVICE_NAME"; then
        echo -e "1. Ollama          (Status: ${GREEN}ATIVO${NC}   | Ação: Parar)"
    else
        echo -e "1. Ollama          (Status: ${RED}INATIVO${NC}  | Ação: Iniciar)"
    fi

    # Status do Dask
    if pgrep -f "$DASK_SCHEDULER_PROCESS" > /dev/null; then
        echo -e "2. Dask            (Status: ${GREEN}ATIVO${NC}   | Ação: Parar)"
    else
        echo -e "2. Dask            (Status: ${RED}INATIVO${NC}  | Ação: Iniciar)"
    fi

    # Status do OpenWebUI
    if command_exists docker && docker ps --format '{{.Names}}' | grep -q "$OPENWEBUI_CONTAINER_NAME"; then
        echo -e "3. OpenWebUI (Docker) (Status: ${GREEN}ATIVO${NC}   | Ação: Parar)"
    else
        echo -e "3. OpenWebUI (Docker) (Status: ${RED}INATIVO${NC}  | Ação: Iniciar)"
    fi

    echo "---"
    echo "4. Voltar ao menu principal"
}

run_service_management_menu() {
    while true; do
        clear
        show_service_management_menu
        read -p "Selecione uma opção [1-4]: " choice
        case $choice in
            1) 
                if service_active "$OLLAMA_SERVICE_NAME"; then
                    audit_log "stop_ollama" "ATTEMPT" "From sub-menu"
                    if confirm_operation "Ollama está ATIVO. Deseja pará-lo?" && stop_ollama; then
                        audit_log "stop_ollama" "SUCCESS"
                    else
                        audit_log "stop_ollama" "FAIL/CANCEL"
                    fi
               else
                    audit_log "start_ollama" "ATTEMPT" "From sub-menu"
                    if confirm_operation "Ollama está INATIVO. Deseja iniciá-lo?" && start_ollama; then
                        audit_log "start_ollama" "SUCCESS"
                    else
                        audit_log "start_ollama" "FAIL/CANCEL"
                    fi
               fi
               ;;
            2)
                if pgrep -f "$DASK_SCHEDULER_PROCESS" > /dev/null; then
                    audit_log "stop_dask" "ATTEMPT" "From sub-menu"
                    if confirm_operation "Dask está ATIVO. Deseja pará-lo?" && stop_dask; then
                        audit_log "stop_dask" "SUCCESS"
                    else
                        audit_log "stop_dask" "FAIL/CANCEL"
                    fi
               else
                    audit_log "start_dask" "ATTEMPT" "From sub-menu"
                    if confirm_operation "Dask está INATIVO. Deseja iniciá-lo?" && start_dask; then
                        audit_log "start_dask" "SUCCESS"
                    else
                        audit_log "start_dask" "FAIL/CANCEL"
                    fi
               fi
               ;;
            3)
                if command_exists docker && docker ps --format '{{.Names}}' | grep -q "$OPENWEBUI_CONTAINER_NAME" 2>/dev/null; then
                    audit_log "stop_openwebui" "ATTEMPT" "From sub-menu"
                    if confirm_operation "OpenWebUI está ATIVO. Deseja pará-lo?" && stop_openwebui; then
                        audit_log "stop_openwebui" "SUCCESS"
                    else
                        audit_log "stop_openwebui" "FAIL/CANCEL"
                    fi
               else
                    audit_log "start_openwebui" "ATTEMPT" "From sub-menu"
                    if confirm_operation "OpenWebUI está INATIVO. Deseja iniciá-lo?" && start_openwebui; then
                        audit_log "start_openwebui" "SUCCESS"
                    else
                        audit_log "start_openwebui" "FAIL/CANCEL"
                    fi
               fi
               ;;
            4) break ;;
            *) warn "Opção inválida." ;;
        esac
        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

run_remote_worker_menu() {
    local remote_manager_script="${SCRIPTS_DIR}/management/remote_worker_manager.sh"
    if [ ! -f "$remote_manager_script" ]; then
        error "Script de gerenciamento remoto não encontrado em $remote_manager_script"
        return 1
    fi

    while true; do
        clear
        section "Gerenciamento de Workers Remotos (SSH)"
        echo "1. Iniciar workers em TODOS os nós remotos"
        echo "2. Parar workers em TODOS os nós remotos"
        echo "3. Mostrar status dos workers remotos"
        echo "4. ➕ Adicionar e configurar um novo worker"
        echo "5. 🚀 Executar comando em TODOS os nós"
        echo "6. 📱 Configurar um worker Android (Termux)"
        echo "7. 🔗 Verificar conectividade SSH com os nós"
        echo "---"
        echo "8. Voltar ao menu principal"

        read -p "Selecione uma opção [1-8]: " choice
        case $choice in
            1)
                read -p "Digite o IP do Dask Scheduler (este nó): " scheduler_ip
                if [ -n "$scheduler_ip" ]; then
                    audit_log "remote_worker_start" "ATTEMPT"
                    bash "$remote_manager_script" start "$scheduler_ip"
                else
                    warn "IP do Scheduler é necessário."
                fi
                ;;
            2)
                audit_log "remote_worker_stop" "ATTEMPT"
                bash "$remote_manager_script" stop
                ;;
            3)
                audit_log "remote_worker_status" "EXECUTE"
                bash "$remote_manager_script" status
                ;;
            4)
                audit_log "setup_new_worker" "EXECUTE"
                bash "${SCRIPTS_DIR}/deployment/setup_new_worker.sh"
                ;;
            5)
                read -p "Digite o comando a ser executado remotamente: " cmd_to_run
                if [ -n "$cmd_to_run" ]; then
                    audit_log "remote_worker_exec" "ATTEMPT" "Command: $cmd_to_run"
                    bash "$remote_manager_script" exec "$cmd_to_run"
                else
                    warn "Comando não pode ser vazio."
                fi
                ;;
            6)
                audit_log "setup_android_worker" "GUIDE"
                subsection "Passo 1: Guia para Configurar Worker Android (Termux)"
                info "Para configurar seu dispositivo Android como um worker, siga estes passos:"
                echo "1. Instale o aplicativo 'Termux' da F-Droid ou Play Store no seu Android."
                echo "2. Abra o Termux e execute o seguinte comando para baixar e rodar o script de configuração:"
                echo ""
                warn "   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash"
                echo ""
                info "3. O script irá guiá-lo pelo resto do processo no seu dispositivo. Copie a chave SSH pública ao final."
                
                if confirm_operation "Você completou os passos acima e copiou a chave SSH? Deseja registrar o worker agora?"; then
                    subsection "Passo 2: Registrando o Worker no Servidor"
                    bash "${SCRIPTS_DIR}/deployment/register_worker_node.sh"
                fi
                ;;
            7)
                audit_log "remote_worker_check_ssh" "EXECUTE"
                bash "$remote_manager_script" check-ssh
                ;;
            8) break ;;
            *) warn "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

# --- Funções Principais ---
show_status() {
    section "Status Geral do Cluster"
    
    subsection "Serviço Ollama"
    if command_exists "$OLLAMA_SERVICE_NAME"; then
        if service_active "$OLLAMA_SERVICE_NAME"; then
            success "Ollama: Ativo"
            ollama ps 2>/dev/null | head -n 5
        else
            warn "Ollama: Inativo"
        fi
    else
        log "Ollama: Não instalado"
    fi

    subsection "Cluster Dask"
    if pgrep -f "$DASK_SCHEDULER_PROCESS" > /dev/null; then
        success "Dask Scheduler: Ativo"
    else
        warn "Dask Scheduler: Inativo"
    fi
    local worker_count
    worker_count=$(pgrep -f "$DASK_WORKER_PROCESS" | wc -l)
    if [ "$worker_count" -gt 0 ]; then
        success "Dask Workers: $worker_count ativos"
    else
        warn "Dask Workers: Nenhum ativo"
    fi

    subsection "Workers Dask Remotos"
    local remote_manager_script="${SCRIPTS_DIR}/management/remote_worker_manager.sh"
    local nodes_list_file="$HOME/.cluster_config/nodes_list.conf"
    if [ -f "$remote_manager_script" ] && [ -f "$nodes_list_file" ] && [ -s "$nodes_list_file" ]; then
        bash "$remote_manager_script" status
    else
        log "Nenhum nó remoto configurado. Pule esta verificação."
    fi

    subsection "Containers Docker"
    if command_exists docker && docker info >/dev/null 2>&1; then
        log "Containers em execução:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        warn "Docker: Daemon não está em execução ou não está instalado."
    fi
}

run_health_check() {
    section "Running Health Check"
    bash "${UTILS_DIR}/health_check.sh"
}

run_optimizer() {
    local optimizer_script="${SCRIPTS_DIR}/management/resource_optimizer.sh"
    if [ ! -f "$optimizer_script" ]; then
        error "Script do otimizador não encontrado em $optimizer_script"
        return 1
    fi

    while true; do
        clear
        section "Otimizador de Recursos"
        bash "$optimizer_script" status # Show local status on menu
        echo "---"
        echo "1. Otimizar este nó (Local)"
        echo "2. Otimizar TODOS os nós remotos"
        echo "3. Restaurar configurações otimizadas (Local)"
        echo "---"
        echo "4. Voltar ao menu principal"
        read -p "Selecione uma opção [1-4]: " choice

        case $choice in
            1)
                audit_log "optimizer_local" "EXECUTE"
                if confirm_operation "Deseja otimizar as configurações deste nó local?"; then
                    bash "$optimizer_script" optimize
                fi
                ;;
            2)
                audit_log "optimizer_remote" "EXECUTE"
                run_remote_optimization
                ;;
            3)
                audit_log "optimizer_restore" "EXECUTE"
                if confirm_operation "Deseja restaurar as configurações locais para a versão anterior à última otimização?"; then
                    bash "$optimizer_script" restore
                fi
                ;;
            4) break ;;
            *) warn "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

run_remote_optimization() {
    local nodes_file="$HOME/.cluster_config/nodes_list.conf"
    if [ ! -f "$nodes_file" ] || [ ! -s "$nodes_file" ]; then
        warn "Arquivo de lista de nós não encontrado ou vazio. Nenhum nó remoto para otimizar."
        return
    fi

    subsection "Iniciando Otimização Remota"
    while read -r hostname ip user port; do
        if [ -z "$hostname" ]; then continue; fi
        
        log "Otimizando nó: $user@$hostname ($ip)..."
        local remote_tmp_dir="/tmp/cluster_ai_optimizer_$$"
        local optimizer_cmd="bash '$remote_tmp_dir/resource_optimizer.sh' optimize -y"

        # Detecta se é um nó Android pela porta e aplica o perfil correto
        if [[ "${port:-22}" == "8022" ]]; then
            info "   -> Perfil Android detectado (porta 8022). Aplicando otimização conservadora."
            optimizer_cmd="bash '$remote_tmp_dir/resource_optimizer.sh' optimize --profile android -y"
        fi

        # 1. Criar diretório temporário remoto e copiar scripts
        if ssh -p "${port:-22}" "$user@$hostname" "mkdir -p '$remote_tmp_dir/scripts/utils'" && \
           scp -P "${port:-22}" "${SCRIPTS_DIR}/management/resource_optimizer.sh" "$user@$hostname:$remote_tmp_dir/resource_optimizer.sh" >/dev/null && \
           scp -P "${port:-22}" "${UTILS_DIR}/common.sh" "$user@$hostname:$remote_tmp_dir/scripts/utils/common.sh" >/dev/null; then
            # 2. Executar o otimizador remotamente em modo não-interativo e depois limpar
            ssh -p "${port:-22}" "$user@$hostname" "$optimizer_cmd && rm -rf '$remote_tmp_dir'" || error "Falha na execução do otimizador em $hostname"
        else
            error "Falha ao copiar scripts para $hostname. Verifique a conectividade SSH."
        fi
    done < <(grep -vE '^\s*(#|$)' "$nodes_file")
    success "Otimização remota concluída para todos os nós."
}

run_config_manager() {
    section "Gerenciador de Configurações de Otimização"
    bash "${SCRIPTS_DIR}/management/config_manager.sh" "$@"
}

run_installer() {
    section "Acessando Instalador/Configurador"
    log "Iniciando o script de instalação principal..."
    bash "${PROJECT_ROOT}/install.sh"
}

view_audit_log() {
    section "Log de Auditoria"
    if [ -f "$AUDIT_LOG_FILE" ]; then
        # Mostra as últimas 20 linhas
        tail -n 20 "$AUDIT_LOG_FILE"
    else
        warn "Nenhum log de auditoria encontrado."
    fi
}

run_log_rotator() {
    section "Rotacionando Logs de Auditoria"
    bash "${SCRIPTS_DIR}/maintenance/log_rotator.sh"
}

run_cron_setup() {
    section "Agendando Rotação de Logs"
    bash "${SCRIPTS_DIR}/maintenance/setup_cron_job.sh"
}

run_monitor_setup() {
    section "Configurando Serviço de Monitoramento"
    sudo bash "${SCRIPTS_DIR}/deployment/setup_monitor_service.sh"
}

run_readme_generator() {
    section "Gerando Documentação README.md"
    warn "Script de geração de README não encontrado. Funcionalidade não implementada ainda."
}

run_linter() {
    section "Verificando Qualidade do Código com ShellCheck"
    bash "${SCRIPTS_DIR}/maintenance/run_linter.sh"
}

run_auto_updater() {
    section "Atualizando o Projeto via Git"
    bash "${SCRIPTS_DIR}/maintenance/auto_updater.sh"
}

run_backup_manager() {
    local backup_script="${SCRIPTS_DIR}/maintenance/backup_manager.sh"
    if [ ! -f "$backup_script" ]; then
        error "Script de backup não encontrado em $backup_script"
        return 1
    fi

    while true; do
        clear
        section "Gerenciador de Backups"
        echo "1. 💾 Fazer Backup Completo (config, modelos, docker)"
        echo "2. ⚙️ Fazer Backup apenas das Configurações"
        echo "3. 🧠 Fazer Backup apenas dos Modelos Ollama"
        echo "4. 🐳 Fazer Backup apenas dos Dados Docker"
        echo "5. 🖧 Fazer Backup Apenas dos Workers Remotos"
        echo "6. 🔄 Restaurar a partir de um backup"
        echo "---"
        echo "7. 📋 Listar Backups existentes"
        echo "8. 🗑️ Limpar Backups antigos"
        echo "---"
        echo "9. ↩️ Voltar ao menu principal"
        read -p "Selecione uma opção [1-9]: " choice

        case $choice in
            1) audit_log "backup_full" "EXECUTE"; bash "$backup_script" full ;;
            2) audit_log "backup_config" "EXECUTE"; bash "$backup_script" config ;;
            3) audit_log "backup_models" "EXECUTE"; bash "$backup_script" models ;;
            4) audit_log "backup_docker" "EXECUTE"; bash "$backup_script" docker-data ;;
            5) audit_log "backup_remote" "EXECUTE"; bash "$backup_script" remote-workers ;;
            6) 
               audit_log "restore_start" "EXECUTE"
               bash "${SCRIPTS_DIR}/maintenance/restore_manager.sh"
               ;;
            7) audit_log "backup_list" "EXECUTE"; bash "$backup_script" list ;;
            8) audit_log "backup_cleanup" "EXECUTE"; bash "$backup_script" cleanup ;;
            9) break ;;
            *) warn "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

run_performance_reporter() {
    section "Gerando Relatório de Performance"
    bash "${PROJECT_ROOT}/generate_performance_report.sh"
}

run_model_installer() {
    local model_installer_script="${SCRIPTS_DIR}/management/install_models.sh"
    if [ ! -f "$model_installer_script" ]; then
        error "Script de instalação de modelos não encontrado em $model_installer_script"
        return 1
    fi
    section "Instalador de Modelos Ollama"
    bash "$model_installer_script"
}

run_model_remover() {
    local model_remover_script="${SCRIPTS_DIR}/management/remove_models.sh"
    if [ ! -f "$model_remover_script" ]; then
        error "Script de remoção de modelos não encontrado em $model_remover_script"
        return 1
    fi
    section "Removedor de Modelos Ollama"
    bash "$model_remover_script"
}

main() {
    while true; do
        # clear # Removido para manter o contexto visível após uma ação
        show_menu
        read -p "Selecione uma opção [1-21]: " choice
        case $choice in
            1) audit_log "start_all" "ATTEMPT"; start_all_services && audit_log "start_all" "SUCCESS" || audit_log "start_all" "FAIL" ;;
            2) audit_log "stop_all" "ATTEMPT"; stop_all_services && audit_log "stop_all" "SUCCESS" || audit_log "stop_all" "FAIL" ;;
            3) audit_log "restart_all" "ATTEMPT"; restart_all_services && audit_log "restart_all" "SUCCESS" || audit_log "restart_all" "FAIL" ;;
            4) audit_log "manage_local_individual" "ENTER"; run_service_management_menu; audit_log "manage_local_individual" "EXIT" ;;
            5) audit_log "manage_remote_workers" "ENTER"; run_remote_worker_menu; audit_log "manage_remote_workers" "EXIT" ;;
            6) audit_log "show_status" "EXECUTE"; show_status ;;
            7) audit_log "run_health_check" "EXECUTE"; run_health_check ;;
            8) audit_log "run_optimizer" "EXECUTE"; run_optimizer ;;
            9) audit_log "install_models" "ENTER"; run_model_installer; audit_log "install_models" "EXIT" ;;
            10) audit_log "remove_models" "ENTER"; run_model_remover; audit_log "remove_models" "EXIT" ;;
            11) 
               subsection "Gerenciador de Configurações"
               echo "Opções disponíveis: backup, restore, list"
               read -p "Digite o comando desejado: " config_cmd
               audit_log "config_manager" "ATTEMPT" "Command: $config_cmd"
               if run_config_manager "$config_cmd"; then
                   audit_log "config_manager" "SUCCESS" "Command: $config_cmd"
               else
                   audit_log "config_manager" "FAIL" "Command: $config_cmd"
               fi
               ;;
            12) 
               audit_log "run_installer" "EXECUTE"
               run_installer; break 
               ;;
            13) audit_log "view_audit_log" "EXECUTE"; view_audit_log ;;
            14) audit_log "discover_nodes" "EXECUTE"; bash "${SCRIPTS_DIR}/management/discover_nodes.sh" ;;
            15) audit_log "run_log_rotator" "EXECUTE"; run_log_rotator ;;
            16) audit_log "setup_cron" "EXECUTE"; run_cron_setup ;;
            17) audit_log "setup_monitor" "EXECUTE"; run_monitor_setup ;;
            18) audit_log "generate_readme" "EXECUTE"; run_readme_generator ;;
            19) audit_log "run_linter" "EXECUTE"; run_linter ;;
            20) audit_log "run_updater" "EXECUTE"; run_auto_updater ;;
            21) audit_log "backup_manager" "ENTER"; run_backup_manager; audit_log "backup_manager" "EXIT" ;;
            22) audit_log "run_perf_report" "EXECUTE"; run_performance_reporter ;;
            23) audit_log "exit_manager" "EXECUTE"; log "Saindo..."; exit 0 ;;
            *) warn "Opção inválida";;
        esac
        echo ""
        # Ação do usuário concluída, o menu será exibido novamente.
    done
}

main "$@"
