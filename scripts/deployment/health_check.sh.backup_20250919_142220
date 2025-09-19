#!/bin/bash
# Health Check Script para Cluster AI
# Verifica se todos os serviços estão funcionando corretamente

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="${PROJECT_ROOT}/logs/health_check_$(date +%Y%m%d_%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
    ((CHECKS_PASSED++))
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
    ((CHECKS_WARNING++))
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

check_start() {
    ((CHECKS_TOTAL++))
    log "Verificando: $1"
}

# =============================================================================
# VERIFICAÇÕES DE SISTEMA
# =============================================================================

check_system_requirements() {
    log "=== VERIFICAÇÕES DE SISTEMA ==="

    # Verificar Python
    check_start "Python 3.9+ instalado"
    if command -v python3 &> /dev/null && python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)"; then
        success "Python $(python3 --version) encontrado"
    else
        error "Python 3.9+ não encontrado ou versão incompatível"
    fi

    # Verificar espaço em disco
    check_start "Espaço em disco suficiente"
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 90 ]; then
        success "Espaço em disco: ${disk_usage}% usado"
    else
        warning "Espaço em disco baixo: ${disk_usage}% usado"
    fi

    # Verificar memória
    check_start "Memória suficiente"
    local mem_total
    local mem_available
    mem_total=$(free -m | grep '^Mem:' | awk '{print $2}')
    mem_available=$(free -m | grep '^Mem:' | awk '{print $7}')

    if [ "$mem_available" -gt 512 ]; then
        success "Memória disponível: ${mem_available}MB de ${mem_total}MB"
    else
        warning "Memória baixa: ${mem_available}MB de ${mem_total}MB disponível"
    fi

    # Verificar conectividade de rede
    check_start "Conectividade de rede"
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        success "Conectividade de rede OK"
    else
        error "Sem conectividade de rede"
    fi
}

# =============================================================================
# VERIFICAÇÕES DE DEPENDÊNCIAS
# =============================================================================

check_dependencies() {
    log "=== VERIFICAÇÕES DE DEPENDÊNCIAS ==="

    # Verificar pip
    check_start "Pip instalado"
    if command -v pip3 &> /dev/null; then
        success "Pip encontrado: $(pip3 --version)"
    else
        error "Pip não encontrado"
    fi

    # Verificar dependências Python
    check_start "Dependências Python instaladas"
    if [ -f "${PROJECT_ROOT}/requirements.txt" ]; then
        if python3 -c "
import sys
import pkg_resources
import importlib

# Ler requirements
with open('${PROJECT_ROOT}/requirements.txt', 'r') as f:
    requirements = [line.strip() for line in f if line.strip() and not line.startswith('#')]

missing_deps = []
for req in requirements[:5]:  # Verificar apenas as primeiras 5 para performance
    try:
        pkg_resources.require(req)
    except (pkg_resources.DistributionNotFound, pkg_resources.VersionConflict):
        try:
            # Tentar importar o módulo
            package_name = req.split()[0].split('==')[0].split('>=')[0].split('<')[0]
            importlib.import_module(package_name.replace('-', '_'))
        except ImportError:
            missing_deps.append(req)

if not missing_deps:
    success 'Principais dependências Python OK'
else:
    warning 'Dependências possivelmente faltando: ${missing_deps[*]}'
        "; then
            success "Dependências Python verificadas"
        else
            warning "Problemas com dependências Python"
        fi
    else
        info "Arquivo requirements.txt não encontrado"
    fi

    # Verificar ferramentas de sistema
    local system_tools=("bash" "grep" "awk" "sed" "find")
    for tool in "${system_tools[@]}"; do
        check_start "Ferramenta de sistema: $tool"
        if command -v "$tool" &> /dev/null; then
            success "$tool encontrado"
        else
            error "$tool não encontrado"
        fi
    done
}

# =============================================================================
# VERIFICAÇÕES DE ARQUIVOS E PERMISSÕES
# =============================================================================

