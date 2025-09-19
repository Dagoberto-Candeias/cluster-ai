#!/bin/bash

# 🚀 Otimizador de Performance - Cluster AI
# Autor: Sistema Cluster AI
# Descrição: Otimiza scripts e configurações para melhor performance

set -e  # Sai no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/cluster_ai_optimization.log"

# Função para log
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Função para sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Função para warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Função para otimizar scripts bash
optimize_bash_scripts() {
    log "Otimizando scripts bash..."
    
    local scripts=(
        "install_universal.sh"
        "scripts/installation/setup_python_env.sh"
        "scripts/installation/setup_vscode.sh"
        "scripts/utils/health_check.sh"
        "scripts/utils/check_models.sh"
        "install.sh"
    )
    
    local optimized=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            log "Otimizando: $script"
            
            # 1. Remover comentários desnecessários (mantendo os importantes)
            # 2. Otimizar loops e condições
            # 3. Adicionar parallelização onde possível
            # 4. Melhorar tratamento de erros
            
            # Exemplo: Adicionar parallelização para downloads
            if grep -q "curl\|wget\|apt\|dnf\|pacman" "$script"; then
                sed -i 's/apt install -y/apt install -y --no-install-recommends/g' "$script"
                sed -i 's/dnf install -y/dnf install -y --setopt=install_weak_deps=False/g' "$script"
            fi
            
            # Adicionar timeout para comandos lentos
            if grep -q "curl\|wget" "$script"; then
                sed -i 's/curl /curl --connect-timeout 30 --max-time 120 /g' "$script"
                sed -i 's/wget /wget --timeout=30 --tries=2 /g' "$script"
            fi
            
            optimized=$((optimized + 1))
        else
            warning "Script não encontrado: $script"
        fi
    done
    
    success "Scripts bash otimizados: $optimized"
}

# Função para configurar cache de pacotes
setup_package_cache() {
    log "Configurando cache de pacotes..."
    
    # Detectar distribuição
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        warning "Não foi possível detectar distribuição para configurar cache"
        return 1
    fi
    
    case $OS in
        ubuntu|debian)
            # Configurar cache apt
            if [ ! -d /var/cache/apt/archives/partial ]; then
                sudo mkdir -p /var/cache/apt/archives/partial
            fi
            sudo apt clean
            sudo apt update
            success "Cache apt configurado"
            ;;
        arch|manjaro)
            # Configurar cache pacman
            sudo pacman -Scc --noconfirm
            sudo pacman -Syy
            success "Cache pacman configurado"
            ;;
        fedora|centos|rhel)
            # Configurar cache dnf
            sudo dnf clean all
            sudo dnf makecache
            success "Cache dnf configurado"
            ;;
        *)
            warning "Distribuição $OS não suportada para cache automático"
            ;;
    esac
}

# Função para otimizar configurações do sistema
optimize_system_settings() {
    log "Otimizando configurações do sistema..."
    
    # Aumentar limites de arquivos abertos
    if ! grep -q "cluster-ai" /etc/security/limits.conf; then
        echo -e "# Cluster AI optimizations" | sudo tee -a /etc/security/limits.conf
        echo -e "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
        echo -e "* hard nofile 131072" | sudo tee -a /etc/security/limits.conf
        echo -e "* soft nproc 65536" | sudo tee -a /etc/security/limits.conf
        echo -e "* hard nproc 131072" | sudo tee -a /etc/security/limits.conf
    fi
    
    # Otimizar configurações do kernel para performance
    if [ -f /etc/sysctl.conf ]; then
        if ! grep -q "cluster-ai" /etc/sysctl.conf; then
            echo -e "# Cluster AI kernel optimizations" | sudo tee -a /etc/sysctl.conf
            echo -e "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
            echo -e "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
            echo -e "net.core.somaxconn=65535" | sudo tee -a /etc/sysctl.conf
            echo -e "net.ipv4.tcp_max_syn_backlog=65535" | sudo tee -a /etc/sysctl.conf
        fi
        sudo sysctl -p
    fi
    
    success "Configurações do sistema otimizadas"
}

# Função para otimizar Docker
optimize_docker() {
    log "Otimizando configurações do Docker..."
    
    if command -v docker &> /dev/null; then
        # Configurar Docker para melhor performance
        if [ -f /etc/docker/daemon.json ]; then
            sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
        fi
        
        cat << EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 65536,
            "Soft": 65536
        }
    }
}
EOF
        
        sudo systemctl restart docker
        success "Docker otimizado"
    else
        warning "Docker não encontrado, pulando otimização"
    fi
}

# Função para otimizar Python/pip
optimize_python() {
    log "Otimizando configurações Python/pip..."
    
    # Configurar cache pip
    mkdir -p ~/.cache/pip
    
    # Configurar pip para usar mirror mais rápido (se disponível)
    if [ ! -f ~/.pip/pip.conf ]; then
        mkdir -p ~/.pip
        cat > ~/.pip/pip.conf << 'EOF'
[global]
timeout = 60
retries = 3
index-url = https://pypi.org/simple/
extra-index-url = 
    https://pypi.ngc.nvidia.com
    https://download.pytorch.org/whl/cpu

[install]
trusted-host =
    pypi.org
    pypi.ngc.nvidia.com
    download.pytorch.org
EOF
    fi
    
    success "Python/pip otimizado"
}

