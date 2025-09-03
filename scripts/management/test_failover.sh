#!/bin/bash
# Script de Teste de Failover para Cluster AI

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs"
TEST_LOG="${LOG_DIR}/failover_test_$(date +%Y%m%d_%H%M%S).log"

# Carregar funções comuns
COMMON_SCRIPT_PATH="${PROJECT_ROOT}/scripts/utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
    confirm_operation() {
        read -p "$1 (s/N): " -n 1 -r; echo
        [[ $REPLY =~ ^[Ss]$ ]]
    }
fi

# Carregar configurações
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Configurações padrão
NODE_IP="${NODE_IP:-192.168.0.2}"
DASK_SCHEDULER_PORT="${DASK_SCHEDULER_PORT:-8786}"
SECONDARY_IP="${NODE_IP_SECONDARY:-192.168.0.3}"
SECONDARY_PORT="${DASK_SCHEDULER_SECONDARY_PORT:-8788}"
WORKER_MANJARO_IP="${WORKER_MANJARO_IP:-192.168.0.4}"

# Função para registrar eventos de teste
log_test_event() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$TEST_LOG"
    echo "$message"
}

# Função para verificar status do scheduler
check_scheduler_status() {
    local ip="$1"
    local port="$2"
    local name="$3"

    if timeout 5 bash -c "echo >/dev/tcp/${ip}/${port}" 2>/dev/null; then
        log_test_event "✅ $name ($ip:$port) - ATIVO"
        return 0
    else
        log_test_event "❌ $name ($ip:$port) - INATIVO"
        return 1
    fi
}

# Função para verificar workers conectados
check_worker_connections() {
    local scheduler_ip="$1"
    local scheduler_port="$2"
    local scheduler_name="$3"

    log_test_event "Verificando workers conectados ao $scheduler_name..."

    # Usar dask client para verificar workers
    python3 -c "
import asyncio
from dask.distributed import Client
import sys

async def check_workers():
    try:
        client = Client(f'tcp://{scheduler_ip}:{scheduler_port}', timeout='5s')
        workers = list(client.scheduler_info()['workers'].keys())
        client.close()
        print(f'Workers conectados: {len(workers)}')
        for worker in workers:
            print(f'  - {worker}')
        return len(workers)
    except Exception as e:
        print(f'Erro ao conectar: {e}')
        return 0

result = asyncio.run(check_workers())
sys.exit(0 if result > 0 else 1)
" 2>/dev/null || log_test_event "⚠️ Não foi possível verificar workers via API"
}

# Função para testar failover
test_failover() {
    section "Teste de Failover Automático"

    log_test_event "=== INICIANDO TESTE DE FAILOVER ==="

    # Verificar status inicial
    log_test_event "Verificando status inicial dos schedulers..."
    check_scheduler_status "$NODE_IP" "$DASK_SCHEDULER_PORT" "Scheduler Primário"
    check_scheduler_status "$SECONDARY_IP" "$SECONDARY_PORT" "Scheduler Secundário"

    # Verificar workers inicialmente
    check_worker_connections "$NODE_IP" "$DASK_SCHEDULER_PORT" "Scheduler Primário"

    # Simular falha do scheduler primário
    log_test_event "Simulando falha do scheduler primário..."
    log_test_event "Parando scheduler primário temporariamente..."

    # Parar scheduler primário (simulação)
    pkill -f "dask-scheduler.*${DASK_SCHEDULER_PORT}" || log_test_event "Scheduler primário já estava parado"

    # Aguardar detecção de falha
    log_test_event "Aguardando detecção de falha e failover..."
    sleep 10

    # Verificar se scheduler secundário assumiu
    if check_scheduler_status "$SECONDARY_IP" "$SECONDARY_PORT" "Scheduler Secundário"; then
        log_test_event "✅ Scheduler secundário assumiu o controle"

        # Verificar se workers reconectaram
        check_worker_connections "$SECONDARY_IP" "$SECONDARY_PORT" "Scheduler Secundário"

        # Testar conectividade do cluster
        test_cluster_connectivity "$SECONDARY_IP" "$SECONDARY_PORT"

        success "Failover realizado com sucesso!"
    else
        error "Scheduler secundário não assumiu o controle"
        return 1
    fi

    # Restaurar scheduler primário
    log_test_event "Restaurando scheduler primário..."
    if [ -f "${PROJECT_ROOT}/scripts/management/failover_scheduler.sh" ]; then
        bash "${PROJECT_ROOT}/scripts/management/failover_scheduler.sh" restore || log_test_event "Erro ao restaurar scheduler primário"
    fi

    # Aguardar recuperação
    sleep 15

    # Verificar recuperação
    if check_scheduler_status "$NODE_IP" "$DASK_SCHEDULER_PORT" "Scheduler Primário"; then
        log_test_event "✅ Scheduler primário recuperado com sucesso"
    else
        warn "Scheduler primário não foi recuperado automaticamente"
    fi

    log_test_event "=== TESTE DE FAILOVER CONCLUÍDO ==="
}

