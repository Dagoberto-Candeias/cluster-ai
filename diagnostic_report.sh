#!/bin/bash

# Cluster AI - Comprehensive Diagnostic Report
# Generated: $(date)

set -e

echo "🔍 CLUSTER AI - RELATÓRIO DIAGNÓSTICO ABRANGENTE"
echo "=================================================="
echo "Data: $(date)"
echo "Diretório: $(pwd)"
echo ""

# 1. SISTEMA OPERACIONAL E RECURSOS
echo "1. 📊 SISTEMA OPERACIONAL E RECURSOS"
echo "-------------------------------------"
echo "Sistema: $(uname -a)"
echo "Distribuição: $(lsb_release -d 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "CPU: $(nproc) cores - $(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2 | sed 's/^ *//')"
echo "Memória Total: $(free -h | grep Mem | awk '{print $2}')"
echo "Memória Disponível: $(free -h | grep Mem | awk '{print $7}')"
echo "Disco: $(df -h / | tail -1 | awk '{print $4 " disponível de " $2}')"
echo ""

# 2. AMBIENTE PYTHON
echo "2. 🐍 AMBIENTE PYTHON"
echo "---------------------"
if [ -d "cluster-ai-env" ]; then
    echo "✅ Ambiente virtual encontrado: cluster-ai-env"
    source cluster-ai-env/bin/activate
    echo "Python: $(python --version)"
    echo "Pip: $(pip --version)"
    echo "Local do ambiente: $(which python)"
else
    echo "❌ Ambiente virtual NÃO encontrado"
fi
echo ""

# 3. DEPENDÊNCIAS PYTHON
echo "3. 📦 DEPENDÊNCIAS PYTHON"
echo "-------------------------"
echo "Verificando dependências críticas..."
python -c "
try:
    import flask, fastapi, dask, torch, ollama
    print('✅ Dependências principais OK')
except ImportError as e:
    print(f'❌ Falta dependência: {e}')
"
echo ""

