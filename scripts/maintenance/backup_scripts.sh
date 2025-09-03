#!/bin/bash
# Script de Backup dos Scripts do Cluster AI
# Cria backups organizados antes de modificações

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções auxiliares
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Diretório de backup
BACKUP_DIR="backups/scripts_backup_$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="scripts_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Criar diretório de backup
create_backup_dir() {
    log "Criando diretório de backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    success "Diretório criado"
}

# Backup de scripts da raiz
backup_root_scripts() {
    log "Fazendo backup dos scripts da raiz..."

    # Lista de scripts importantes na raiz
    local root_scripts=(
        "install.sh"
        "install_unified.sh"
        "manager.sh"
        "get-docker.sh"
        "start_cluster.sh"
        "demo_cluster.py"
        "simple_demo.py"
        "test_installation.py"
        "test_pytorch_functionality.py"
    )

    mkdir -p "$BACKUP_DIR/root_scripts"

    for script in "${root_scripts[@]}"; do
        if [ -f "$script" ]; then
            cp "$script" "$BACKUP_DIR/root_scripts/"
            log "Backup: $script"
        else
            warn "Script não encontrado: $script"
        fi
    done

    success "Backup dos scripts da raiz concluído"
}

# Backup de scripts organizados
backup_organized_scripts() {
    log "Fazendo backup dos scripts organizados..."

    # Diretórios a fazer backup
    local dirs=(
        "scripts/installation"
        "scripts/setup"
        "scripts/vscode"
        "scripts/maintenance"
        "scripts/utils"
        "scripts/android"
    )

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            mkdir -p "$BACKUP_DIR/$dir"
            cp -r "$dir"/* "$BACKUP_DIR/$dir/" 2>/dev/null || true
            log "Backup: $dir"
        else
            warn "Diretório não encontrado: $dir"
        fi
    done

    success "Backup dos scripts organizados concluído"
}

# Backup de arquivos de configuração
backup_config_files() {
    log "Fazendo backup dos arquivos de configuração..."

    local config_files=(
        "requirements.txt"
        "cluster.conf"
        "cluster.conf.example"
        ".gitignore"
        "packages.microsoft.gpg"
    )

    mkdir -p "$BACKUP_DIR/config"

    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_DIR/config/"
            log "Backup: $file"
        else
            warn "Arquivo não encontrado: $file"
        fi
    done

    success "Backup dos arquivos de configuração concluído"
}

# Criar arquivo de manifesto
create_manifest() {
    log "Criando manifesto do backup..."

    cat > "$BACKUP_DIR/BACKUP_MANIFEST.txt" << EOF
BACKUP MANIFEST - CLUSTER AI SCRIPTS
====================================

Data/Hora: $(date)
Diretório: $BACKUP_DIR
Arquivo: $ARCHIVE_NAME

CONTEÚDO DO BACKUP:
==================

SCRIPTS DA RAIZ:
$(ls -la "$BACKUP_DIR/root_scripts/" 2>/dev/null || echo "Nenhum script encontrado")

SCRIPTS ORGANIZADOS:
$(find "$BACKUP_DIR/scripts/" -type f -name "*.sh" -o -name "*.py" -o -name "*.md" | sort)

ARQUIVOS DE CONFIGURAÇÃO:
$(ls -la "$BACKUP_DIR/config/" 2>/dev/null || echo "Nenhum arquivo encontrado")

ESTRUTURA FINAL:
$(find "$BACKUP_DIR" -type f | sort)

NOTAS:
======
- Este backup foi criado automaticamente pelo script backup_scripts.sh
- Use este backup para restaurar arquivos se necessário
- Para restaurar: tar -xzf $ARCHIVE_NAME
EOF

    success "Manifesto criado"
}

# Criar arquivo compactado
create_archive() {
    log "Criando arquivo compactado..."

    if command -v tar &> /dev/null; then
        tar -czf "$ARCHIVE_NAME" -C "$BACKUP_DIR" .
        success "Arquivo compactado criado: $ARCHIVE_NAME"
    else
        warn "tar não encontrado, mantendo apenas diretório"
    fi
}

# Mostrar resumo
show_summary() {
    echo
    echo "📊 RESUMO DO BACKUP"
    echo "==================="
    echo
    echo "📁 Diretório: $BACKUP_DIR"
    echo "📦 Arquivo: $ARCHIVE_NAME"
    echo
    echo "📂 Conteúdo:"
    find "$BACKUP_DIR" -type f | wc -l | xargs echo "   Arquivos: "
    du -sh "$BACKUP_DIR" | cut -f1 | xargs echo "   Tamanho: "
    echo
    echo "📋 Arquivos importantes:"
    find "$BACKUP_DIR" -name "*.sh" -o -name "*.py" | head -10
    echo
    echo "🔧 Para restaurar:"
    echo "   tar -xzf $ARCHIVE_NAME"
    echo "   # ou copie os arquivos de $BACKUP_DIR"
    echo
}

# Função principal
main() {
    echo
    echo "💾 BACKUP DE SCRIPTS - CLUSTER AI"
    echo "================================="
    echo

    log "Iniciando processo de backup..."

    # Verificar se já existe backup recente
    if ls backups/scripts_backup_* 2>/dev/null | head -5 | grep -q .; then
        echo "Backups recentes encontrados:"
        ls -la backups/scripts_backup_* 2>/dev/null | head -5
        echo
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Backup cancelado pelo usuário"
            exit 0
        fi
    fi

    # Executar backup
    create_backup_dir
    backup_root_scripts
    backup_organized_scripts
    backup_config_files
    create_manifest
    create_archive
    show_summary

    echo
    success "BACKUP CONCLUÍDO COM SUCESSO!"
    echo
    warn "IMPORTANTE: Mantenha este backup seguro!"
    echo
}

# Executar
main "$@"