check_files_and_permissions() {
    log "=== VERIFICAÇÕES DE ARQUIVOS E PERMISSÕES ==="

    # Verificar arquivos críticos
    local critical_files=(
        "manager.sh"
        "demo_cluster.py"
        "requirements.txt"
        "README.md"
    )

    for file in "${critical_files[@]}"; do
        check_start "Arquivo crítico: $file"
        if [ -f "${PROJECT_ROOT}/$file" ]; then
            success "$file encontrado"
        else
            error "$file não encontrado"
        fi
    done

    # Verificar permissões de execução dos scripts
    check_start "Permissões de execução dos scripts"
    local executable_scripts
    executable_scripts=$(find "${PROJECT_ROOT}" -name "*.sh" -not -executable | wc -l)

    if [ "$executable_scripts" -eq 0 ]; then
        success "Todos os scripts têm permissão de execução"
    else
        warning "$executable_scripts scripts sem permissão de execução"
    fi

    # Verificar estrutura de diretórios
    check_start "Estrutura de diretórios"
    local expected_dirs=("scripts" "tests" "docs" "logs" "configs")
    local missing_dirs=()

    for dir in "${expected_dirs[@]}"; do
        if [ ! -d "${PROJECT_ROOT}/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -eq 0 ]; then
        success "Estrutura de diretórios completa"
    else
        warning "Diretórios faltando: ${missing_dirs[*]}"
    fi
}

# =============================================================================
# VERIFICAÇÕES FUNCIONAIS
# =============================================================================

check_functionality() {
    log "=== VERIFICAÇÕES FUNCIONAIS ==="

    # Verificar manager.sh
    check_start "Manager.sh funcional"
    if [ -x "${PROJECT_ROOT}/manager.sh" ]; then
        if timeout 5s bash "${PROJECT_ROOT}/manager.sh" help &> /dev/null; then
            success "Manager.sh executa corretamente"
        else
            error "Manager.sh falha ao executar"
        fi
    else
        error "Manager.sh não é executável"
    fi

    # Verificar demo_cluster.py
    check_start "Demo cluster funcional"
    if [ -f "${PROJECT_ROOT}/demo_cluster.py" ]; then
        if timeout 10s python3 "${PROJECT_ROOT}/demo_cluster.py" --help &> /dev/null; then
            success "Demo cluster executa corretamente"
        else
            warning "Demo cluster pode ter problemas"
        fi
    else
        error "demo_cluster.py não encontrado"
    fi

    # Verificar ferramentas avançadas
    local advanced_tools=("monitor" "optimize" "vscode" "update" "security")
    for tool in "${advanced_tools[@]}"; do
        check_start "Ferramenta avançada: $tool"
        if timeout 3s bash "${PROJECT_ROOT}/manager.sh" "$tool" --help &> /dev/null; then
            success "Ferramenta $tool OK"
        else
            warning "Ferramenta $tool pode ter problemas"
        fi
    done
}

# =============================================================================
# VERIFICAÇÕES DE PERFORMANCE
# =============================================================================

check_performance() {
    log "=== VERIFICAÇÕES DE PERFORMANCE ==="

    # Verificar tempo de inicialização
    check_start "Tempo de inicialização do manager"
    local start_time
    local end_time
    local duration

    start_time=$(date +%s.%3N)
    timeout 3s bash "${PROJECT_ROOT}/manager.sh" help &> /dev/null
    end_time=$(date +%s.%3N)

    duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

    if (( $(echo "$duration < 2.0" | bc -l 2>/dev/null || echo "1") )); then
        success "Tempo de inicialização: ${duration}s"
    else
        warning "Tempo de inicialização lento: ${duration}s"
    fi

    # Verificar uso de CPU durante execução simples
    check_start "Uso de CPU durante execução"
    local cpu_before
    local cpu_after

    cpu_before=$(uptime | awk '{print $NF}' | sed 's/,//')
    timeout 5s bash "${PROJECT_ROOT}/manager.sh" status &> /dev/null
    cpu_after=$(uptime | awk '{print $NF}' | sed 's/,//')

    if (( $(echo "$cpu_after < $cpu_before + 50" | bc -l 2>/dev/null || echo "1") )); then
        success "Uso de CPU aceitável"
    else
        warning "Uso de CPU elevado detectado"
    fi
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

generate_report() {
    log ""
    log "================================================================================="
    log "                        RELATÓRIO DE HEALTH CHECK"
    log "================================================================================="
    log ""
    log "📊 Estatísticas:"
    log "   Total de verificações: $CHECKS_TOTAL"
    log "   ✅ Aprovadas: $CHECKS_PASSED"
    log "   ❌ Reprovadas: $CHECKS_FAILED"
    log "   ⚠️  Avisos: $CHECKS_WARNING"
    log ""

    local success_rate=0
    if [ $CHECKS_TOTAL -gt 0 ]; then
        success_rate=$(( (CHECKS_PASSED * 100) / CHECKS_TOTAL ))
    fi

    log "📈 Taxa de Sucesso: $success_rate%"
    log ""

    # Status geral
    if [ $success_rate -ge 95 ]; then
        log "🎯 Status Geral: ✅ EXCELENTE"
        log "   Sistema saudável e pronto para produção"
    elif [ $success_rate -ge 85 ]; then
        log "🎯 Status Geral: ✅ BOM"
        log "   Sistema funcional com pequenos ajustes necessários"
    elif [ $success_rate -ge 70 ]; then
        log "🎯 Status Geral: ⚠️ RAZOÁVEL"
        log "   Sistema funcional mas requer atenção"
    else
        log "🎯 Status Geral: ❌ PREOCUPANTE"
        log "   Sistema requer manutenção urgente"
    fi

    log ""
    log "📝 Log detalhado: $LOG_FILE"
    log "📅 Data/Hora: $(date)"
    log ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    log "Iniciando Health Check do Cluster AI"
    log "==================================="
    log "Diretório: $PROJECT_ROOT"
    log "Data/Hora: $(date)"
    log ""

    # Executar todas as verificações
    check_system_requirements
    check_dependencies
    check_files_and_permissions
    check_functionality
    check_performance

    # Gerar relatório
    generate_report

    # Retornar código baseado no status
    local success_rate=0
    if [ $CHECKS_TOTAL -gt 0 ]; then
        success_rate=$(( (CHECKS_PASSED * 100) / CHECKS_TOTAL ))
    fi

    if [ $success_rate -ge 85 ]; then
        log "✅ Health Check APROVADO"
        exit 0
    else
        log "❌ Health Check REPROVADO"
        exit 1
    fi
}

# Executar
main "$@"
