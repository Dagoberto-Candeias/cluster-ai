#!/bin/bash
# Script de teste de estresse de memória para Cluster AI
# Simula uso intensivo de memória para testar o sistema de swap auto-expansível

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[MEMORY STRESS TEST]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[MEMORY STRESS TEST]${NC} $1"
}

error() {
    echo -e "${RED}[MEMORY STRESS TEST]${NC} $1"
}

# Função para verificar uso de memória
check_memory_usage() {
    local mem_info=$(LC_ALL=C free -m | grep "Mem:")
    local total_mem=$(echo "$mem_info" | awk '{print $2}')
    local used_mem=$(echo "$mem_info" | awk '{print $3}')
    local mem_percent=$((used_mem * 100 / total_mem))
    
    echo "$mem_percent"
}

# Função para alocar memória
allocate_memory() {
    local size_mb=$1
    log "Alocando ${size_mb}MB de memória..."
    
    # Criar arquivo temporário para alocar memória
    head -c ${size_mb}M /dev/urandom > /tmp/memory_stress_test.bin 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log "✅ ${size_mb}MB alocados com sucesso"
        return 0
    else
        error "❌ Falha ao alocar ${size_mb}MB"
        return 1
    fi
}

# Função para liberar memória alocada
free_allocated_memory() {
    log "Liberando memória alocada..."
    rm -f /tmp/memory_stress_test.bin 2>/dev/null
    sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    log "✅ Memória liberada"
}

# Função principal de teste
run_stress_test() {
    echo -e "${BLUE}=== INICIANDO TESTE DE ESTRESSE DE MEMÓRIA ===${NC}"
    
    # Verificar memória inicial
    local initial_usage=$(check_memory_usage)
    log "Uso inicial de memória: ${initial_usage}%"
    
    # Fase 1: Alocar 4GB (teste moderado)
    log "Fase 1: Teste moderado (4GB)"
    if allocate_memory 4096; then
        sleep 5
        local phase1_usage=$(check_memory_usage)
        log "Uso após fase 1: ${phase1_usage}%"
        
        # Verificar se o swap está sendo usado
        local swap_info=$(LC_ALL=C free -m | grep "Swap:")
        local swap_used=$(echo "$swap_info" | awk '{print $3}')
        log "Swap usado: ${swap_used}MB"
    fi
    
    # Fase 2: Alocar mais 4GB (teste intensivo)
    log "Fase 2: Teste intensivo (+4GB)"
    if allocate_memory 4096; then
        sleep 5
        local phase2_usage=$(check_memory_usage)
        log "Uso após fase 2: ${phase2_usage}%"
        
        # Verificar swap novamente
        local swap_info=$(LC_ALL=C free -m | grep "Swap:")
        local swap_used=$(echo "$swap_info" | awk '{print $3}')
        log "Swap usado: ${swap_used}MB"
    fi
    
    # Fase 3: Alocar mais 4GB (teste extremo)
    log "Fase 3: Teste extremo (+4GB)"
    if allocate_memory 4096; then
        sleep 5
        local phase3_usage=$(check_memory_usage)
        log "Uso após fase 3: ${phase3_usage}%"
        
        # Verificar swap final
        local swap_info=$(LC_ALL=C free -m | grep "Swap:")
        local swap_used=$(echo "$swap_info" | awk '{print $3}')
        log "Swap usado final: ${swap_used}MB"
    fi
    
    # Liberar memória
    free_allocated_memory
    
    # Verificar recuperação
    sleep 10
    local final_usage=$(check_memory_usage)
    log "Uso final após liberação: ${final_usage}%"
    
    echo -e "${BLUE}=== TESTE CONCLUÍDO ===${NC}"
    
    # Resultado do teste
    if [ "$final_usage" -lt 50 ]; then
        log "✅ Teste de estresse PASSOU - Sistema se recuperou adequadamente"
        return 0
    else
        warn "⚠️ Teste de estresse com AVISOS - Sistema pode precisar de ajustes"
        return 1
    fi
}

# Menu principal
case "$1" in
    "run")
        run_stress_test
        ;;
    "quick")
        # Teste rápido com 2GB
        allocate_memory 2048
        sleep 3
        usage=$(check_memory_usage)
        log "Uso rápido: ${usage}%"
        free_allocated_memory
        ;;
    *)
        echo -e "${BLUE}Uso: $0 [comando]${NC}"
        echo "Comandos:"
        echo "  run     - Executar teste completo de estresse"
        echo "  quick   - Teste rápido (2GB)"
        ;;
esac
