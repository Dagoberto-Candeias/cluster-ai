# Cluster AI - Docker Management Makefile

.PHONY: help build up down restart logs clean dev prod backup restore health status \
	venv venv-dev fix-perms status-summary status-quick lint-shell

# Default target
help: ## Show this help message
	@echo "Cluster AI - Docker Management Commands"
	@echo ""
{{ ... }}
	@echo "  make restore          Restore from backup"
	@echo "  make venv             Create/Update local Python venv (.venv)"
	@echo "  make venv-dev         Create/Update venv and install dev deps"
	@echo "  make fix-perms        Ensure scripts are executable"
	@echo "  make status-summary   Show system/services/workers summary"
	@echo "  make status-quick     Quick health check"
	@echo "  make lint-shell       Run ShellCheck on shell scripts"
	@echo ""
	@echo "Quick Commands:"
	@echo "  make up               Start development environment"
	@echo "  make down             Stop all environments"
	@echo "  make restart          Restart all environments"
{{ ... }}
# Status summaries
status-summary: ## Show system/services/workers summary
	@bash scripts/utils/system_status_dashboard.sh || true

status-quick: ## Quick health check
	@bash scripts/utils/health_check.sh status || true

# Lint shell scripts with ShellCheck
lint-shell: ## Run ShellCheck on shell scripts
	@echo "Running ShellCheck..."
	@find scripts -type f -name '*.sh' -not -path '*/tests/bash/libs/*' -print0 | xargs -0 -I {} sh -c 'shellcheck -x "{}" || true'
	@echo "ShellCheck completed."

clean: ## Remove all containers and volumes
	@echo "⚠️  This will remove all containers, volumes, and data!"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose -f docker-compose.prod.yml down -v --remove-orphans; \
		docker system prune -f; \
		echo "✅ Cleanup completed"; \
	else \
		echo "❌ Cleanup cancelled"; \
	fi

backup: ## Create backup of data
	@echo "Creating backup..."
	@mkdir -p backups
	@BACKUP_FILE=backups/cluster_ai_backup_$(date +%Y%m%d_%H%M%S).tar.gz; \
	docker run --rm -v $(pwd):/backup -v $(pwd)/data:/data alpine tar czf /backup/$$BACKUP_FILE -C / data; \
	echo "✅ Backup created: $$BACKUP_FILE"

backup-postgres: ## Run PostgreSQL backup script in Kubernetes
	kubectl create namespace cluster-ai || true
	kubectl apply -f backup/config/postgres-backup-cronjob.yaml

backup-redis: ## Run Redis backup script in Kubernetes
	kubectl create namespace cluster-ai || true
	kubectl apply -f backup/config/redis-backup-cronjob.yaml

# Performance Commands
redis-cluster-deploy: ## Deploy Redis Cluster for high availability
	kubectl create namespace cluster-ai || true
	kubectl apply -f performance/redis-cluster/redis-cluster-statefulset.yaml
	@echo "Waiting for Redis nodes to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis-cluster -n cluster-ai --timeout=300s
	kubectl apply -f performance/redis-cluster/redis-cluster-init-job.yaml

pgbouncer-deploy: ## Deploy PgBouncer for connection pooling
	kubectl create namespace cluster-ai || true
	kubectl apply -f performance/database/pgbouncer-config.yaml

performance-monitoring-deploy: ## Deploy APM and distributed tracing
	kubectl create namespace cluster-ai || true
	kubectl apply -f performance/monitoring/apm-config.yaml

cdn-config-update: ## Update Nginx with CDN optimizations
	kubectl create configmap cluster-ai-nginx-cdn-config \
		--from-file=performance/cdn/nginx-cdn-config.conf \
		-n cluster-ai --dry-run=client -o yaml | kubectl apply -f -

docker-build-optimized: ## Build optimized Docker images
	docker build -f performance/docker/Dockerfile.optimized \
		-t cluster-ai-backend:optimized ./web-dashboard/backend
	docker build -f performance/docker/Dockerfile.optimized \
		-t cluster-ai-frontend:optimized ./web-dashboard

performance-test: ## Run performance tests
	@echo "Running performance tests..."
	ab -n 1000 -c 10 http://localhost:3000/

# AI/ML Commands
tensorflow-serving-deploy: ## Deploy TensorFlow Serving
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/tensorflow-serving/tensorflow-serving-deployment.yaml

torchserve-deploy: ## Deploy TorchServe
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/torchserve/torchserve-deployment.yaml

gpu-optimization-deploy: ## Deploy GPU optimization components
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/gpu/gpu-optimization.yaml

model-cache-deploy: ## Deploy model caching system
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/model-cache/model-cache-deployment.yaml

inference-optimization-deploy: ## Deploy inference optimization stack
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/inference/inference-optimization.yaml

ml-monitoring-deploy: ## Deploy ML monitoring and observability
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/monitoring/ml-monitoring-config.yaml

model-registry-deploy: ## Deploy model registry system
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/model-registry/model-registry-deployment.yaml

model-backup-deploy: ## Deploy model backup system
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/backup/model-backup-deployment.yaml

ml-autoscaling-deploy: ## Deploy ML-specific autoscaling
	kubectl create namespace cluster-ai || true
	kubectl apply -f ai-ml/autoscaling/ml-autoscaling.yaml

	@echo "Performance test completed"

restore: ## Restore from backup
	@echo "Available backups:"
	@ls -la backups/ 2>/dev/null || echo "No backups found"
	@echo "To restore, run: make restore BACKUP_FILE=backups/your_backup_file.tar.gz"

# Database Commands
db-migrate: ## Run database migrations
	docker-compose exec backend alembic upgrade head

db-reset: ## Reset database (WARNING: This will delete all data)
	@echo "⚠️  This will delete all database data!"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose exec postgres dropdb -U cluster_ai cluster_ai; \
		docker-compose exec postgres createdb -U cluster_ai cluster_ai; \
		make db-migrate; \
		echo "✅ Database reset completed"; \
	else \
		echo "❌ Database reset cancelled"; \
	fi

# Monitoring Commands
monitoring-up: ## Start only monitoring stack
	docker-compose up -d prometheus grafana elasticsearch logstash kibana

monitoring-down: ## Stop monitoring stack
	docker-compose down prometheus grafana elasticsearch logstash kibana

# Testing Commands
test: ## Run tests
	docker-compose exec backend pytest

test-frontend: ## Run frontend tests
	docker-compose exec frontend npm test

# Security Commands
security-scan: ## Run security scan on containers
	docker-compose exec backend trivy image cluster-ai-backend:latest || echo "Trivy not installed"
	docker-compose exec frontend trivy image cluster-ai-frontend:latest || echo "Trivy not installed"

# Performance Commands
perf-test: ## Run performance tests
	@echo "Running performance tests..."
	docker run --rm -v $(pwd)/tests:/tests --network cluster-ai-network \
		postman/newman run /tests/cluster_ai_postman_collection.json \
		--environment /tests/cluster_ai_environment.json

# Help target
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
