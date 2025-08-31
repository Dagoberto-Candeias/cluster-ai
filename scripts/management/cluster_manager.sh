#!/bin/bash
# Cluster AI Manager - Script de gerenciamento com opções de reset/reconfiguração

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Função para limpar ambiente completamente
clean_environment() {
    echo -e "\n${RED}=== LIMPEZA COMPLETA DO AMBIENTE ===${NC}"
    echo -e "${YELLOW}AVISO: Esta operação removerá TODOS os dados do cluster!${NC}"
    read -p "Tem certeza que deseja continuar? (s/n): " confirm_clean
    
    if [ "$confirm_clean" != "s" ]; then
        log "Limpeza cancelada."
        return 0
    fi
    
    log "Iniciando limpeza completa do ambiente..."
    
    # Parar todos os serviços
    sudo pkill -f "dask-scheduler" || true
    sudo pkill -f "dask-worker" || true
    sudo pkill -f "ollama" || true
    
    # Remover containers Docker
    sudo docker rm -f open-webui 2>/dev/null || true
    
    # Remover arquivos e diretórios
    rm -rf ~/.cluster_role
    rm -rf ~/cluster_scripts
    rm -rf ~/.ollama
    rm -rf ~/open-webui
    rm -rf ~/cluster_env
    rm -rf ~/cluster_backups
    rm -rf ~/scheduler.log
    rm -rf ~/worker.log
    
    # Remover configurações específicas
    sudo rm -rf /etc/systemd/system/ollama.service.d/
    
    log "Ambiente completamente limpo. Todos os dados foram removidos."
}

