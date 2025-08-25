#!/bin/bash
# Script de validação da instalação do Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se um serviço está rodando
service_running() {
    local service="$1"
    if pgrep -f "$service" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Função para verificar se uma porta está aberta
port_open() {
    local port="$1"
    if netstat -tln | grep ":$port " >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Função para testar conexão HTTP
test_http() {
    local url="$1"
    if curl -s --head "$url" | grep "HTTP" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Validação principal
validate_installation() {
    echo -e "${BLUE}=== VALIDAÇÃO DA INSTALAÇÃO CLUSTER AI ===${NC}"
    echo ""
    
    local overall_success=true
    
    # 1. Verificar dependências básicas
    echo -e "${YELLOW}1. VERIFICANDO DEPENDÊNCIAS BÁSICAS${NC}"
    local deps=("docker" "python3" "pip3" "curl" "git")
    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            success "$dep encontrado"
        else
            fail "$dep não encontrado"
            overall_success=false
        fi
    done
    echo ""
    
    # 2. Verificar Docker
    echo -e "${YELLOW}2. VERIFICANDO DOCKER${NC}"
    if command_exists docker; then
        success "Docker instalado"
        if docker info >/dev/null 2>&1; then
            success "Docker funcionando"
        else
            fail "Docker não está rodando"
            overall_success=false
        fi
    else
        fail "Docker não instalado"
        overall_success=false
    fi
    echo ""
    
    # 3. Verificar ambiente Python
    echo -e "${YELLOW}3. VERIFICANDO AMBIENTE PYTHON${NC}"
    if [ -d "$HOME/cluster_env" ]; then
        success "Ambiente virtual encontrado"
        if source "$HOME/cluster_env/bin/activate" && python -c "import dask" 2>/dev/null; then
            success "Dask instalado no ambiente virtual"
        else
            fail "Dask não instalado no ambiente virtual"
            overall_success=false
        fi
        deactivate
    else
        fail "Ambiente virtual não encontrado"
        overall_success=false
    fi
    echo ""
    
    # 4. Verificar configuração do cluster
    echo -e "${YELLOW}4. VERIFICANDO CONFIGURAÇÃO DO CLUSTER${NC}"
    if [ -f "$HOME/.cluster_role" ]; then
        success "Arquivo de configuração encontrado"
        source "$HOME/.cluster_role"
        info "Papel: $ROLE"
        info "Máquina: $MACHINE_NAME"
        if [ -n "$SERVER_IP" ]; then
            info "Servidor: $SERVER_IP"
        fi
    else
        warn "Arquivo de configuração não encontrado (executar install_cluster.sh primeiro)"
    fi
    echo ""
    
    # 5. Verificar scripts de gerenciamento
    echo -e "${YELLOW}5. VERIFICANDO SCRIPTS DE GERENCIAMENTO${NC}"
    if [ -d "$HOME/cluster_scripts" ]; then
        success "Diretório de scripts encontrado"
        if [ -f "$HOME/cluster_scripts/start_scheduler.sh" ]; then
            success "Script do scheduler encontrado"
        fi
        if [ -f "$HOME/cluster_scripts/start_worker.sh" ]; then
            success "Script do worker encontrado"
        fi
    else
        warn "Diretório de scripts não encontrado"
    fi
    echo ""
    
    # 6. Verificar Ollama
    echo -e "${YELLOW}6. VERIFICANDO OLLAMA${NC}"
    if command_exists ollama; then
        success "Ollama instalado"
        
        # Verificar se Ollama está rodando
        if service_running "ollama"; then
            success "Ollama está rodando"
            
            # Testar API do Ollama
            if test_http "http://localhost:11434/api/tags"; then
                success "API do Ollama respondendo"
                
                # Verificar modelos instalados
                local models=$(ollama list 2>/dev/null | wc -l)
                if [ "$models" -gt 1 ]; then
                    success "$((models-1)) modelo(s) instalado(s)"
                    ollama list
                else
                    warn "Nenhum modelo Ollama instalado"
                    info "Execute: ./scripts/utils/check_models.sh"
                fi
            else
                fail "API do Ollama não respondendo"
                overall_success=false
            fi
        else
            fail "Ollama não está rodando"
            overall_success=false
        fi
    else
        warn "Ollama não instalado"
        info "Execute: curl -fsSL https://ollama.com/install.sh | sh"
    fi
    echo ""
    
    # 7. Verificar serviços Dask
    echo -e "${YELLOW}7. VERIFICANDO SERVIÇOS DASK${NC}"
    
    # Verificar scheduler
    if service_running "dask-scheduler"; then
        success "Dask Scheduler rodando"
        if port_open 8786; then
            success "Porta 8786 (scheduler) aberta"
        else
            fail "Porta 8786 não aberta"
            overall_success=false
        fi
    else
        warn "Dask Scheduler não está rodando"
    fi
    
    # Verificar dashboard
    if port_open 8787; then
        success "Porta 8787 (dashboard) aberta"
        if test_http "http://localhost:8787"; then
            success "Dashboard acessível"
        else
            warn "Dashboard não respondendo"
        fi
    else
        warn "Dashboard não está rodando"
    fi
    
    # Verificar workers
    if service_running "dask-worker"; then
        success "Dask Worker(s) rodando"
        local workers=$(pgrep -f "dask-worker" | wc -l)
        info "$workers worker(s) em execução"
    else
        warn "Nenhum Dask Worker rodando"
    fi
    echo ""
    
    # 8. Verificar OpenWebUI
    echo -e "${YELLOW}8. VERIFICANDO OPENWEBUI${NC}"
    if docker ps | grep -q "open-webui"; then
        success "OpenWebUI container rodando"
        if port_open 8080; then
            success "Porta 8080 aberta"
            if test_http "http://localhost:8080"; then
                success "OpenWebUI acessível"
            else
                warn "OpenWebUI não respondendo"
            fi
        else
            fail "Porta 8080 não aberta"
            overall_success=false
        fi
    else
        warn "OpenWebUI não está rodando"
        info "Execute: docker-compose -f configs/docker/compose-basic.yml up -d"
    fi
    echo ""
    
    # 9. Verificar firewall
    echo -e "${YELLOW}9. VERIFICANDO FIREWALL${NC}"
    if command_exists ufw; then
        if sudo ufw status | grep -q "Status: active"; then
            success "Firewall ativo"
            # Verificar portas essenciais
            local essential_ports=(22 8786 8787 8080 11434)
            for port in "${essential_ports[@]}"; do
                if sudo ufw status | grep -q "$port/tcp.*ALLOW"; then
                    success "Porta $port permitida no firewall"
                else
                    warn "Porta $port não permitida no firewall"
                    info "Execute: sudo ufw allow $port/tcp"
                fi
            done
        else
            warn "Firewall não está ativo"
        fi
    else
        warn "UFW não instalado"
    fi
    echo ""
    
    # 10. Verificar sistema de backup
    echo -e "${YELLOW}10. VERIFICANDO SISTEMA DE BACKUP${NC}"
    if [ -d "$HOME/cluster_backups" ]; then
        success "Diretório de backups encontrado"
        local backup_count=$(find "$HOME/cluster_backups" -name "*.tar.gz" | wc -l)
        if [ "$backup_count" -gt 0 ]; then
            success "$backup_count backup(s) encontrado(s)"
            ls -la "$HOME/cluster_backups/" | grep "\.tar.gz"
        else
            warn "Nenhum backup encontrado"
            info "Execute: ./install_cluster.sh --backup"
        fi
    else
        warn "Diretório de backups não encontrado"
    fi
    echo ""
    
    # Resumo final
    echo -e "${BLUE}=== RESUMO DA VALIDAÇÃO ===${NC}"
    if [ "$overall_success" = true ]; then
        success "✅ Instalação validada com sucesso!"
        echo ""
        echo -e "${GREEN}📊 STATUS DOS SERVIÇOS:${NC}"
        echo -e "Dask Scheduler: $(service_running "dask-scheduler" && echo "✅" || echo "❌")"
        echo -e "Dask Worker(s): $(service_running "dask-worker" && echo "✅" || echo "❌")"  
        echo -e "Ollama: $(service_running "ollama" && echo "✅" || echo "❌")"
        echo -e "OpenWebUI: $(docker ps | grep -q "open-webui" && echo "✅" || echo "❌")"
        echo ""
        echo -e "${GREEN}🌐 URLS DISPONÍVEIS:${NC}"
        echo -e "Dashboard Dask: http://$(hostname -I | awk '{print $1}'):8787"
        echo -e "OpenWebUI: http://$(hostname -I | awk '{print $1}'):8080"
        echo -e "Ollama API: http://$(hostname -I | awk '{print $1}'):11434"
    else
        fail "❌ Instalação com problemas!"
        echo ""
        echo -e "${RED}⚠️  PROBLEMAS ENCONTRADOS:${NC}"
        echo -e "Verifique os logs acima e corrija os issues identificados."
        echo -e "Consulte o guia de troubleshooting: docs/guides/TROUBLESHOOTING.md"
    fi
    
    echo ""
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo "1. Verifique os serviços acima"
    echo "2. Consulte a documentação em docs/"
    echo "3. Teste com exemplos em examples/"
    echo "4. Configure backups regulares"
    
    return $([ "$overall_success" = true ] && echo 0 || echo 1)
}

# Executar validação
validate_installation

# Salvar resultado
exit $?
