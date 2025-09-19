#!/bin/bash
# Script para consolidar e limpar scripts redundantes do Cluster AI
# Autor: Dagoberto Candeias <betoallnet@gmail.com>

set -euo pipefail

# --- Configurações ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/script_cleanup_$(date +%Y%m%d_%H%M%S)"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[CLEANUP]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Funções ---

# Criar backup antes da limpeza
create_backup() {
    log "Criando backup dos scripts antes da limpeza..."
    mkdir -p "$BACKUP_DIR"

    # Backup dos scripts Android redundantes
    if [ -d "$SCRIPT_DIR/scripts/android" ]; then
        cp -r "$SCRIPT_DIR/scripts/android" "$BACKUP_DIR/"
    fi

    # Backup dos scripts de backup antigos
    if [ -d "$SCRIPT_DIR/backups/android_scripts_before_consolidation" ]; then
        cp -r "$SCRIPT_DIR/backups/android_scripts_before_consolidation" "$BACKUP_DIR/"
    fi

    success "Backup criado em: $BACKUP_DIR"
}

# Identificar scripts redundantes
identify_redundant_scripts() {
    log "Identificando scripts redundantes..."

    local android_scripts=(
        "scripts/android/advanced_worker.sh"
        "scripts/android/install_improved.sh"
        "scripts/android/install_manual.sh"
        "scripts/android/install_offline.sh"
        "scripts/android/install_worker.sh"
        "scripts/android/quick_install.sh"
        "scripts/android/setup_android_worker_robust.sh"
        "scripts/android/setup_android_worker_simple.sh"
        "scripts/android/setup_github_auth.sh"
        "scripts/android/setup_github_ssh.sh"
        "scripts/android/test_android_worker.sh"
        "scripts/android/uninstall_android_worker_safe.sh"
        "scripts/android/uninstall_android_worker.sh"
    )

    local backup_scripts=(
        "backups/android_scripts_before_consolidation/advanced_worker.sh"
        "backups/android_scripts_before_consolidation/install_android_worker.sh"
        "backups/android_scripts_before_consolidation/manual_install.sh"
        "backups/android_scripts_before_consolidation/setup_android_worker_robust.sh"
        "backups/android_scripts_before_consolidation/setup_android_worker_simple.sh"
        "backups/android_scripts_before_consolidation/setup_android_worker.sh"
        "backups/android_scripts_before_consolidation/setup_github_ssh.sh"
        "backups/android_scripts_before_consolidation/test_android_worker.sh"
    )

    echo "Scripts Android redundantes encontrados:"
    for script in "${android_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            echo "  - $script"
        fi
    done

    echo ""
    echo "Scripts de backup antigos encontrados:"
    for script in "${backup_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            echo "  - $script"
        fi
    done
}

# Remover scripts redundantes
remove_redundant_scripts() {
    log "Removendo scripts redundantes..."

    # Scripts Android redundantes (manter apenas setup_android_worker.sh)
    local android_to_remove=(
        "scripts/android/advanced_worker.sh"
        "scripts/android/install_improved.sh"
        "scripts/android/install_manual.sh"
        "scripts/android/install_offline.sh"
        "scripts/android/install_worker.sh"
        "scripts/android/quick_install.sh"
        "scripts/android/setup_android_worker_robust.sh"
        "scripts/android/setup_android_worker_simple.sh"
        "scripts/android/setup_github_auth.sh"
        "scripts/android/setup_github_ssh.sh"
        "scripts/android/test_android_worker.sh"
        "scripts/android/uninstall_android_worker_safe.sh"
        "scripts/android/uninstall_android_worker.sh"
    )

    for script in "${android_to_remove[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            rm "$SCRIPT_DIR/$script"
            success "Removido: $script"
        fi
    done

    # Manter apenas o diretório de backups antigo (já está em backups/)
    # Não remover backups/android_scripts_before_consolidation/
    # pois serve como histórico
}

