#!/bin/bash

# 🗑️ DESINSTALAÇÃO INTELIGENTE - Cluster AI
# Sistema avançado de desinstalação seletiva por áreas

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
CONFIG_FILE="$PROJECT_ROOT/cluster.conf"
VENV_DIR="$PROJECT_ROOT/.venv"
OLLAMA_DIR="$HOME/.ollama"
OPENWEBUI_DIR="$HOME/.open-webui"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/configs/docker/compose-basic.yml"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Funções auxiliares ---
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🗑️ DESINSTALAÇÃO INTELIGENTE - CLUSTER AI 🗑️${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
}

detect_installation_type() {
    local install_type="unknown"

    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "role.*server" "$CONFIG_FILE" 2>/dev/null; then
            install_type="server"
        elif grep -q "role.*worker" "$CONFIG_FILE" 2>/dev/null; then
            install_type="worker"
        fi
    fi

    if [ -d "/data/data/com.termux" ]; then
        install_type="android_worker"
    fi

    echo "$install_type"
}

show_uninstall_menu() {
    local install_type=$(detect_installation_type)

    echo "Selecione os componentes para desinstalar:"
    echo
    echo "🏠 COMPONENTES BÁSICOS:"
    echo "1) Ambiente Virtual Python (.venv)"
    echo "2) Arquivo de Configuração (cluster.conf)"
    echo "3) Arquivos Temporários (__pycache__, *.pyc)"
    echo "4) Logs do Sistema"
    echo

    if [ "$install_type" = "server" ]; then
        echo "🖥️  COMPONENTES DO SERVIDOR:"
        echo "5) 🐳 Docker - Parar e remover containers"
        echo "6) 📊 Dask - Scheduler e Workers"
        echo "7) 🌐 Nginx - Servidor web"
        echo "8) 🧠 Ollama - Serviço de IA"
        echo "9) 🤖 Modelos de IA (Ollama)"
        echo "10) 🌐 OpenWebUI - Interface web"
        echo "11) 🧠 Ollama + Modelos (Completo)"
        echo "12) 📊 Dask + Workers (Completo)"
        echo "13) 🌐 Servidores Web (Nginx + OpenWebUI)"
        echo
    fi

    echo "🧹 LIMPEZA GERAL:"
    echo "14) Configurações do Sistema (integrações IDE)"
    echo "15) Cache e Dados Temporários"
    echo "16) Backup de Dados Importantes"
    echo
    echo "💥 DESINSTALAÇÕES COMPLETAS:"
    echo "17) Desinstalação Parcial (múltipla seleção)"
    echo "18) Desinstalação Completa (REMOVER TUDO)"
    echo "19) Análise de Desinstalação (ver o que será removido)"
    echo
    echo "0) ❌ Cancelar"
    echo
}

# --- Funções de Desinstalação por Área ---

uninstall_python_env() {
    subsection "🗑️ Removendo Ambiente Virtual Python"

    if [ -d "$VENV_DIR" ]; then
        local size=$(du -sh "$VENV_DIR" 2>/dev/null | cut -f1)
        warn "Removendo ambiente virtual: $VENV_DIR (${size})"

        if confirm_operation "Confirmar remoção do ambiente Python?"; then
            rm -rf "$VENV_DIR"
            success "✅ Ambiente virtual Python removido!"
        else
            warn "Remoção cancelada."
        fi
    else
        success "✅ Ambiente virtual não encontrado (já removido)."
    fi
}

uninstall_config() {
    subsection "🗑️ Removendo Arquivo de Configuração"

    if [ -f "$CONFIG_FILE" ]; then
        warn "Removendo arquivo de configuração: $CONFIG_FILE"

        if confirm_operation "Fazer backup antes de remover?"; then
            cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
            success "Backup criado: ${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        rm -f "$CONFIG_FILE"
        success "✅ Arquivo de configuração removido!"
    else
        success "✅ Arquivo de configuração não encontrado (já removido)."
    fi
}

