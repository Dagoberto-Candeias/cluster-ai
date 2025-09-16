#!/bin/bash

# Cluster AI PostgreSQL Backup Script
# This script creates automated backups of PostgreSQL database

set -e

# Configuration
NAMESPACE="cluster-ai"
BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="cluster_ai_postgres_backup_${TIMESTAMP}"
RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Function to check if PostgreSQL pod is running
check_postgres_pod() {
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [ -z "$pod_name" ]; then
        error "PostgreSQL pod not found in namespace $NAMESPACE"
        return 1
    fi

    local pod_status
    pod_status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")

    if [ "$pod_status" != "Running" ]; then
        error "PostgreSQL pod is not running. Status: $pod_status"
        return 1
    fi

    echo "$pod_name"
    return 0
}

# Function to create PostgreSQL backup
create_postgres_backup() {
    local pod_name="$1"
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"

    log "Creating PostgreSQL backup: $backup_file"

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    # Execute pg_dump inside the PostgreSQL pod
    if kubectl exec -n "$NAMESPACE" "$pod_name" -- bash -c "
        pg_dump -U cluster_ai -d cluster_ai --no-password --clean --if-exists --create
    " | gzip > "$backup_file"; then
        log "PostgreSQL backup created successfully: $backup_file"

        # Calculate backup size
        local backup_size
        backup_size=$(du -h "$backup_file" | cut -f1)
        log "Backup size: $backup_size"

        return 0
    else
        error "Failed to create PostgreSQL backup"
        return 1
    fi
}

# Function to verify backup integrity
verify_backup() {
    local backup_file="$1"

    log "Verifying backup integrity: $backup_file"

    if [ ! -f "$backup_file" ]; then
        error "Backup file does not exist: $backup_file"
        return 1
    fi

    # Check if file is not empty
    if [ ! -s "$backup_file" ]; then
        error "Backup file is empty: $backup_file"
        return 1
    fi

    # Try to decompress and check SQL syntax
    if gunzip -c "$backup_file" | head -n 10 | grep -q "PostgreSQL database dump"; then
        log "Backup integrity check passed"
        return 0
    else
        error "Backup integrity check failed - not a valid PostgreSQL dump"
        return 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days"

    local old_backups
    old_backups=$(find "$BACKUP_DIR" -name "cluster_ai_postgres_backup_*.sql.gz" -mtime +"$RETENTION_DAYS" 2>/dev/null || true)

    if [ -n "$old_backups" ]; then
        echo "$old_backups" | while read -r backup; do
            log "Removing old backup: $backup"
            rm -f "$backup"
        done
        log "Cleanup completed"
    else
        log "No old backups to clean up"
    fi
}

# Function to send notification (placeholder for actual notification system)
send_notification() {
    local status="$1"
    local message="$2"

    log "Sending notification: $status - $message"

    # Here you would integrate with your notification system
    # Examples: Slack, email, PagerDuty, etc.

    # For now, just log the notification
    if [ "$status" = "success" ]; then
        log "✅ Backup completed successfully"
    else
        error "❌ Backup failed: $message"
    fi
}

# Main function
main() {
    log "Starting Cluster AI PostgreSQL backup process"

    # Check if running in Kubernetes environment
    if ! kubectl cluster-info >/dev/null 2>&1; then
        error "Not running in a Kubernetes environment or kubectl not configured"
        exit 1
    fi

    # Check PostgreSQL pod
    local postgres_pod
    if ! postgres_pod=$(check_postgres_pod); then
        send_notification "failure" "PostgreSQL pod not available"
        exit 1
    fi

    log "Found PostgreSQL pod: $postgres_pod"

    # Create backup
    if create_postgres_backup "$postgres_pod"; then
        # Verify backup
        if verify_backup "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"; then
            log "Backup verification successful"

            # Cleanup old backups
            cleanup_old_backups

            # Send success notification
            send_notification "success" "PostgreSQL backup completed successfully"

            log "✅ PostgreSQL backup process completed successfully"
            exit 0
        else
            send_notification "failure" "Backup verification failed"
            exit 1
        fi
    else
        send_notification "failure" "Backup creation failed"
        exit 1
    fi
}

# Run main function
main "$@"
