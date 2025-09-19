#!/bin/bash

# Cluster AI Redis Backup Script
# This script creates automated backups of Redis data

set -e

# Configuration
NAMESPACE="cluster-ai"
BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="cluster_ai_redis_backup_${TIMESTAMP}"
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

# Function to check if Redis pod is running
check_redis_pod() {
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [ -z "$pod_name" ]; then
        error "Redis pod not found in namespace $NAMESPACE"
        return 1
    fi

    local pod_status
    pod_status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")

    if [ "$pod_status" != "Running" ]; then
        error "Redis pod is not running. Status: $pod_status"
        return 1
    fi

    echo "$pod_name"
    return 0
}

# Function to create Redis backup using BGSAVE
create_redis_backup() {
    local pod_name="$1"
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}.rdb"

    log "Creating Redis backup: $backup_file"

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    # Trigger BGSAVE in Redis
    log "Triggering BGSAVE in Redis..."
    if ! kubectl exec -n "$NAMESPACE" "$pod_name" -- redis-cli BGSAVE; then
        error "Failed to trigger BGSAVE in Redis"
        return 1
    fi

    # Wait for BGSAVE to complete
    log "Waiting for BGSAVE to complete..."
    local max_wait=300  # 5 minutes timeout
    local wait_count=0

    while [ $wait_count -lt $max_wait ]; do
        local bgsave_status
        bgsave_status=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- redis-cli INFO persistence | grep -A 5 "Persistence" | grep "rdb_bgsave_in_progress" | cut -d: -f2 | tr -d '\r')

        if [ "$bgsave_status" = "0" ]; then
            log "BGSAVE completed successfully"
            break
        fi

        sleep 5
        wait_count=$((wait_count + 5))

        if [ $wait_count -ge $max_wait ]; then
            error "BGSAVE did not complete within timeout period"
            return 1
        fi
    done

    # Copy the RDB file from Redis container
    log "Copying RDB file from Redis container..."
    if kubectl cp "$NAMESPACE/$pod_name:/data/dump.rdb" "$backup_file" 2>/dev/null; then
        log "Redis backup created successfully: $backup_file"

        # Calculate backup size
        local backup_size
        backup_size=$(du -h "$backup_file" | cut -f1)
        log "Backup size: $backup_size"

        return 0
    else
        error "Failed to copy RDB file from Redis container"
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

    # Check Redis RDB file magic number (REDIS)
    if head -c 5 "$backup_file" | grep -q "REDIS"; then
        log "Backup appears to be a valid Redis RDB file"
        return 0
    else
        error "Backup does not appear to be a valid Redis RDB file"
        return 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days"

    local old_backups
    old_backups=$(find "$BACKUP_DIR" -name "cluster_ai_redis_backup_*.rdb" -mtime +"$RETENTION_DAYS" 2>/dev/null || true)

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
    log "Starting Cluster AI Redis backup process"

    # Check if running in Kubernetes environment
    if ! kubectl cluster-info >/dev/null 2>&1; then
        error "Not running in a Kubernetes environment or kubectl not configured"
        exit 1
    fi

    # Check Redis pod
    local redis_pod
    if ! redis_pod=$(check_redis_pod); then
        send_notification "failure" "Redis pod not available"
        exit 1
    fi

    log "Found Redis pod: $redis_pod"

    # Create backup
    if create_redis_backup "$redis_pod"; then
        # Verify backup
        if verify_backup "${BACKUP_DIR}/${BACKUP_NAME}.rdb"; then
            log "Backup verification successful"

            # Cleanup old backups
            cleanup_old_backups

            # Send success notification
            send_notification "success" "Redis backup completed successfully"

            log "✅ Redis backup process completed successfully"
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