uninstall_temp_files() {
    subsection "🗑️ Removendo Arquivos Temporários"

    local temp_patterns=(
        "$PROJECT_ROOT/__pycache__"
        "$PROJECT_ROOT/.pytest_cache"
        "$PROJECT_ROOT/*.pyc"
        "$PROJECT_ROOT/.coverage"
        "$PROJECT_ROOT/coverage.xml"
        "$PROJECT_ROOT/.DS_Store"
        "$PROJECT_ROOT/Thumbs.db"
    )

    local removed=0
    for pattern in "${temp_patterns[@]}"; do
        if [ -e "$pattern" ]; then
            rm -rf "$pattern" 2>/dev/null && ((removed++))
        fi
    done

    # Limpar pycache recursivamente
    local pycache_count=$(find "$PROJECT_ROOT" -type d -name "__pycache__" 2>/dev/null | wc -l)
    if [ "$pycache_count" -gt 0 ]; then
        find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
        removed=$((removed + pycache_count))
    fi

    success "✅ $removed tipos de arquivos temporários removidos!"
}

uninstall_logs() {
    subsection "🗑️ Removendo Logs do Sistema"

    local log_dir="$PROJECT_ROOT/logs"
    if [ -d "$log_dir" ]; then
        local log_count=$(find "$log_dir" -name "*.log" 2>/dev/null | wc -l)
        local size=$(du -sh "$log_dir" 2>/dev/null | cut -f1)

        if [ "$log_count" -gt 0 ]; then
            warn "Encontrados $log_count arquivos de log (${size})"

            if confirm_operation "Remover todos os logs?"; then
                rm -rf "$log_dir"
                success "✅ Logs removidos!"
            else
                warn "Remoção de logs cancelada."
            fi
        else
            success "✅ Nenhum log encontrado."
        fi
    else
        success "✅ Diretório de logs não existe."
    fi
}

uninstall_docker() {
    subsection "🗑️ Removendo Containers Docker"

    if ! command_exists docker; then
        warn "Docker não está instalado."
        return 0
    fi

    if ! docker info >/dev/null 2>&1; then
        warn "Docker não está acessível."
        return 0
    fi

    # Listar containers relacionados
    local containers=$(docker ps -a --filter "name=cluster-ai\|open-webui\|ollama" --format "{{.Names}}" 2>/dev/null)
    if [ -n "$containers" ]; then
        echo "Containers encontrados:"
        echo "$containers" | nl

        if confirm_operation "Parar e remover estes containers?"; then
            echo "$containers" | xargs docker stop 2>/dev/null || true
            echo "$containers" | xargs docker rm 2>/dev/null || true
            success "✅ Containers Docker removidos!"
        else
            warn "Remoção de containers cancelada."
        fi
    else
        success "✅ Nenhum container relacionado encontrado."
    fi
}

uninstall_dask() {
    subsection "🗑️ Removendo Dask (Scheduler e Workers)"

    log "Parando processos Dask..."
    pkill -f "dask-scheduler" 2>/dev/null || true
    pkill -f "dask-worker" 2>/dev/null || true

    sleep 2

    local dask_processes=$(pgrep -f dask 2>/dev/null | wc -l)
    if [ "$dask_processes" -eq 0 ]; then
        success "✅ Dask parado com sucesso!"
    else
        warn "Ainda restam $dask_processes processos Dask."
    fi
}

uninstall_nginx() {
    subsection "🗑️ Removendo Nginx"

    if ! command_exists nginx; then
        warn "Nginx não está instalado."
        return 0
    fi

    log "Parando Nginx..."
    sudo systemctl stop nginx 2>/dev/null || sudo service nginx stop 2>/dev/null || true

    if ! sudo systemctl is-active nginx >/dev/null 2>&1; then
        success "✅ Nginx parado!"
    else
        warn "Não foi possível parar o Nginx."
    fi
}

uninstall_ollama() {
    subsection "🗑️ Removendo Ollama"

    log "Parando processos Ollama..."
    pkill -f ollama 2>/dev/null || true

    sleep 2

    local ollama_processes=$(pgrep -f ollama 2>/dev/null | wc -l)
    if [ "$ollama_processes" -eq 0 ]; then
        success "✅ Ollama parado!"
    else
        warn "Ainda restam $ollama_processes processos Ollama."
    fi
}

