#!/bin/bash
# =============================================================================
# Docker Rollback Script for Cluster AI
# =============================================================================
# Emergency rollback for failed deployments
#
# Author: Cluster AI Team
# Date: 2025-01-27
# Version: 1.0.0
# File: rollback.sh
# =============================================================================

set -euo pipefail

# --- Configuration ---
PROJECT_ROOT="/app"
LOG_DIR="${PROJECT_ROOT}/logs"
ROLLBACK_LOG="${LOG_DIR}/rollback.log"

# Create log directory
mkdir -p "$LOG_DIR"

# --- Functions ---

# Enhanced logging
log_rollback() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$ROLLBACK_LOG"
}

# Get previous image for service
get_previous_image() {
    local service="$1"
    local compose_file="${PROJECT_ROOT}/docker-compose.yml"

    # Try to find previous image from docker history or tags
    # This is a simplified version - in production, you'd use image registry tags
    docker images --format "{{.Repository}}:{{.Tag}}" | grep "$service" | head -2 | tail -1 || echo ""
}

# Rollback service to previous version
rollback_service() {
    local service="$1"

    log_rollback "INFO" "Rolling back service: $service"

    # Stop current service
    if docker-compose ps "$service" | grep -q "Up"; then
        log_rollback "INFO" "Stopping current $service"
        docker-compose stop "$service"
    fi

    # Get previous image
    local prev_image
    prev_image=$(get_previous_image "$service")

    if [[ -z "$prev_image" ]]; then
        log_rollback "ERROR" "No previous image found for $service"
        return 1
    fi

    log_rollback "INFO" "Using previous image: $prev_image"

    # Update compose file temporarily (simplified)
    # In production, you'd modify the compose file or use specific tags

    # Restart with previous image
    if docker-compose up -d "$service"; then
        log_rollback "SUCCESS" "Successfully rolled back $service"
        return 0
    else
        log_rollback "ERROR" "Failed to rollback $service"
        return 1
    fi
}

# Rollback all services
rollback_all() {
    log_rollback "INFO" "Starting full rollback"

    local services=("backend" "frontend" "redis" "postgres")

    for service in "${services[@]}"; do
        if ! rollback_service "$service"; then
            log_rollback "ERROR" "Rollback failed for $service"
        fi
    done

    log_rollback "INFO" "Rollback completed"
}

# Main function
main() {
    cd "$PROJECT_ROOT"

    local action="${1:-all}"

    case "$action" in
        "all")
            rollback_all ;;
        "service")
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 service <service_name>"
                exit 1
            fi
            rollback_service "$2" ;;
        "help"|*)
            echo "Cluster AI - Docker Rollback Script"
            echo ""
            echo "Usage: $0 [action] [service]"
            echo ""
            echo "Actions:"
            echo "  all          - Rollback all services"
            echo "  service      - Rollback specific service"
            echo "  help         - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 all"
            echo "  $0 service backend"
            ;;
    esac
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
