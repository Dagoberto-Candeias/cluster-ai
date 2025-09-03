#!/bin/bash

# 📋 Script de Teste para Múltiplas Distribuições - Cluster AI
# Autor: Sistema Cluster AI
# Descrição: Testa a instalação em diferentes distribuições Linux

set -e  # Sai no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/cluster_ai_distro_test.log"
TEST_RESULTS="/tmp/cluster_ai_test_results.json"

# Função para log
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Função para sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Função para erro
error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Função para warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Função para detectar distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Função para testar instalação básica
test_basic_installation() {
    local distro=$1
    log "Testando instalação básica em $distro..."
    
    # Testar se o script principal existe
    if [ ! -f "./install_cluster_universal.sh" ]; then
        error "Script install_cluster_universal.sh não encontrado"
        return 1
    fi
    
    # Testar permissões
    if [ ! -x "./install_cluster_universal.sh" ]; then
        chmod +x "./install_cluster_universal.sh"
    fi
    
    success "Script principal verificado em $distro"
    return 0
}

# Função para testar dependências
test_dependencies() {
    local distro=$1
    log "Testando dependências em $distro..."
    
    # Verificar dependências básicas
    local missing_deps=()
    
    for dep in curl git python3 docker; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        warning "Dependências faltando em $distro: ${missing_deps[*]}"
        # Tentar instalar dependências baseadas na distro
        install_dependencies "$distro" "${missing_deps[@]}"
    else
        success "Todas dependências presentes em $distro"
    fi
}

# Função para instalar dependências
install_dependencies() {
    local distro=$1
    shift
    local deps=("$@")
    
    log "Instalando dependências em $distro: ${deps[*]}"
    
    case "$distro" in
        ubuntu|debian)
            sudo apt update
            for dep in "${deps[@]}"; do
                case "$dep" in
                    docker) sudo apt install -y docker.io ;;
                    *) sudo apt install -y "$dep" ;;
                esac
            done
            ;;
        arch|manjaro)
            sudo pacman -Sy
            for dep in "${deps[@]}"; do
                case "$dep" in
                    docker) sudo pacman -S docker ;;
                    *) sudo pacman -S "$dep" ;;
                esac
            done
            ;;
        fedora|centos|rhel)
            sudo dnf update
            for dep in "${deps[@]}"; do
                case "$dep" in
                    docker) sudo dnf install -y docker ;;
                    *) sudo dnf install -y "$dep" ;;
                esac
            done
            ;;
        *)
            warning "Distribuição $distro não suportada para instalação automática"
            return 1
            ;;
    esac
    
    success "Dependências instaladas em $distro"
}

# Função para testar GPU
test_gpu() {
    local distro=$1
    log "Testando detecção de GPU em $distro..."
    
    # Verificar NVIDIA
    if lspci | grep -i nvidia &> /dev/null; then
        if command -v nvidia-smi &> /dev/null; then
            success "NVIDIA GPU detectada em $distro"
            nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
        else
            warning "NVIDIA detectada mas drivers não instalados em $distro"
        fi
    fi
    
    # Verificar AMD
    if lspci | grep -i "amd\|ati" &> /dev/null; then
        if command -v rocm-smi &> /dev/null; then
            success "AMD GPU detectada em $distro"
            rocm-smi --showproductname
        else
            warning "AMD detectada mas ROCm não instalado em $distro"
        fi
    fi
    
    # Se nenhuma GPU detectada
    if ! lspci | grep -i "nvidia\|amd\|ati" &> /dev/null; then
        warning "Nenhuma GPU dedicada detectada em $distro - modo CPU apenas"
    fi
}

# Função para testar ambiente Python
test_python_env() {
    local distro=$1
    log "Testando ambiente Python em $distro..."
    
    # Verificar Python
    if command -v python3 &> /dev/null; then
        python3 -c "
import sys
print(f'Python {sys.version}')
try:
    import torch
    print(f'PyTorch {torch.__version__}')
    print(f'CUDA disponível: {torch.cuda.is_available()}')
except ImportError:
    print('PyTorch não instalado')
"
        success "Python verificado em $distro"
    else
        error "Python3 não encontrado em $distro"
        return 1
    fi
}