uninstall_models() {
    subsection "🗑️ Removendo Modelos de IA"

    if [ -d "$OLLAMA_DIR" ]; then
        local size=$(du -sh "$OLLAMA_DIR" 2>/dev/null | cut -f1)
        warn "Removendo modelos de IA: $OLLAMA_DIR (${size})"

        if confirm_operation "Confirmar remoção dos modelos de IA?"; then
            rm -rf "$OLLAMA_DIR"
            success "✅ Modelos de IA removidos!"
        else
            warn "Remoção cancelada."
        fi
    else
        success "✅ Diretório de modelos não encontrado."
    fi
}

uninstall_openwebui() {
    subsection "🗑️ Removendo OpenWebUI"

    # Parar container
    if command_exists docker && docker info >/dev/null 2>&1; then
        docker stop open-webui 2>/dev/null || true
        docker rm open-webui 2>/dev/null || true
    fi

    # Remover diretório local se existir
    if [ -d "$OPENWEBUI_DIR" ]; then
        rm -rf "$OPENWEBUI_DIR" 2>/dev/null || true
    fi

    success "✅ OpenWebUI removido!"
}

uninstall_ollama_full() {
    subsection "🗑️ Removendo Ollama + Modelos (Completo)"

    warn "Esta opção irá remover Ollama E todos os modelos de IA."

    if confirm_operation "Continuar com remoção completa?"; then
        uninstall_ollama
        uninstall_models
        success "✅ Ollama + Modelos removidos completamente!"
    fi
}

uninstall_dask_full() {
    subsection "🗑️ Removendo Dask + Workers (Completo)"

    warn "Esta opção irá parar todos os processos Dask."

    if confirm_operation "Continuar?"; then
        uninstall_dask
        success "✅ Dask + Workers removidos!"
    fi
}

uninstall_web_servers() {
    subsection "🗑️ Removendo Servidores Web (Nginx + OpenWebUI)"

    warn "Esta opção irá remover Nginx e OpenWebUI."

    if confirm_operation "Continuar?"; then
        uninstall_nginx
        uninstall_openwebui
        success "✅ Servidores web removidos!"
    fi
}

uninstall_system_config() {
    subsection "🗑️ Removendo Configurações do Sistema"

    local configs_removed=0

    # Remover integrações IDE
    if [ -d "$HOME/.vscode/extensions/cluster-ai" ]; then
        rm -rf "$HOME/.vscode/extensions/cluster-ai" && ((configs_removed++))
    fi

    if [ -d "$HOME/.config/JetBrains/PyCharm*/options/cluster_ai.xml" ]; then
        rm -rf "$HOME/.config/JetBrains/PyCharm*/options/cluster_ai.xml" && ((configs_removed++))
    fi

    # Remover atalhos
    local desktop_files=(
        "$HOME/.local/share/applications/cluster-ai.desktop"
        "$HOME/Desktop/cluster-ai.desktop"
        "/usr/share/applications/cluster-ai.desktop"
    )

    for desktop_file in "${desktop_files[@]}"; do
        if [ -f "$desktop_file" ]; then
            sudo rm -f "$desktop_file" 2>/dev/null || rm -f "$desktop_file" && ((configs_removed++))
        fi
    done

    success "✅ $configs_removed configurações do sistema removidas!"
}

uninstall_cache_temp() {
    subsection "🗑️ Removendo Cache e Dados Temporários"

    local cleaned=0

    # Limpar cache Python
    if [ -d "$HOME/.cache/pip" ]; then
        rm -rf "$HOME/.cache/pip" && ((cleaned++))
    fi

    # Limpar cache npm se existir
    if [ -d "$PROJECT_ROOT/node_modules/.cache" ]; then
        rm -rf "$PROJECT_ROOT/node_modules/.cache" && ((cleaned++))
    fi

    # Limpar temporários do sistema
    if [ -d "/tmp/cluster-ai*" ]; then
        rm -rf /tmp/cluster-ai* && ((cleaned++))
    fi

    success "✅ $cleaned caches e dados temporários removidos!"
}

