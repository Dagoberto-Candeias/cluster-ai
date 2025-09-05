#!/bin/bash
# Local: install_unified.sh
# Autor: Dagoberto Candeias <betoallnet@gmail.com>

# =============================================================================
# Cluster AI - Instalador Unificado e Modular
# =============================================================================
# Este é o novo instalador principal que orquestra todos os scripts modulares
# de instalação, proporcionando uma experiência consistente e confiável.

set -euo pipefail

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Carrega funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

# Scripts modulares de instalação
SETUP_DEPENDENCIES="${SCRIPT_DIR}/scripts/installation/setup_dependencies.sh"
SETUP_PYTHON_ENV="${SCRIPT_DIR}/scripts/installation/setup_python_env.sh"
SETUP_DOCKER="${SCRIPT_DIR}/scripts/installation/setup_docker.sh"
SETUP_OLLAMA="${SCRIPT_DIR}/scripts/installation/setup_ollama.sh"
SETUP_OPENWEBUI="${SCRIPT_DIR}/scripts/installation/setup_openwebui.sh"

# Status dos componentes
declare -A COMPONENT_STATUS

# =============================================================================
# FUNÇÕES DE INSTALAÇÃO MODULAR
# =============================================================================

# Executa um script modular com tratamento de erros
run_modular_script() {
    local script_path="$1"
    local component_name="$2"
    local description="$3"

    subsection "$description"

    if [[ ! -f "$script_path" ]]; then
        warn "Script não encontrado: $script_path"
        COMPONENT_STATUS["$component_name"]="NOT_FOUND"
        return 1
    fi

    progress "Executando $component_name..."

    if bash "$script_path"; then
        success "$component_name concluído com sucesso"
        COMPONENT_STATUS["$component_name"]="SUCCESS"
        return 0
    else
        error "Falha na execução de $component_name"
        COMPONENT_STATUS["$component_name"]="FAILED"
        return 1
    fi
}

# Verifica o espaço em disco antes da instalação
# Retorna 0 se houver espaço suficiente, 1 caso contrário.
check_disk_space() {
    subsection "Verificando espaço em disco"

    # Estimativa conservadora do espaço necessário em MB para uma instalação completa
    # (Dependências, Docker, Python venv, Imagens Docker para Ollama/WebUI)
    local required_space_mb=6000 # 6 GB
    local required_space_kb=$((required_space_mb * 1024))

    log "Espaço estimado necessário: ${required_space_mb}MB"

    # Obtém o espaço disponível em KB no diretório do projeto
    local available_space_kb
    available_space_kb=$(df -k "$PROJECT_ROOT" | awk 'NR==2 {print $4}')

    if [ -z "$available_space_kb" ]; then
        error "Não foi possível determinar o espaço em disco disponível."
        return 1
    fi

    log "Espaço disponível: $((available_space_kb / 1024))MB"

    if [ "$available_space_kb" -lt "$required_space_kb" ]; then
        error "Espaço em disco insuficiente."
        info "São necessários pelo menos ${required_space_mb}MB, mas apenas $((available_space_kb / 1024))MB estão disponíveis."
        return 1
    fi

    success "Espaço em disco suficiente."
    return 0
}

# Instala dependências do sistema
install_system_dependencies() {
    run_modular_script "$SETUP_DEPENDENCIES" "dependencies" "Instalando Dependências do Sistema"
}

# Configura ambiente Python
setup_python_environment() {
    run_modular_script "$SETUP_PYTHON_ENV" "python_env" "Configurando Ambiente Python"
}

# Instala o Docker
setup_docker() {
    run_modular_script "$SETUP_DOCKER" "docker" "Instalando e Configurando o Docker"
}

# Configura Ollama
setup_ollama_service() {
    if [[ -f "$SETUP_OLLAMA" ]]; then
        run_modular_script "$SETUP_OLLAMA" "ollama" "Configurando Ollama"
    else
        warn "Script Ollama não encontrado - pulando"
        COMPONENT_STATUS["ollama"]="NOT_FOUND"
    fi
}

# Configura OpenWebUI
setup_openwebui_service() {
    if [[ -f "$SETUP_OPENWEBUI" ]]; then
        run_modular_script "$SETUP_OPENWEBUI" "openwebui" "Configurando OpenWebUI"
    else
        warn "Script OpenWebUI não encontrado - pulando"
        COMPONENT_STATUS["openwebui"]="NOT_FOUND"
    fi
}

# =============================================================================
# FUNÇÕES DE INSTALAÇÃO COMPLETA
# =============================================================================

