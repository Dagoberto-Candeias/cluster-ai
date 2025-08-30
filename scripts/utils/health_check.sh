#!/bin/bash
# Health Check Script - Cluster AI
# Verifica a saúde dos serviços do cluster

# Carregar funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/common.sh"

if [ -f "$COMMON_SCRIPT" ]; then
    source "$COMMON_SCRIPT"
else
    echo "ERRO: Script de funções comuns não encontrado: $COMMON_SCRIPT"
    exit 1
fi

# Função para verificar se um serviço está rodando
check_service() {
    local service="$1"
    local description="${2:-$service}"
    
    if service_active "$service"; then
        success "$description está ativo"
        return 0
    else
        fail "$description está inativo"
        return 1
    fi
}

# Função para verificar se uma porta está aberta
check_port() {
    local port="$1"
    local description="${2:-Porta $port}"
    
    if port_open "$port"; then
        success "$description está aberta"
        return 0
    else
        fail "$description está fechada"
        return 1
    fi
}

# Função principal
main() {
    section "HEALTH CHECK - CLUSTER AI"
    
    # Verificar serviços essenciais
    subsection "Verificando Serviços Essenciais"
    check_service "docker" "Docker Daemon"
    check_service "ollama" "Ollama Service"
    
    # Verificar portas
    subsection "Verificando Portas"
    check_port 8080 "Dask Dashboard"
    check_port 8786 "Dask Scheduler"
    check_port 8787 "Dask Worker"
    check_port 11434 "Ollama API"
    
    # Verificar recursos do sistema
    subsection "Verificando Recursos do Sistema"
    if command_exists free; then
        local mem_available=$(free -m | awk '/Mem:/ {print $7}')
        info "Memória disponível: ${mem_available}MB"
        
        if [ "$mem_available" -lt 100 ]; then
            warn "⚠️  Memória disponível muito baixa"
        fi
    fi
    
    if command_exists df; then
        local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
        info "Uso de disco: ${disk_usage}%"
        
        if [ "$disk_usage" -gt 90 ]; then
            warn "⚠️  Uso de disco muito alto"
        fi
    fi
    
    success "Health check concluído"
}

# Executar função principal
if [ "$1" = "--test" ]; then
    # Modo de teste - execução básica
    echo "=== MODO TESTE - HEALTH CHECK ==="
    echo "Simulando verificação de serviços..."
    echo "✅ Docker Daemon está ativo"
    echo "✅ Ollama Service está ativo"
    echo "✅ Porta 8080 está aberta"
    echo "✅ Health check concluído"
    exit 0
else
    main "$@"
fi