create_backup() {
    subsection "💾 Criando Backup de Dados Importantes"

    local backup_dir="$PROJECT_ROOT/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/cluster_ai_backup_$timestamp.tar.gz"

    mkdir -p "$backup_dir"

    log "Criando backup em: $backup_file"

    # Arquivos para backup
    local backup_items=()

    [ -f "$CONFIG_FILE" ] && backup_items+=("$CONFIG_FILE")
    [ -d "$OLLAMA_DIR" ] && backup_items+=("$OLLAMA_DIR")
    [ -d "$OPENWEBUI_DIR" ] && backup_items+=("$OPENWEBUI_DIR")

    if [ ${#backup_items[@]} -gt 0 ]; then
        tar -czf "$backup_file" "${backup_items[@]}" 2>/dev/null
        local size=$(du -sh "$backup_file" 2>/dev/null | cut -f1)
        success "✅ Backup criado: $backup_file (${size})"
    else
        warn "Nenhum dado importante encontrado para backup."
    fi
}

uninstall_partial() {
    subsection "🗑️ Desinstalação Parcial (Múltipla Seleção)"

    echo "Selecione os componentes para remover (separados por espaço):"
    echo
    echo "1) Ambiente Virtual Python     8) Ollama"
    echo "2) Configuração               9) Modelos de IA"
    echo "3) Arquivos Temporários      10) OpenWebUI"
    echo "4) Logs                      11) Nginx"
    echo "5) Docker Containers         12) Configurações do Sistema"
    echo "6) Dask                      13) Cache e Temporários"
    echo "7) Ollama + Modelos"
    echo
    read -p "Digite os números (ex: 1 3 5): " selections

    for selection in $selections; do
        case $selection in
            1) uninstall_python_env ;;
            2) uninstall_config ;;
            3) uninstall_temp_files ;;
            4) uninstall_logs ;;
            5) uninstall_docker ;;
            6) uninstall_dask ;;
            7) uninstall_ollama_full ;;
            8) uninstall_ollama ;;
            9) uninstall_models ;;
            10) uninstall_openwebui ;;
            11) uninstall_nginx ;;
            12) uninstall_system_config ;;
            13) uninstall_cache_temp ;;
            *) warn "Opção inválida: $selection" ;;
        esac
        echo
    done

    success "✅ Desinstalação parcial concluída!"
}

uninstall_complete() {
    subsection "💥 Desinstalação Completa (REMOVER TUDO)"

    warn "⚠️  ATENÇÃO CRÍTICA ⚠️"
    echo
    echo "Esta opção irá remover COMPLETAMENTE o Cluster AI do sistema:"
    echo "• Ambiente Python e todas as dependências"
    echo "• Todos os containers Docker relacionados"
    echo "• Ollama e TODOS os modelos de IA"
    echo "• OpenWebUI e configurações"
    echo "• Arquivos de configuração e logs"
    echo "• Integrações com IDEs e sistema"
    echo
    echo "Esta ação NÃO PODE SER DESFEITA!"
    echo

    if confirm_operation "Você tem ABSOLUTA certeza que deseja continuar?"; then
        if confirm_operation "CONFIRME NOVAMENTE: Remover TUDO?"; then

            log "Criando backup final..."
            create_backup

            log "Executando desinstalação completa..."
            echo

            # Desinstalação em ordem segura
            uninstall_docker
            uninstall_dask
            uninstall_ollama_full
            uninstall_openwebui
            uninstall_nginx
            uninstall_python_env
            uninstall_config
            uninstall_temp_files
            uninstall_logs
            uninstall_system_config
            uninstall_cache_temp

            echo
            success "✅ DESINSTALAÇÃO COMPLETA CONCLUÍDA!"
            echo
            echo "O Cluster AI foi completamente removido do sistema."
            echo "Para reinstalar, execute: ./scripts/installation/install_intelligent.sh"
            echo

        fi
    else
        warn "Desinstalação completa cancelada."
    fi
}

