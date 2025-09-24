#!/bin/bash
# =============================================================================
# Cluster AI Redis Backup Script
# =============================================================================
# This script creates automated backups of Redis data
#
# Author: Cluster AI Team
# Date: 2025-01-20
# Version: 1.0.0
# File: redis-backup.sh
# =============================================================================

set -euo pipefail

# --- Configuration ---
BACKUP_DIR="${BACKUP_DIR:-/backup}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="redis_backup_${TIMESTAMP}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.rdb"
LOG_FILE="${BACKUP_DIR}/redis_backup.log"

# Redis connection settings
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

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

# Test Redis connection
test_connection() {
    log "INFO" "Testing Redis connection..."

    local auth_args=()
    if [[ -n "$REDIS_PASSWORD" ]]; then
        auth_args+=("-a" "$REDIS_PASSWORD")
    fi

    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" "${auth_args[@]}" ping | grep -q PONG; then
        log "INFO" "Redis connection successful"
        return 0
    else
        error_exit "Redis connection failed"
    fi
}

# Perform backup
perform_backup() {
    log "INFO" "Starting Redis backup: $BACKUP_NAME"

    local auth_args=()
    if [[ -n "$REDIS_PASSWORD" ]]; then
        auth_args+=("-a" "$REDIS_PASSWORD")
    fi

    # Trigger a synchronous save to disk
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" "${auth_args[@]}" save; then
        log "INFO" "Redis save command executed"
    else
        error_exit "Failed to execute Redis save command"
    fi

    # Locate Redis dump file (default: dump.rdb)
    local redis_dump_file="/data/dump.rdb"
    if [[ ! -f "$redis_dump_file" ]]; then
        error_exit "Redis dump file not found at $redis_dump_file"
    fi

    # Copy dump file to backup location
    if cp "$redis_dump_file" "$BACKUP_FILE"; then
        log "INFO" "Redis dump file copied to backup location: $BACKUP_FILE"
    else
        error_exit "Failed to copy Redis dump file"
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log "INFO" "Cleaning up old backups (keeping last $MAX_BACKUPS)"

    local backup_count
    backup_count=$(find "$BACKUP_DIR" -name "redis_backup_*.rdb" | wc -l)

    if [[ $backup_count -le $MAX_BACKUPS ]]; then
        log "DEBUG" "Number of backups within limit: $backup_count <= $MAX_BACKUPS"
        return 0
    fi

    local to_remove=$((backup_count - MAX_BACKUPS))
    log "INFO" "Removing $to_remove old backups"

    find "$BACKUP_DIR" -name "redis_backup_*.rdb" -printf '%T+ %p\n' | \
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

    # Check if file is non-empty
    if [[ -s "$BACKUP_FILE" ]]; then
        log "INFO" "Backup file integrity verified"
        return 0
    else
        error_exit "Backup file is empty or corrupted"
    fi
}

# Main function
main() {
    log "INFO" "=== Starting Redis Backup Script ==="

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

    log "INFO" "=== Redis Backup Script Completed Successfully ==="
    echo "Backup completed: $BACKUP_FILE"
}

# Run main function
main "$@"
