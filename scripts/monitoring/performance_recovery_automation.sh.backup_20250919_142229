#!/bin/bash
# Sistema de Automação de Recuperação de Performance
# Executa ações automatizadas para restaurar performance do sistema

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="${PROJECT_ROOT}/config"
LOGS_DIR="${PROJECT_ROOT}/logs"
BACKUP_DIR="${PROJECT_ROOT}/backups"
RECOVERY_DIR="${PROJECT_ROOT}/recovery"

# Arquivos de configuração
RECOVERY_CONFIG="${CONFIG_DIR}/recovery_automation.conf"
BACKUP_CONFIG="${CONFIG_DIR}/backup_strategy.conf"

# Arquivos de log e estado
RECOVERY_LOG="${LOGS_DIR}/recovery_automation.log"
BACKUP_LOG="${LOGS_DIR}/backup_operations.log"
SYSTEM_STATE="${RECOVERY_DIR}/system_state.json"
RECOVERY_SCRIPTS="${RECOVERY_DIR}/scripts"

# Configurações de recuperação
RECOVERY_CHECK_INTERVAL=60  # segundos
BACKUP_INTERVAL=3600  # 1 hora
MAX_BACKUPS=10
RECOVERY_TIMEOUT=600  # 10 minutos