# Criar arquivo de manifesto dos scripts consolidados
create_manifest() {
    log "Criando manifesto dos scripts consolidados..."

    local manifest_file="$SCRIPT_DIR/SCRIPTS_MANIFEST.md"

    cat > "$manifest_file" << 'EOF'
# Manifesto dos Scripts Consolidados - Cluster AI

## Scripts Ativos e Funcionais

### Core Scripts
- `manager.sh` - Gerenciador principal do cluster
- `scripts/lib/common.sh` - Biblioteca de funções comuns

### Worker Setup Scripts
- `scripts/android/setup_android_worker.sh` - Configuração automática de worker Android
- `scripts/installation/setup_generic_worker.sh` - Configuração automática de worker Linux/Unix

### Management Scripts
- `scripts/management/worker_registration.sh` - Processa registro automático de workers
- `scripts/management/network_discovery.sh` - Descoberta automática de nós na rede

### Maintenance Scripts
- `scripts/maintenance/backup_manager.sh` - Gerenciamento de backups
- `scripts/maintenance/consolidate_scripts.sh` - Este script de consolidação

## Scripts Removidos (Redundantes)

### Android Worker Scripts (Removidos)
Estes scripts foram consolidados em `setup_android_worker.sh`:
- advanced_worker.sh
- install_improved.sh
- install_manual.sh
- install_offline.sh
- install_worker.sh
- quick_install.sh
- setup_android_worker_robust.sh
- setup_android_worker_simple.sh
- setup_github_auth.sh
- setup_github_ssh.sh
- test_android_worker.sh
- uninstall_android_worker_safe.sh
- uninstall_android_worker.sh

### Backup Location
Scripts removidos foram backupados em:
`backups/script_cleanup_YYYYMMDD_HHMMSS/`

## Funcionalidades Consolidadas

### Sistema Plug-and-Play
- ✅ Descoberta automática de workers na rede
- ✅ Registro automático no servidor
- ✅ Suporte a Android (Termux) e Linux/Unix
- ✅ Gerenciamento integrado via manager.sh

### Segurança
- ✅ Geração automática de chaves SSH
- ✅ Validação de dados de registro
- ✅ Armazenamento seguro de chaves públicas

### Monitoramento
- ✅ Verificação automática de status
- ✅ Logs detalhados de operações
- ✅ Interface unificada no manager.sh

## Como Usar

### Para Workers Android
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash
```

### Para Workers Linux/Unix
```bash
wget https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/setup_generic_worker.sh
chmod +x setup_generic_worker.sh
./setup_generic_worker.sh
```

### Gerenciamento via Manager
```bash
./manager.sh
# Escolher: 15) ⚙️ Configurar Workers (Remoto/Android)
```

## Manutenção

Para manter a organização:
1. Novos scripts devem ser adicionados em diretórios apropriados
2. Scripts redundantes devem ser identificados e consolidados
3. Este manifesto deve ser atualizado após mudanças significativas

---
Gerado automaticamente em: $(date)
EOF

    success "Manifesto criado: $manifest_file"
}

# Verificar integridade após limpeza
verify_integrity() {
    log "Verificando integridade dos scripts restantes..."

    local critical_scripts=(
        "manager.sh"
        "scripts/lib/common.sh"
        "scripts/android/setup_android_worker.sh"
        "scripts/installation/setup_generic_worker.sh"
        "scripts/management/worker_registration.sh"
        "scripts/management/network_discovery.sh"
    )

    local missing_scripts=()

    for script in "${critical_scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            missing_scripts+=("$script")
        fi
    done

    if [ ${#missing_scripts[@]} -gt 0 ]; then
        error "Scripts críticos faltando:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
        return 1
    fi

    success "Todos os scripts críticos estão presentes"
}

# Função principal
main() {
    section "Consolidação de Scripts do Cluster AI"

    echo "Este script irá:"
    echo "1. Identificar scripts redundantes"
    echo "2. Criar backup dos scripts a serem removidos"
    echo "3. Remover scripts redundantes"
    echo "4. Criar manifesto dos scripts consolidados"
    echo "5. Verificar integridade do sistema"
    echo

    if ! confirm_operation "Deseja continuar com a consolidação?"; then
        warn "Operação cancelada"
        exit 0
    fi

    # Executar etapas
    identify_redundant_scripts
    echo

    if confirm_operation "Criar backup antes da limpeza?"; then
        create_backup
    fi

    if confirm_operation "Remover scripts redundantes?"; then
        remove_redundant_scripts
    fi

    create_manifest
    verify_integrity

    section "Consolidação Concluída"
    success "Scripts consolidados com sucesso!"
    info "Backup criado em: $BACKUP_DIR"
    info "Manifesto criado em: $SCRIPT_DIR/SCRIPTS_MANIFEST.md"
}

# Carregar função de confirmação se não estiver disponível
confirm_operation() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}AVISO:${NC} $message (s/N) ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}

section() {
    echo -e "\n${BLUE}=======================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=======================================================================${NC}"
}

main "$@"
