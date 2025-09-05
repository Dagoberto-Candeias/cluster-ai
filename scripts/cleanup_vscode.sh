#!/bin/bash

# Script de limpeza para otimizar performance do VSCode no projeto Cluster AI
# Remove arquivos temporários, caches e processos desnecessários

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${BLUE}[CLEANUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "manager.sh" ]; then
    error "Execute este script do diretório raiz do projeto Cluster AI"
    exit 1
fi

log "Iniciando limpeza para otimizar VSCode..."

# 1. Limpar caches Python
log "Limpando caches Python..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type f -name "*.pyd" -delete 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true

# 2. Limpar logs antigos
log "Limpando logs antigos..."
find logs/ -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true
find test_logs/ -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true

# 3. Limpar arquivos temporários
log "Limpando arquivos temporários..."
find . -type f -name "*.tmp" -delete 2>/dev/null || true
find . -type f -name "*.bak" -delete 2>/dev/null || true
find . -type f -name "*~" -delete 2>/dev/null || true
find . -type f -name ".DS_Store" -delete 2>/dev/null || true

# 4. Limpar backups antigos (manter apenas os últimos 5)
log "Organizando backups..."
if [ -d "backups" ]; then
    # Manter apenas os 5 backups mais recentes
    ls -t backups/ | tail -n +6 | xargs -I {} rm -rf "backups/{}" 2>/dev/null || true
fi

# 5. Limpar arquivos de relatórios antigos
log "Limpando relatórios antigos..."
find reports/ -type f -name "*.txt" -mtime +30 -delete 2>/dev/null || true
find project_analysis/reports/ -type f -name "*.txt" -mtime +30 -delete 2>/dev/null || true

# 6. Verificar e limpar processos do VSCode se necessário
log "Verificando processos em execução..."
if pgrep -f "vscode" > /dev/null; then
    warn "VSCode está rodando. Considere fechar e reabrir para aplicar as otimizações."
fi

# 7. Verificar tamanho dos diretórios
log "Verificando tamanho dos diretórios..."
du -sh backups/ 2>/dev/null || echo "backups/: diretório não encontrado"
du -sh logs/ 2>/dev/null || echo "logs/: diretório não encontrado"
du -sh test_logs/ 2>/dev/null || echo "test_logs/: diretório não encontrado"
du -sh reports/ 2>/dev/null || echo "reports/: diretório não encontrado"

# 8. Criar arquivo .vscodeignore se não existir
if [ ! -f ".vscodeignore" ]; then
    log "Criando .vscodeignore..."
    cat > .vscodeignore << 'EOF'
# Arquivos e pastas a ignorar no VSCode
backups/
logs/
test_logs/
reports/
data/
models/
metrics/
run/
android/
alerts/
certs/
configs/
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/
*.log
*.tmp
*.bak
*~
.DS_Store
Thumbs.db
EOF
fi

# 9. Otimizar .gitignore se necessário
if [ -f ".gitignore" ]; then
    log "Verificando .gitignore..."
    # Adicionar entradas importantes se não existirem
    grep -q "__pycache__" .gitignore || echo "__pycache__/" >> .gitignore
    grep -q "*.pyc" .gitignore || echo "*.pyc" >> .gitignore
    grep -q ".pytest_cache" .gitignore || echo ".pytest_cache/" >> .gitignore
    grep -q "*.log" .gitignore || echo "*.log" >> .gitignore
fi

success "Limpeza concluída!"
echo
echo "📋 PRÓXIMOS PASSOS RECOMENDADOS:"
echo "1. Feche o VSCode completamente"
echo "2. Execute: killall code || killall code-insiders"
echo "3. Reabra o VSCode no projeto"
echo "4. Aguarde a indexação inicial (pode demorar alguns minutos)"
echo "5. Verifique se a performance melhorou"
echo
echo "💡 DICAS ADICIONAIS:"
echo "- Mantenha menos de 10 abas abertas simultaneamente"
echo "- Use Ctrl+Shift+P > 'Developer: Reload Window' se necessário"
echo "- Desative extensões não utilizadas via Ctrl+Shift+X"
echo "- Configure 'Files: Exclude' nas configurações do workspace"