# Instalação completa automatizada
install_complete() {
    section "🚀 Instalação Completa do Cluster AI"

    info "Esta instalação irá configurar:"
    echo "  ✅ Dependências do sistema"
    echo "  ✅ Docker Engine"
    echo "  ✅ Ambiente Python com todas as bibliotecas"
    echo "  ✅ Ollama (se disponível)"
    echo "  ✅ OpenWebUI (se disponível)"
    echo "  ✅ Configurações básicas do cluster"
    echo

    if ! confirm "Iniciar instalação completa?" "y"; then
        info "Instalação cancelada"
        return 0
    fi

    # Verificar espaço em disco antes de prosseguir
    if ! check_disk_space; then
        error "Instalação abortada devido à falta de espaço em disco."
        return 1
    fi

    local start_time=$(date +%s)
    local failed_components=()

    # Executa cada componente
    if ! install_system_dependencies; then
        failed_components+=("Dependências do Sistema")
    fi

    if ! setup_docker; then
        failed_components+=("Docker")
    fi

    if ! setup_python_environment; then
        failed_components+=("Ambiente Python")
    fi

    setup_ollama_service
    setup_openwebui_service

    # Cria configuração básica
    create_basic_config

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Relatório final
    section "📊 Relatório da Instalação"

    echo "Tempo total: ${duration}s"
    echo

    # Status dos componentes
    for component in "${!COMPONENT_STATUS[@]}"; do
        local status="${COMPONENT_STATUS[$component]}"
        case $status in
            SUCCESS)
                success "$component: OK"
                ;;
            FAILED)
                error "$component: FALHA"
                ;;
            NOT_FOUND)
                warn "$component: NÃO ENCONTRADO"
                ;;
        esac
    done

    echo

    # Verifica se houve falhas críticas
    if [[ ${#failed_components[@]} -gt 0 ]]; then
        error "Componentes com falha: ${failed_components[*]}"
        warn "Algumas funcionalidades podem não estar disponíveis"
        info "Execute novamente ou instale manualmente os componentes com falha"
        return 1
    else
        success "🎉 Instalação completa realizada com sucesso!"
        show_post_install_info
        return 0
    fi
}

# Instalação personalizada
install_custom() {
    section "🔧 Instalação Personalizada"

    info "Selecione os componentes para instalar:"

    local choices=()
    local descriptions=(
        "Dependências do Sistema (recomendado)"
        "Docker Engine (essencial)"
        "Ambiente Python (recomendado)"
        "Ollama"
        "OpenWebUI"
    )

    # Menu de seleção
    for i in "${!descriptions[@]}"; do
        local component_name
        case $i in
            0) component_name="dependencies" ;;
            1) component_name="docker" ;;
            2) component_name="python_env" ;;
            3) component_name="ollama" ;;
            4) component_name="openwebui" ;;
        esac

        if confirm "${descriptions[$i]}" "y"; then
            choices+=("$component_name")
        fi
    done

    if [[ ${#choices[@]} -eq 0 ]]; then
        warn "Nenhum componente selecionado"
        return 0
    fi

    # Executa componentes selecionados
    for choice in "${choices[@]}"; do
        case $choice in
            dependencies) install_system_dependencies ;;
            docker) setup_docker ;;
            python_env) setup_python_environment ;;
            ollama) setup_ollama_service ;;
            openwebui) setup_openwebui_service ;;
        esac
    done

    create_basic_config
    success "Instalação personalizada concluída"
}