# Função para resetar configurações
reset_configuration() {
    echo -e "\n${YELLOW}=== RESET DE CONFIGURAÇÕES ===${NC}"
    echo "1. Reset completo (limpar tudo e reinstalar)"
    echo "2. Reset apenas das configurações (manter dados)"
    echo "3. Voltar"
    
    read -p "Selecione o tipo de reset [1-3]: " reset_choice
    
    case $reset_choice in
        1)
            clean_environment
            log "Ambiente resetado. Execute a instalação novamente."
            # Executar instalação normal após reset
            exec ./install_cluster.sh
            ;;
        2)
            rm -rf ~/.cluster_role
            rm -rf ~/cluster_scripts/*.sh
            log "Configurações resetadas. Papel da máquina será redefinido."
            # Executar instalação para reconfigurar
            exec ./install_cluster.sh
            ;;
        3)
            return
            ;;
        *)
            warn "Opção inválida."
            ;;
    esac
}

# Função para reconfigurar ambiente
reconfigure_environment() {
    echo -e "\n${BLUE}=== RECONFIGURAÇÃO DO AMBIENTE ===${NC}"
    echo "1. Alterar papel da máquina"
    echo "2. Reconfigurar serviços existentes"
    echo "3. Reinstalar dependências"
    echo "4. Voltar"
    
    read -p "Selecione a opção de reconfiguração [1-4]: " reconf_choice
    
    case $reconf_choice in
        1)
            # Forçar redefinição do papel
            rm -f ~/.cluster_role
            exec ./install_cluster.sh
            ;;
        2)
            # Reiniciar serviços
            sudo pkill -f "dask-scheduler" || true
            sudo pkill -f "dask-worker" || true
            sudo systemctl restart ollama
            log "Serviços reiniciados."
            ;;
        3)
            # Reinstalar dependências
            echo "Reinstalando dependências..."
            # Esta funcionalidade precisaria ser implementada no script principal
            warn "Funcionalidade de reinstalação precisa ser implementada no script de instalação."
            ;;
        4)
            return
            ;;
        *)
            warn "Opção inválida."
            ;;
    esac
}

# Função para reaproveitar configuração existente
reuse_existing_config() {
    echo -e "\n${GREEN}=== REAPROVEITAR CONFIGURAÇÃO EXISTENTE ===${NC}"
    
    if [ -f ~/.cluster_role ]; then
        source ~/.cluster_role
        log "Configuração existente detectada:"
        echo "Papel: $ROLE"
        echo "Servidor: $SERVER_IP"
        echo "Máquina: $MACHINE_NAME"
        
        read -p "Deseja reaproveitar esta configuração? (s/n): " reuse_choice
        
        if [ "$reuse_choice" = "s" ]; then
            log "Configuração existente será reaproveitada."
            # Continuar com a instalação normal
            exec ./install_cluster.sh
        else
            log "Configuração existente será ignorada."
            rm -f ~/.cluster_role
            # Iniciar configuração do zero
            exec ./install_cluster.sh
        fi
    else
        log "Nenhuma configuração existente encontrada."
        # Iniciar configuração do zero
        exec ./install_cluster.sh
    fi
}

# Função para detectar estado do ambiente
detect_environment_state() {
    local has_config=false
    local has_services=false
    
    # Verificar se existe configuração
    if [ -f ~/.cluster_role ]; then
        has_config=true
        source ~/.cluster_role
    fi
    
    # Verificar se serviços estão rodando
    if pgrep -f "dask-scheduler" >/dev/null || \
       pgrep -f "dask-worker" >/dev/null || \
       pgrep -f "ollama" >/dev/null; then
        has_services=true
    fi
    
    # Verificar se existem dados
    local has_data=false
    if [ -d ~/.ollama ] || [ -d ~/open-webui ] || [ -d ~/cluster_env ]; then
        has_data=true
    fi
    
    # Determinar estado
    if [ "$has_config" = true ] && [ "$has_services" = true ]; then
        echo "active"
    elif [ "$has_config" = true ] && [ "$has_services" = false ]; then
        echo "configured"
    elif [ "$has_data" = true ] && [ "$has_config" = false ]; then
        echo "orphan_data"
    else
        echo "clean"
    fi
}

# Função para menu principal adaptativo
show_main_menu() {
    local state=$(detect_environment_state)
    
    while true; do
        echo -e "\n${BLUE}=== GERENCIAMENTO DO CLUSTER AI ===${NC}"
        echo -e "${YELLOW}Estado detectado: $state${NC}"
        
        case $state in
            "active")
                echo -e "${GREEN}Ambiente ativo e configurado${NC}"
                echo "1. Reiniciar Serviços"
                echo "2. Alterar Configuração"
                echo "3. Fazer Backup"
                echo "4. Resetar/Reinstalar"
                echo "5. Limpar Tudo"
                echo "6. Ver Status Detalhado"
                echo "7. Sair"
                
                read -p "Selecione uma opção [1-7]: " choice
                
                case $choice in
                    1)
                        log "Reiniciando serviços..."
                        sudo pkill -f "dask-scheduler" || true
                        sudo pkill -f "dask-worker" || true
                        sudo systemctl restart ollama
                        log "Serviços reiniciados."
                        ;;
                    2)
                        reconfigure_environment
                        ;;
                    3)
                        # Backup será implementado posteriormente
                        warn "Funcionalidade de backup será implementada em breve."
                        ;;
                    4)
                        reset_configuration
                        ;;
                    5)
                        clean_environment
                        exit 0
                        ;;
                    6)
                        show_detailed_status
                        ;;
                    7)
                        log "Saindo..."
                        exit 0
                        ;;
                    *)
                        warn "Opção inválida. Tente novamente."
                        ;;
                esac
                ;;
                
            "configured")
                echo -e "${YELLOW}Ambiente configurado mas serviços parados${NC}"
                echo "1. Iniciar Serviços"
                echo "2. Reconfigurar"
                echo "3. Limpar Configuração"
                echo "4. Ver Status"
                echo "5. Sair"
                
                read -p "Selecione uma opção [1-5]: " choice
                
                case $choice in
                    1)
                        log "Iniciando serviços..."
                        exec ./install_cluster.sh
                        ;;
                    2)
                        reconfigure_environment
                        ;;
                    3)
                        rm -f ~/.cluster_role
                        rm -rf ~/cluster_scripts/*.sh
                        log "Configuração removida."
                        state=$(detect_environment_state)
                        ;;
                    4)
                        show_detailed_status
                        ;;
                    5)
                        exit 0
                        ;;
                    *)
                        warn "Opção inválida. Tente novamente."
                        ;;
                esac
                ;;
                
            "orphan_data")
                echo -e "${YELLOW}Dados encontrados sem configuração${NC}"
                echo "1. Reaproveitar Dados Existente"
                echo "2. Limpar Tudo e Instalar do Zero"
                echo "3. Ver Dados Encontrados"
                echo "4. Sair"
                
                read -p "Selecione uma opção [1-4]: " choice
                
                case $choice in
                    1)
                        reuse_existing_config
                        ;;
                    2)
                        clean_environment
                        log "Ambiente limpo. Iniciando instalação..."
                        exec ./install_cluster.sh
                        ;;
                    3)
                        show_orphan_data
                        ;;
                    4)
                        exit 0
                        ;;
                    *)
                        warn "Opção inválida. Tente novamente."
                        ;;
                esac
                ;;
                
            "clean")
                echo -e "${CYAN}Ambiente limpo - Pronto para instalação${NC}"
                echo "1. Instalação Normal"
                echo "2. Instalação Avançada"
                echo "3. Verificar Recursos do Sistema"
                echo "4. Sair"
                
                read -p "Selecione uma opção [1-4]: " choice
                
                case $choice in
                    1)
                        log "Iniciando instalação normal..."
                        exec ./install_cluster.sh
                        ;;
                    2)
                        # Instalação avançada poderia ter mais opções
                        log "Iniciando instalação avançada..."
                        exec ./install_cluster.sh
                        ;;
                    3)
                        # Verificar recursos do sistema
                        if [ -f "./scripts/utils/resource_checker.sh" ]; then
                            bash ./scripts/utils/resource_checker.sh
                        else
                            warn "Script de verificação de recursos não encontrado."
                        fi
                        ;;
                    4)
                        exit 0
                        ;;
                    *)
                        warn "Opção inválida. Tente novamente."
                        ;;
                esac
                ;;
        esac
        
        # Atualizar estado após cada operação
        state=$(detect_environment_state)
    done
}

# Função para mostrar status detalhado
show_detailed_status() {
    echo -e "\n${CYAN}=== STATUS DETALHADO DO SISTEMA ===${NC}"
    
    # Configuração
    if [ -f ~/.cluster_role ]; then
        source ~/.cluster_role
        echo -e "${GREEN}CONFIGURAÇÃO:${NC}"
        echo "Papel: $ROLE"
        echo "Máquina: $MACHINE_NAME"
        echo "Servidor: ${SERVER_IP:-Não configurado}"
        echo "Backup Dir: ${BACKUP_DIR:-Padrão}"
    else
        echo -e "${YELLOW}CONFIGURAÇÃO: Nenhuma configuração encontrada${NC}"
    fi
    
    # Serviços
    echo -e "\n${GREEN}SERVIÇOS:${NC}"
    if pgrep -f "dask-scheduler" >/dev/null; then
        echo "✓ Dask Scheduler está em execução"
    else
        echo "✗ Dask Scheduler não está em execução"
    fi
    
    if pgrep -f "dask-worker" >/dev/null; then
        echo "✓ Dask Worker está em execução"
    else
        echo "✗ Dask Worker não está em execução"
    fi
    
    if pgrep -f "ollama" >/dev/null; then
        echo "✓ Ollama está em execução"
    else
        echo "✗ Ollama não está em execução"
    fi
    
    # Dados
    echo -e "\n${GREEN}DADOS:${NC}"
    if [ -d ~/.ollama ]; then
        echo "✓ Modelos Ollama presentes"
        if command_exists ollama; then
            echo "  Modelos instalados:"
            ollama list 2>/dev/null || echo "  Não foi possível listar modelos"
        fi
    else
        echo "✗ Nenhum modelo Ollama encontrado"
    fi
    
    if [ -d ~/open-webui ]; then
        echo "✓ Dados OpenWebUI presentes"
    else
        echo "✗ Nenhum dado OpenWebUI encontrado"
    fi
    
    if [ -d ~/cluster_env ]; then
        echo "✓ Ambiente Python presente"
    else
        echo "✗ Ambiente Python não encontrado"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Função para mostrar dados órfãos
show_orphan_data() {
    echo -e "\n${YELLOW}=== DADOS ÓRFÃOS DETECTADOS ===${NC}"
    
    if [ -d ~/.ollama ]; then
        echo "📦 Modelos Ollama: ~/.ollama"
        echo "   Tamanho: $(du -sh ~/.ollama 2>/dev/null | cut -f1) ou N/A"
    fi
    
    if [ -d ~/open-webui ]; then
        echo "🌐 Dados OpenWebUI: ~/open-webui"
        echo "   Tamanho: $(du -sh ~/open-webui 2>/dev/null | cut -f1) ou N/A"
    fi
    
    if [ -d ~/cluster_env ]; then
        echo "🐍 Ambiente Python: ~/cluster_env"
        echo "   Tamanho: $(du -sh ~/cluster_env 2>/dev/null | cut -f1) ou N/A"
    fi
    
    if [ -d ~/cluster_scripts ]; then
        echo "📜 Scripts: ~/cluster_scripts"
        echo "   Tamanho: $(du -sh ~/cluster_scripts 2>/dev/null | cut -f1) ou N/A"
    fi
    
    if [ ! -d ~/.ollama ] && [ ! -d ~/open-webui ] && [ ! -d ~/cluster_env ] && [ ! -d ~/cluster_scripts ]; then
        echo "✅ Nenhum dado órfão encontrado"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Executar menu principal
show_main_menu
