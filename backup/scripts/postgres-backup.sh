#!/bin/bash
# =============================================================================
# Cluster AI PostgreSQL Backup Script
# =============================================================================
# This script creates automated backups of PostgreSQL database
#
# Author: Cluster AI Team
# Date: 2025-01-20
# Version: 1.0.0
# File: postgres-backup.sh
# =============================================================================

set -euo pipefail

# --- Configuration ---
BACKUP_DIR="${BACKUP_DIR:-/backup}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="postgres_backup_${TIMESTAMP}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"
LOG_FILE="${BACKUP_DIR}/postgres_backup.log"

# PostgreSQL connection settings
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-postgres}"
PG_PASSWORD="${PG_PASSWORD:-}"
PG_DATABASE="${PG_DATABASE:-postgres}"

# Retention settings
MAX_BACKUPS="${MAX_BACKUPS:-7}"

# --- Functions ---

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo "[$timestamp] [$level] $message"
}

# Error handling
error_exit() {
    local message="$1"
    log "ERROR" "$message"
    exit 1
}

# Create backup directory
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory: $BACKUP_DIR"
        log "INFO" "Created backup directory: $BACKUP_DIR"
    fi
}

# Test PostgreSQL connection
test_connection() {
    log "INFO" "Testing PostgreSQL connection..."

    # Set password if provided
    if [[ -n "$PG_PASSWORD" ]]; then
        export PGPASSWORD="$PG_PASSWORD"
    fi

    if pg_isready -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" >/dev/null 2>&1; then
        log "INFO" "PostgreSQL connection successful"
        return 0
    else
        error_exit "PostgreSQL connection failed"
    fi
}

# Perform backup
perform_backup() {
    log "INFO" "Starting PostgreSQL backup: $BACKUP_NAME"

    # Use pg_dumpall for full backup including roles and databases
    if pg_dumpall -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" --clean --if-exists | gzip > "$BACKUP_FILE" 2>>"$LOG_FILE"; then
        log "INFO" "PostgreSQL backup completed successfully: $BACKUP_FILE"

        # Get backup size
        local size
        size=$(du -h "$BACKUP_FILE" | cut -f1)
        log "INFO" "Backup size: $size"

        return 0
    else
        error_exit "PostgreSQL backup failed"
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log "INFO" "Cleaning up old backups (keeping last $MAX_BACKUPS)"

    local backup_count
    backup_count=$(find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" | wc -l)

    if [[ $backup_count -le $MAX_BACKUPS ]]; then
        log "DEBUG" "Number of backups within limit: $backup_count <= $MAX_BACKUPS"
        return 0
    fi

    local to_remove=$((backup_count - MAX_BACKUPS))
    log "INFO" "Removing $to_remove old backups"

    find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" -printf '%T+ %p\n' | \
        sort | head -n "$to_remove" | while read -r line; do
        local backup_file
        backup_file=$(echo "$line" | cut -d' ' -f2-)
        log "INFO" "Removing old backup: $backup_file"
        rm -f "$backup_file"
    done

    log "INFO" "Cleanup completed"
}

# Verify backup integrity
verify_backup() {
    log "INFO" "Verifying backup integrity: $BACKUP_FILE"

    if [[ ! -f "$BACKUP_FILE" ]]; then
        error_exit "Backup file does not exist: $BACKUP_FILE"
    fi

    # Check if gzip file is valid
    if gzip -t "$BACKUP_FILE" 2>>"$LOG_FILE"; then
        log "INFO" "Backup file integrity verified"
        return 0
    else
        error_exit "Backup file is corrupted"
    fi
}

# Main function
main() {
    log "INFO" "=== Starting PostgreSQL Backup Script ==="

    # Create backup directory
    create_backup_dir

    # Test connection
    test_connection

    # Perform backup
    perform_backup

    # Verify backup
    verify_backup

    # Clean up old backups
    cleanup_old_backups

    log "INFO" "=== PostgreSQL Backup Script Completed Successfully ==="
    echo "Backup completed: $BACKUP_FILE"
}

# Run main function
main "$@"