# 4. ESTRUTURA DE DIRETÓRIOS
echo "4. 📁 ESTRUTURA DE DIRETÓRIOS"
echo "-----------------------------"
echo "Scripts encontrados: $(find scripts/ -name "*.sh" -type f 2>/dev/null | wc -l)"
echo "Arquivos Python: $(find . -name "*.py" -type f -not -path "./node_modules/*" -not -path "./cluster-ai-env/*" -not -path "./__pycache__/*" 2>/dev/null | wc -l)"
echo "Diretórios principais:"
ls -la | grep "^d" | awk '{print "  " $9}' | head -10
echo ""

# 5. PERMISSÕES DE SCRIPTS
echo "5. 🔐 PERMISSÕES DE SCRIPTS"
echo "---------------------------"
echo "Scripts sem permissão de execução:"
find scripts/ -name "*.sh" -type f ! -executable 2>/dev/null | head -5 || echo "  Nenhum encontrado"
echo "Scripts com permissão de execução: $(find scripts/ -name "*.sh" -type f -executable 2>/dev/null | wc -l)"
echo ""

# 6. SINTAXE DE SCRIPTS
echo "6. 📝 SINTAXE DE SCRIPTS"
echo "-----------------------"
echo "Verificando sintaxe dos scripts..."
bash_syntax_errors=$(find scripts/ -name "*.sh" -type f -executable -exec bash -n {} \; 2>&1 | wc -l)
if [ "$bash_syntax_errors" -eq 0 ]; then
    echo "✅ Nenhum erro de sintaxe encontrado em scripts Bash"
else
    echo "❌ $bash_syntax_errors erros de sintaxe encontrados"
fi

echo "Verificando sintaxe Python..."
python_syntax_errors=$(python -m py_compile $(find . -name "*.py" -type f -not -path "./node_modules/*" -not -path "./cluster-ai-env/*" -not -path "./__pycache__/*" 2>/dev/null) 2>&1 | wc -l)
if [ "$python_syntax_errors" -eq 0 ]; then
    echo "✅ Nenhum erro de sintaxe encontrado em arquivos Python"
else
    echo "❌ $python_syntax_errors erros de sintaxe encontrados"
fi
echo ""

# 7. CONFIGURAÇÕES
echo "7. ⚙️ CONFIGURAÇÕES"
echo "-------------------"
echo "Arquivos de configuração encontrados:"
find . -name "*.yaml" -o -name "*.yml" -o -name "*.conf" -o -name "*.ini" -o -name "*.env*" | grep -v cluster-ai-env | head -5
echo ""

# 8. SERVIÇOS E PORTAS
echo "8. 🌐 SERVIÇOS E PORTAS"
echo "-----------------------"
echo "Portas em uso:"
netstat -tlnp 2>/dev/null | grep LISTEN | head -5 || ss -tlnp | head -5 || echo "  Não foi possível verificar portas"
echo ""

# 9. LOGS RECENTES
echo "9. 📋 LOGS RECENTES"
echo "-------------------"
echo "Arquivos de log encontrados:"
find logs/ -name "*.log" -type f 2>/dev/null | head -3 || echo "  Nenhum log encontrado"
echo ""

# 10. TESTES DISPONÍVEIS
echo "10. 🧪 TESTES DISPONÍVEIS"
echo "-------------------------"
echo "Arquivos de teste encontrados: $(find tests/ -name "*.py" -type f 2>/dev/null | wc -l)"
echo "Scripts de validação: $(find scripts/validation/ -name "*.sh" -type f 2>/dev/null | wc -l)"
echo ""

# 11. WORKERS CONFIGURADOS
echo "11. 👥 WORKERS CONFIGURADOS"
echo "---------------------------"
if [ -f "cluster.yaml" ]; then
    echo "Arquivo cluster.yaml encontrado"
    worker_count=$(grep -c "worker_" cluster.yaml 2>/dev/null || echo "0")
    echo "Workers configurados: $worker_count"
else
    echo "❌ Arquivo cluster.yaml NÃO encontrado"
fi
echo ""

# 12. MODELOS OLLAMA
echo "12. 🤖 MODELOS OLLAMA"
echo "---------------------"
if command -v ollama &> /dev/null; then
    echo "✅ Ollama instalado"
    echo "Modelos disponíveis: $(ollama list 2>/dev/null | wc -l)"
else
    echo "❌ Ollama NÃO instalado"
fi
echo ""

# 13. DOCKER
echo "13. 🐳 DOCKER"
echo "------------"
if command -v docker &> /dev/null; then
    echo "✅ Docker instalado: $(docker --version)"
    echo "Containers em execução: $(docker ps 2>/dev/null | wc -l)"
else
    echo "❌ Docker NÃO instalado"
fi
echo ""

# 14. RESUMO EXECUTIVO
echo "14. 📊 RESUMO EXECUTIVO"
echo "======================="
echo "✅ Itens funcionando:"
echo "  - Ambiente virtual: $([ -d "cluster-ai-env" ] && echo "OK" || echo "FALTA")"
echo "  - Scripts executáveis: $(find scripts/ -name "*.sh" -type f -executable 2>/dev/null | wc -l)"
echo "  - Arquivos Python: $(find . -name "*.py" -type f -not -path "./node_modules/*" -not -path "./cluster-ai-env/*" -not -path "./__pycache__/*" 2>/dev/null | wc -l)"
echo "  - Sintaxe scripts: $([ "$bash_syntax_errors" -eq 0 ] && echo "OK" || echo "ERROS")"
echo "  - Sintaxe Python: $([ "$python_syntax_errors" -eq 0 ] && echo "OK" || echo "ERROS")"
echo ""
echo "⚠️ Itens para verificar:"
echo "  - Dependências Python específicas"
echo "  - Configurações de rede"
echo "  - Permissões de arquivos"
echo "  - Configuração de workers"
echo ""

echo "🎯 PRÓXIMOS PASSOS RECOMENDADOS:"
echo "1. Corrigir erros de sintaxe encontrados"
echo "2. Verificar permissões de arquivos"
echo "3. Configurar workers adequadamente"
echo "4. Testar inicialização de serviços"
echo "5. Executar suíte de testes completa"
echo ""

echo "📅 Relatório gerado em: $(date)"
echo "🔍 Diagnóstico concluído"