# Reinstalação completa
reinstall_complete() {
    section "🔄 Reinstalação Completa do Cluster AI"

    info "Esta reinstalação irá sobrescrever todos os componentes:"
    echo "  ✅ Dependências do sistema"
    echo "  ✅ Docker Engine"
    echo "  ✅ Ambiente Python com todas as bibliotecas"
    echo "  ✅ Ollama (se disponível)"
    echo "  ✅ OpenWebUI (se disponível)"
    echo "  ✅ Configurações básicas do cluster"
    echo

    if ! confirm "Iniciar reinstalação completa?" "y"; then
        info "Reinstalação cancelada"
        return 0
    fi

    local start_time=$(date +%s)
    local failed_components=()

    # Executa cada componente
    if ! install_system_dependencies; then
        failed_components+=("Dependências do Sistema")
    fi

    if ! setup_docker; then
        failed_components+=("Docker")
    fi

    if ! setup_python_environment; then
        failed_components+=("Ambiente Python")
    fi

    setup_ollama_service
    setup_openwebui_service

    # Cria configuração básica
    create_basic_config

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Relatório final
    section "📊 Relatório da Reinstalação"

    echo "Tempo total: ${duration}s"
    echo

    # Status dos componentes
    for component in "${!COMPONENT_STATUS[@]}"; do
        local status="${COMPONENT_STATUS[$component]}"
        case $status in
            SUCCESS)
                success "$component: OK"
                ;;
            FAILED)
                error "$component: FALHA"
                ;;
            NOT_FOUND)
                warn "$component: NÃO ENCONTRADO"
                ;;
        esac
    done

    echo

    # Verifica se houve falhas críticas
    if [[ ${#failed_components[@]} -gt 0 ]]; then
        error "Componentes com falha: ${failed_components[*]}"
        warn "Algumas funcionalidades podem não estar disponíveis"
        info "Execute novamente ou instale manualmente os componentes com falha"
        return 1
    else
        success "🎉 Reinstalação completa realizada com sucesso!"
        show_post_install_info
        return 0
    fi
}

# Reparo da instalação
repair_installation() {
    section "🛠️ Reparo da Instalação"

    info "Verificando status da instalação atual..."

    if check_installation_status; then
        success "Instalação está OK. Nenhum reparo necessário."
        return 0
    fi

    info "Detectados componentes faltantes. Iniciando reparo..."

    local failed_components=()

    # Verifica e reinstala componentes faltantes
    if ! command_exists python3; then
        if ! install_system_dependencies; then
            failed_components+=("Dependências do Sistema")
        fi
    fi

    if ! command_exists docker; then
        if ! setup_docker; then
            failed_components+=("Docker")
        fi
    fi

    if ! dir_exists "${PROJECT_ROOT}/.venv"; then
        if ! setup_python_environment; then
            failed_components+=("Ambiente Python")
        fi
    fi

    if ! command_exists ollama; then
        setup_ollama_service
    fi

    # Verifica OpenWebUI (mais complexo, assume que se não estiver rodando, precisa reinstalar)
    # Para simplificar, sempre tenta configurar
    setup_openwebui_service

    # Recria configuração se necessário
    if ! file_exists "$CONFIG_FILE"; then
        create_basic_config
    fi

    if [[ ${#failed_components[@]} -gt 0 ]]; then
        error "Falha no reparo de: ${failed_components[*]}"
        return 1
    else
        success "🎉 Reparo da instalação concluído com sucesso!"
        return 0
    fi
}

# Desinstalação
uninstall_components() {
    section "🗑️ Desinstalação do Cluster AI"

    info "Esta operação irá remover os componentes instalados:"
    echo "  ❌ Ambiente Python virtual"
    echo "  ❌ Serviços Ollama e OpenWebUI"
    echo "  ❌ Configurações do cluster"
    echo "  ❌ Arquivos de backup (opcional)"
    echo

    if ! confirm "Iniciar desinstalação? Esta ação não pode ser desfeita completamente." "n"; then
        info "Desinstalação cancelada"
        return 0
    fi

    local start_time=$(date +%s)
    local failed_removals=()

    # Para o cluster se estiver rodando
    if file_exists "${PROJECT_ROOT}/manager.sh"; then
        info "Parando serviços do cluster..."
        bash "${PROJECT_ROOT}/manager.sh" stop 2>/dev/null || true
    fi

    # Remove ambiente virtual
    if dir_exists "${PROJECT_ROOT}/.venv"; then
        if rm -rf "${PROJECT_ROOT}/.venv"; then
            success "Ambiente virtual removido"
        else
            error "Falha ao remover ambiente virtual"
            failed_removals+=("Ambiente Virtual")
        fi
    fi

    # Para e remove serviços
    for service in ollama openwebui; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            if sudo systemctl stop "$service" && sudo systemctl disable "$service"; then
                success "Serviço parado: $service"
            else
                warn "Falha ao parar serviço: $service"
            fi
        fi
    done

    # Remove arquivos de configuração
    if file_exists "$CONFIG_FILE"; then
        if rm "$CONFIG_FILE"; then
            success "Arquivo de configuração removido"
        else
            warn "Falha ao remover arquivo de configuração"
        fi
    fi

    # Remove backups se confirmado
    if dir_exists "${PROJECT_ROOT}/backups"; then
        if confirm "Remover diretório de backups?" "n"; then
            if rm -rf "${PROJECT_ROOT}/backups"; then
                success "Backups removidos"
            else
                warn "Falha ao remover backups"
            fi
        fi
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    section "📊 Relatório da Desinstalação"

    echo "Tempo total: ${duration}s"
    echo

    if [[ ${#failed_removals[@]} -gt 0 ]]; then
        error "Falhas na remoção: ${failed_removals[*]}"
        return 1
    else
        success "🎉 Desinstalação concluída com sucesso!"
        info "Para reinstalar, execute o instalador novamente."
        return 0
    fi
}

# Cria configuração básica
create_basic_config() {
    subsection "Criando Configuração Básica"

    if file_exists "$CONFIG_FILE"; then
        if confirm "Arquivo de configuração já existe. Sobrescrever?"; then
            backup_file "$CONFIG_FILE"
        else
            info "Mantendo configuração existente"
            return 0
        fi
    fi

    progress "Criando configuração básica..."

    cat > "$CONFIG_FILE" << EOF
# Configuração básica do Cluster AI
# Gerada automaticamente em $(date)

# Diretórios
PROJECT_ROOT="$PROJECT_ROOT"
LOGS_DIR="$LOGS_DIR"
BACKUP_DIR="$BACKUP_DIR"

# Status da instalação
INSTALL_DATE="$(date)"
INSTALL_METHOD="unified_installer"

# Componentes instalados
$(for component in "${!COMPONENT_STATUS[@]}"; do
    echo "COMPONENT_${component^^}=\"${COMPONENT_STATUS[$component]}\""
done)
EOF

    success "Configuração criada: $CONFIG_FILE"
}

# =============================================================================
# FUNÇÕES DE VERIFICAÇÃO E DIAGNÓSTICO
# =============================================================================

# Verifica status da instalação
check_installation_status() {
    section "🔍 Verificação da Instalação"

    local checks=(
        "python3:Python 3"
        "pip:Pip"
        "docker:Docker"
        "ollama:Ollama"
    )

    local all_ok=true

    for check in "${checks[@]}"; do
        local cmd="${check%%:*}"
        local name="${check#*:}"

        if command_exists "$cmd"; then
            success "$name: OK"
        else
            warn "$name: NÃO ENCONTRADO"
            all_ok=false
        fi
    done

    # Verifica ambiente virtual
    if dir_exists "${PROJECT_ROOT}/.venv"; then
        success "Ambiente Virtual: OK"
    else
        warn "Ambiente Virtual: NÃO ENCONTRADO"
        all_ok=false
    fi

    # Verifica configuração
    if file_exists "$CONFIG_FILE"; then
        success "Configuração: OK"
    else
        warn "Configuração: NÃO ENCONTRADA"
        all_ok=false
    fi

    echo

    if [[ "$all_ok" == "true" ]]; then
        success "✅ Verificação: TODOS OS COMPONENTES OK"
        return 0
    else
        warn "⚠️  Verificação: ALGUNS COMPONENTES FALTANDO"
        info "Execute a instalação para corrigir"
        return 1
    fi
}

# Mostra informações pós-instalação
show_post_install_info() {
    section "🎯 Próximos Passos"

    echo "Para começar a usar o Cluster AI:"
    echo
    echo "1. 🌐 Ativar ambiente virtual:"
    echo "   source .venv/bin/activate"
    echo
    echo "2. ⚙️  Editar configuração (opcional):"
    echo "   nano cluster.conf"
    echo
    echo "3. 🚀 Iniciar o cluster:"
    echo "   ./manager.sh start"
    echo
    echo "4. 📊 Acessar interfaces:"
    echo "   • Dashboard Dask: http://localhost:8787"
    echo "   • OpenWebUI: http://localhost:3000"
    echo
    echo "5. 📚 Para ajuda:"
    echo "   ./manager.sh --help"
    echo
}

# =============================================================================
# FUNÇÕES DE INTERFACE
# =============================================================================

# Exibe banner do instalador
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🚀 CLUSTER AI - INSTALADOR UNIFICADO 🚀${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
    echo -e "${GREEN}Instalador modular e inteligente para o Cluster AI${NC}"
    echo -e "${BLUE}Versão: Unificada | Método: Modular${NC}"
    echo
}

# Exibe informações do sistema
show_system_info() {
    subsection "Informações do Sistema"

    local os=$(detect_os)
    local distro=$(detect_linux_distro)
    local arch=$(detect_arch)
    local pm=$(detect_package_manager)

    info "Sistema Operacional: $os"
    info "Distribuição: $distro"
    info "Arquitetura: $arch"
    info "Gerenciador de Pacotes: $pm"
    info "Diretório do Projeto: $PROJECT_ROOT"
    echo
}

# Menu principal
show_menu() {
    subsection "Menu de Instalação"

    echo "Escolha uma opção:"
    echo
    echo "🚀 INSTALAÇÃO:"
    echo "1) 📦 Instalação Completa (Recomendado)"
    echo "   - Instala todos os componentes automaticamente"
    echo "   - Configuração otimizada para produção"
    echo
    echo "2) 🔧 Instalação Personalizada"
    echo "   - Escolha quais componentes instalar"
    echo "   - Maior controle sobre o processo"
    echo
    echo "🔄 MANUTENÇÃO:"
    echo "3) 🔄 Reinstalação Completa"
    echo "   - Executa instalação completa novamente"
    echo "   - Sobrescreve componentes existentes"
    echo
    echo "4) 🛠️  Reparo da Instalação"
    echo "   - Verifica e reinstala componentes faltantes"
    echo "   - Corrige problemas de instalação"
    echo
    echo "5) 🗑️  Desinstalação"
    echo "   - Remove componentes instalados"
    echo "   - Usa sistema de rollback para reversão"
    echo
    echo "🔍 DIAGNÓSTICO:"
    echo "6) 📊 Verificar Status da Instalação"
    echo "   - Verifica componentes instalados"
    echo "   - Identifica problemas"
    echo
    echo "📚 INFORMAÇÕES:"
    echo "7) ℹ️  Sobre o Instalador"
    echo "   - Informações sobre o processo"
    echo
    echo "0) ❌ Sair"
    echo
}

# Mostra informações sobre o instalador
show_about() {
    section "ℹ️ Sobre o Instalador Unificado"

    echo "Este instalador utiliza uma abordagem modular:"
    echo
    echo "🏗️  ARQUITETURA MODULAR:"
    echo "• Scripts independentes em scripts/installation/"
    echo "• Cada componente pode ser instalado separadamente"
    echo "• Facilita manutenção e atualizações"
    echo
    echo "🔧 COMPONENTES PRINCIPAIS:"
    echo "• setup_dependencies.sh - Dependências do sistema"
    echo "• setup_python_env.sh - Ambiente Python"
    echo "• setup_ollama.sh - Serviço Ollama"
    echo "• setup_openwebui.sh - Interface Web"
    echo
    echo "✨ VANTAGENS:"
    echo "• Instalação mais rápida e confiável"
    echo "• Melhor tratamento de erros"
    echo "• Instalação segura do Docker"
    echo "• Logs detalhados e progresso"
    echo "• Rollback automático em caso de falha"
    echo
    echo "📊 STATUS DOS SCRIPTS:"
    for script in "$SETUP_DEPENDENCIES" "$SETUP_DOCKER" "$SETUP_PYTHON_ENV" "$SETUP_OLLAMA" "$SETUP_OPENWEBUI"; do
        if [[ -f "$script" ]]; then
            success "✓ $(basename "$script")"
        else
            warn "✗ $(basename "$script") (não encontrado)"
        fi
    done
    echo

    confirm "Voltar ao menu principal?" "y" || exit 0
}

# Processa a escolha do menu e retorna um status
# Retornos:
#   0: Sucesso, continuar loop
#   1: Sair do loop
#   2: Opção inválida
process_menu_choice() {
    local choice="$1"
    case $choice in
        1) install_complete ;;
        2) install_custom ;;
        3) reinstall_complete ;;
        4) repair_installation ;;
        5) uninstall_components ;;
        6) check_installation_status ;;
        7) show_about; return 0 ;; # 'show_about' já tem sua própria pausa
        0) info "Instalação cancelada pelo usuário"; return 1 ;;
        *) error "Opção inválida. Tente novamente."; sleep 2; return 2 ;;
    esac

    # Para as opções que executam uma ação, perguntar se deseja continuar
    echo
    if ! confirm "Voltar ao menu principal?" "y"; then
        return 1 # Sinaliza para sair
    fi
    return 0 # Sinaliza para continuar
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Verificações iniciais
    if is_root; then
        error "Não execute o instalador como root. Use: ./install_unified.sh"
        exit 1
    fi

    show_banner

    # Loop principal do menu
    while true; do
        show_system_info
        show_menu

        read -p "Digite sua opção (0-7): " choice

        process_menu_choice "$choice"
        local exit_code=$?

        if [[ $exit_code -eq 1 ]]; then
            break # Sai do loop
        fi
        # Se for 0 ou 2, o loop continua
    done

    # Finalização
    echo
    success "🎉 Processo de instalação finalizado!"
    echo
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executa função principal
main "$@"