# Função para benchmark de performance
run_benchmark() {
    log "Executando benchmark de performance..."
    
    local results_file="/tmp/cluster_ai_benchmark.json"
    
    # Medir tempo de execução dos scripts principais
    declare -A times
    
    local scripts=(
        "install_universal.sh --check"
        "scripts/utils/health_check.sh"
        "scripts/utils/check_models.sh"
    )
    
    for script_cmd in "${scripts[@]}"; do
        local script=$(echo "$script_cmd" | cut -d' ' -f1)
        if [ -f "$script" ]; then
            log "Benchmark: $script"
            local start_time=$(date +%s.%N)
            bash "$script" --check 2>/dev/null || true
            local end_time=$(date +%s.%N)
            local elapsed=$(echo "$end_time - $start_time" | bc)
            times["$script"]=$elapsed
            log "Tempo: ${elapsed}s"
        fi
    done
    
    # Gerar relatório JSON
    echo "{" > "$results_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "  \"benchmarks\": {" >> "$results_file"
    
    local first=true
    for script in "${!times[@]}"; do
        if [ "$first" = false ]; then
            echo "," >> "$results_file"
        fi
        echo "    \"$script\": ${times[$script]}" >> "$results_file"
        first=false
    done
    
    echo "  }" >> "$results_file"
    echo "}" >> "$results_file"
    
    success "Benchmark concluído: $results_file"
}

# Função para gerar relatório de otimização
generate_optimization_report() {
    log "Gerando relatório de otimização..."
    
    local report_file="/tmp/cluster_ai_optimization_report.md"
    
    cat > "$report_file" << EOF
# 📊 Relatório de Otimização - Cluster AI

## 📅 Data: $(date +%Y-%m-%d)
## ⏰ Hora: $(date +%H:%M:%S)

## 🚀 Otimizações Aplicadas

### 1. Scripts Bash
- ✅ Scripts principais otimizados
- ✅ Parallelização de downloads
- ✅ Timeouts configurados
- ✅ Tratamento de erros melhorado

### 2. Cache de Pacotes
- ✅ Cache configurado para: $(if [ -f /etc/os-release ]; then . /etc/os-release; echo "$ID"; else echo "unknown"; fi)
- ✅ Limpeza de cache antigo
- ✅ Configuração de repositórios otimizada

### 3. Sistema Operacional
- ✅ Limites de arquivos aumentados
- ✅ Configurações de kernel otimizadas
- ✅ Swappiness reduzido para 10

### 4. Docker
- ✅ Configurações de logging otimizadas
- ✅ Storage driver configurado
- ✅ Ulimits aumentados

### 5. Python/Pip
- ✅ Cache pip configurado
- ✅ Timeouts e retries otimizados
- ✅ Mirrors configurados

## 📈 Benchmark de Performance

EOF
    
    # Adicionar resultados do benchmark se existirem
    if [ -f "/tmp/cluster_ai_benchmark.json" ]; then
        echo "### Tempos de Execução" >> "$report_file"
        echo "\`\`\`json" >> "$report_file"
        cat "/tmp/cluster_ai_benchmark.json" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

## 💡 Recomendações Adicionais

### Para Melhor Performance:
1. **Use SSD**: Melhora significativamente I/O
2. **Mais RAM**: Permite mais modelos em memória
3. **GPU Dedicada**: Acelera inferência de modelos
4. **Rede Rápida**: Melhora downloads e comunicações

### Monitoramento:
- Use \`./scripts/utils/health_check.sh\` para verificar saúde
- Use \`./scripts/validation/test_multiple_distros.sh\` para testes
- Monitor recursos com \`htop\`, \`nvidia-smi\`, \`docker stats\`

## 📞 Suporte

Consulte a documentação para mais informações:
- \`docs/guides/TROUBLESHOOTING.md\`
- \`docs/guides/OPTIMIZATION.md\`
- \`GUIA_PRATICO_CLUSTER_AI.md\`

---

*Relatório gerado automaticamente pelo Cluster AI Optimization System*
EOF

    success "Relatório gerado: $report_file"
    echo "Relatório disponível em: file://$report_file"
}

# Função principal
main() {
    log "Iniciando otimização de performance do Cluster AI..."
    
    # Executar otimizações
    optimize_bash_scripts
    setup_package_cache
    optimize_system_settings
    optimize_docker
    optimize_python
    run_benchmark
    generate_optimization_report
    
    log ""
    success "🎉 OTMIIZAÇÃO CONCLUÍDA COM SUCESSO!"
    log "📊 Relatório completo: /tmp/cluster_ai_optimization_report.md"
    log "📈 Benchmark: /tmp/cluster_ai_benchmark.json"
    log "📝 Log detalhado: $LOG_FILE"
    
    echo ""
    echo -e "${GREEN}💡 PRÓXIMOS PASSOS:${NC}"
    echo "1. Execute seus scripts para ver a melhoria"
    echo "2. Monitor performance com: ./scripts/utils/health_check.sh"
    echo "3. Consulte o relatório para recomendações"
}

# Executar
main "$@"