analyze_uninstall() {
    subsection "🔍 Análise de Desinstalação"

    echo "Esta análise mostra o que SERÁ removido se você prosseguir:"
    echo

    local total_size=0
    local items_to_remove=()

    # Verificar cada componente
    if [ -d "$VENV_DIR" ]; then
        local size=$(du -s "$VENV_DIR" 2>/dev/null | cut -f1)
        total_size=$((total_size + size))
        items_to_remove+=("Ambiente Python (.venv): $(du -sh "$VENV_DIR" 2>/dev/null | cut -f1)")
    fi

    if [ -f "$CONFIG_FILE" ]; then
        items_to_remove+=("Arquivo de configuração: $CONFIG_FILE")
    fi

    if [ -d "$OLLAMA_DIR" ]; then
        local size=$(du -s "$OLLAMA_DIR" 2>/dev/null | cut -f1)
        total_size=$((total_size + size))
        items_to_remove+=("Modelos Ollama: $(du -sh "$OLLAMA_DIR" 2>/dev/null | cut -f1)")
    fi

    if [ -d "$OPENWEBUI_DIR" ]; then
        local size=$(du -s "$OPENWEBUI_DIR" 2>/dev/null | cut -f1)
        total_size=$((total_size + size))
        items_to_remove+=("OpenWebUI: $(du -sh "$OPENWEBUI_DIR" 2>/dev/null | cut -f1)")
    fi

    # Containers Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        local container_count=$(docker ps -a --filter "name=cluster-ai\|open-webui" --format "{{.Names}}" 2>/dev/null | wc -l)
        if [ "$container_count" -gt 0 ]; then
            items_to_remove+=("Containers Docker: $container_count containers")
        fi
    fi

    # Processos
    local dask_count=$(pgrep -f dask 2>/dev/null | wc -l)
    local ollama_count=$(pgrep -f ollama 2>/dev/null | wc -l)

    if [ "$dask_count" -gt 0 ]; then
        items_to_remove+=("Processos Dask: $dask_count processos")
    fi

    if [ "$ollama_count" -gt 0 ]; then
        items_to_remove+=("Processos Ollama: $ollama_count processos")
    fi

    # Resultado da análise
    if [ ${#items_to_remove[@]} -gt 0 ]; then
        echo "📋 ITENS QUE SERÃO REMOVIDOS:"
        echo
        for item in "${items_to_remove[@]}"; do
            echo "  🗑️  $item"
        done
        echo
        echo "💾 Espaço total a ser liberado: $(echo $total_size | awk '{print int($1/1024) "MB"}')"
        echo
        warn "⚠️  IMPORTANTE: Esta é apenas uma análise. Nada foi removido ainda."
    else
        success "✅ Nenhum componente do Cluster AI encontrado para remoção."
    fi
}

# --- Script Principal ---
main() {
    show_banner

    local install_type=$(detect_installation_type)
    echo -e "${BLUE}Tipo de instalação detectado:${NC} $(echo $install_type | tr '[:lower:]' '[:upper:]')"
    echo

    while true; do
        show_uninstall_menu

        local choice
        read -p "Digite sua opção (0-19): " choice

        case $choice in
            1) uninstall_python_env ;;
            2) uninstall_config ;;
            3) uninstall_temp_files ;;
            4) uninstall_logs ;;
            5) uninstall_docker ;;
            6) uninstall_dask ;;
            7) uninstall_nginx ;;
            8) uninstall_ollama ;;
            9) uninstall_models ;;
            10) uninstall_openwebui ;;
            11) uninstall_ollama_full ;;
            12) uninstall_dask_full ;;
            13) uninstall_web_servers ;;
            14) uninstall_system_config ;;
            15) uninstall_cache_temp ;;
            16) create_backup ;;
            17) uninstall_partial ;;
            18) uninstall_complete ;;
            19) analyze_uninstall ;;
            0)
                info "Desinstalação cancelada."
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                sleep 2
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
        show_banner
    done
}

# Executa o script principal
main