# Função para teste rápido de funcionalidade
test_quick_functionality() {
    local distro=$1
    log "Teste rápido de funcionalidade em $distro..."
    
    # Testar scripts básicos
    local scripts=(
        "scripts/utils/health_check.sh"
        "scripts/utils/gpu_detection.sh"
        "scripts/installation/universal_install.sh --check"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script"; then
                success "Script $script validado sintaticamente em $distro"
            else
                error "Erro de sintaxe em $script em $distro"
            fi
        else
            warning "Script $script não encontrado em $distro"
        fi
    done
}

# Função principal de teste
main_test() {
    local distro=$(detect_distro)
    
    log "Iniciando testes no Cluster AI"
    log "Distribuição detectada: $distro"
    log "Diretório atual: $(pwd)"
    log "Usuário: $(whoami)"
    
    echo "{\"distro\": \"$distro\", \"tests\": [], \"timestamp\": \"$(date -Iseconds)\"}" > "$TEST_RESULTS"
    
    # Array de testes para executar
    local tests=(
        "test_basic_installation"
        "test_dependencies" 
        "test_gpu"
        "test_python_env"
        "test_quick_functionality"
    )
    
    local passed=0
    local total=${#tests[@]}
    
    for test_func in "${tests[@]}"; do
        log "Executando teste: $test_func"
        if $test_func "$distro"; then
            success "$test_func PASSOU"
            passed=$((passed + 1))
            # Atualizar JSON de resultados
            jq --arg test "$test_func" --arg status "passed" \
               '.tests += [{"name": $test, "status": $status}]' \
               "$TEST_RESULTS" > "${TEST_RESULTS}.tmp" && mv "${TEST_RESULTS}.tmp" "$TEST_RESULTS"
        else
            error "$test_func FALHOU"
            # Atualizar JSON de resultados
            jq --arg test "$test_func" --arg status "failed" \
               '.tests += [{"name": $test, "status": $status}]' \
               "$TEST_RESULTS" > "${TEST_RESULTS}.tmp" && mv "${TEST_RESULTS}.tmp" "$TEST_RESULTS"
        fi
    done
    
    # Calcular score final
    local score=$((passed * 100 / total))
    jq --arg score "$score" '.score = ($score | tonumber)' "$TEST_RESULTS" > "${TEST_RESULTS}.tmp" && mv "${TEST_RESULTS}.tmp" "$TEST_RESULTS"
    
    log "=========================================="
    log "RELATÓRIO FINAL DE TESTES - $distro"
    log "Testes executados: $total"
    log "Testes passados: $passed"
    log "Score: $score%"
    log "Log completo: $LOG_FILE"
    log "Resultados JSON: $TEST_RESULTS"
    log "=========================================="
    
    if [ $score -ge 80 ]; then
        success "✅ TESTES CONCLUÍDOS COM SUCESSO!"
        return 0
    elif [ $score -ge 50 ]; then
        warning "⚠️  TESTES COM RESULTADOS MISTOS"
        return 1
    else
        error "❌ TESTES FALHARAM"
        return 1
    fi
}

# Função para gerar relatório HTML
generate_html_report() {
    log "Gerando relatório HTML..."
    
    local html_report="/tmp/cluster_ai_test_report.html"
    
    cat > "$html_report" << EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Testes - Cluster AI</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .test { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; }
        .passed { border-color: #28a745; background: #f8fff9; }
        .failed { border-color: #dc3545; background: #fff8f8; }
        .score { font-size: 24px; font-weight: bold; margin: 20px 0; }
        .high { color: #28a745; }
        .medium { color: #ffc107; }
        .low { color: #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Relatório de Testes - Cluster AI</h1>
        <p><strong>Distribuição:</strong> $(jq -r '.distro' "$TEST_RESULTS")</p>
        <p><strong>Data:</strong> $(jq -r '.timestamp' "$TEST_RESULTS" | cut -d'T' -f1)</p>
    </div>
    
    <div class="score">
        Score: <span class="$(if [ $(jq -r '.score' "$TEST_RESULTS") -ge 80 ]; then echo "high"; elif [ $(jq -r '.score' "$TEST_RESULTS") -ge 50 ]; then echo "medium"; else echo "low"; fi)">
            $(jq -r '.score' "$TEST_RESULTS")%
        </span>
    </div>
    
    <h2>📋 Testes Executados</h2>
    $(jq -r '.tests[] | "<div class=\"test \(.status)\"><strong>\(.name)</strong>: \(.status)</div>"' "$TEST_RESULTS")
    
    <h2>📝 Log Completo</h2>
    <pre>$(cat "$LOG_FILE")</pre>
</body>
</html>
EOF
    
    success "Relatório HTML gerado: $html_report"
    echo "Abra o relatório: file://$html_report"
}

# Handler para limpeza
cleanup() {
    log "Limpando arquivos temporários..."
    rm -f "${TEST_RESULTS}.tmp"
}

# Configurar trap para limpeza
trap cleanup EXIT

# Execução principal
if [ "$1" = "--html" ]; then
    main_test
    generate_html_report
else
    main_test
fi

exit $?