# Função para testar conectividade do cluster
test_cluster_connectivity() {
    local scheduler_ip="$1"
    local scheduler_port="$2"

    log_test_event "Testando conectividade do cluster..."

    # Teste simples de conectividade
    python3 -c "
import asyncio
from dask.distributed import Client
import time
import sys

async def test_connectivity(scheduler_ip, scheduler_port):
    try:
        client = Client(f'tcp://{scheduler_ip}:{scheduler_port}', timeout='10s')

        # Teste básico
        future = client.submit(lambda x: x + 1, 10)
        result = future.result(timeout=10)
        print(f'Teste de computação: 10 + 1 = {result}')

        # Verificar workers
        workers = list(client.scheduler_info()['workers'].keys())
        print(f'Workers ativos: {len(workers)}')

        client.close()
        return True
    except Exception as e:
        print(f'Erro no teste: {e}')
        return False

success = asyncio.run(test_connectivity('$scheduler_ip', '$scheduler_port'))
print(f'Conectividade: {\"OK\" if success else \"FALHA\"}')
sys.exit(0 if success else 1)
" 2>/dev/null && log_test_event "✅ Conectividade do cluster OK" || log_test_event "❌ Problemas na conectividade do cluster"
}

# Função para executar testes de carga
test_load_balancing() {
    section "Teste de Balanceamento de Carga"

    log_test_event "=== TESTE DE BALANCEAMENTO DE CARGA ==="

    # Verificar distribuição de tarefas
    python3 -c "
import asyncio
from dask.distributed import Client
import time

async def test_load():
    try:
        # Conectar ao scheduler ativo
        client = Client(timeout='10s')

        print('Executando tarefas de teste...')

        # Criar tarefas computacionais
        futures = []
        for i in range(10):
            future = client.submit(lambda x: sum(range(x)), 100000)
            futures.append(future)

        # Aguardar conclusão
        results = await asyncio.gather(*[f.result() for f in futures])

        print(f'Tarefas concluídas: {len(results)}')
        print(f'Resultado médio: {sum(results)/len(results):.0f}')

        # Verificar distribuição
        scheduler_info = client.scheduler_info()
        workers = scheduler_info['workers']

        print(f'Workers disponíveis: {len(workers)}')
        for worker_addr, worker_info in workers.items():
            tasks = worker_info.get('metrics', {}).get('tasks', 0)
            print(f'  {worker_addr}: {tasks} tarefas')

        client.close()
        return True
    except Exception as e:
        print(f'Erro no teste de carga: {e}')
        return False

success = asyncio.run(test_load())
print(f'Balanceamento: {\"OK\" if success else \"FALHA\"}')
" 2>/dev/null || log_test_event "⚠️ Erro no teste de balanceamento"
}

# Função para gerar relatório de teste
generate_test_report() {
    section "Gerando Relatório de Teste"

    local report_file="${LOG_DIR}/failover_test_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== RELATÓRIO DE TESTE DE FAILOVER ==="
        echo "Data/Hora: $(date)"
        echo ""
        echo "=== CONFIGURAÇÃO TESTADA ==="
        echo "Scheduler Primário: $NODE_IP:$DASK_SCHEDULER_PORT"
        echo "Scheduler Secundário: $SECONDARY_IP:$SECONDARY_PORT"
        echo "Worker Manjaro: $WORKER_MANJARO_IP"
        echo ""
        echo "=== LOGS DO TESTE ==="
        if [ -f "$TEST_LOG" ]; then
            cat "$TEST_LOG"
        else
            echo "Arquivo de log não encontrado"
        fi
        echo ""
        echo "=== RESULTADO GERAL ==="
        if grep -q "Failover realizado com sucesso" "$TEST_LOG" 2>/dev/null; then
            echo "✅ TESTE APROVADO - Failover funcionando corretamente"
        else
            echo "❌ TESTE REPROVADO - Problemas detectados no failover"
        fi
        echo ""
        echo "=== RECOMENDAÇÕES ==="
        echo "1. Verificar se os schedulers estão configurados corretamente"
        echo "2. Confirmar que workers conseguem reconectar automaticamente"
        echo "3. Testar em condições de carga real"
        echo "4. Configurar alertas para falhas de failover"

    } > "$report_file"

    log_test_event "Relatório salvo em: $report_file"
    success "Relatório de teste gerado: $report_file"
}

# Função principal
main() {
    mkdir -p "$LOG_DIR"

    case "${1:-full}" in
        failover)
            test_failover
            ;;
        connectivity)
            test_cluster_connectivity "$NODE_IP" "$DASK_SCHEDULER_PORT"
            ;;
        load)
            test_load_balancing
            ;;
        full)
            test_failover
            test_load_balancing
            generate_test_report
            ;;
        report)
            generate_test_report
            ;;
        *)
            echo "Uso: $0 [failover|connectivity|load|full|report]"
            echo ""
            echo "Comandos:"
            echo "  failover     - Testa apenas o failover"
            echo "  connectivity - Testa conectividade do cluster"
            echo "  load         - Testa balanceamento de carga"
            echo "  full         - Executa todos os testes"
            echo "  report       - Gera relatório dos testes"
            ;;
    esac
}

main "$@"
