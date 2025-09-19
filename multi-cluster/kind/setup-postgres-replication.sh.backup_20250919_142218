#!/bin/bash

# Script to set up PostgreSQL replication across all clusters
set -e

echo "🐘 Setting up PostgreSQL Cross-Cluster Replication"
echo "================================================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Function to setup PostgreSQL on a cluster
setup_postgres_cluster() {
    local cluster=$1
    local is_primary=${2:-false}

    echo ""
    echo "📦 Setting up PostgreSQL on cluster: $cluster"

    # Switch to cluster context
    kubectl config use-context "kind-$cluster"

    # Apply PostgreSQL configuration
    kubectl apply -f postgres-replication.yaml

    # Wait for PostgreSQL to be ready
    if [ "$is_primary" = true ]; then
        echo "⏳ Waiting for PostgreSQL primary to be ready..."
        kubectl wait --for=condition=ready --timeout=300s pod/postgres-primary-0
    else
        echo "⏳ Waiting for PostgreSQL replicas to be ready..."
        kubectl wait --for=condition=ready --timeout=300s pod/postgres-replica-0
        kubectl wait --for=condition=ready --timeout=300s pod/postgres-replica-1
    fi

    # Wait for LoadBalancer IP if primary
    if [ "$is_primary" = true ]; then
        echo "⏳ Waiting for LoadBalancer IP..."
        local attempts=0
        local max_attempts=30
        while [ $attempts -lt $max_attempts ]; do
            local lb_ip=$(kubectl get svc postgres-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            if [ -n "$lb_ip" ]; then
                echo "✅ PostgreSQL LoadBalancer IP: $lb_ip"
                break
            fi
            sleep 5
            attempts=$((attempts + 1))
        done
    fi

    echo "✅ PostgreSQL setup completed on $cluster"
}

# Setup primary on AWS cluster
setup_postgres_cluster "aws-cluster" true

# Setup replicas on GCP and Azure clusters
setup_postgres_cluster "gcp-cluster" false
setup_postgres_cluster "azure-cluster" false

echo ""
echo "🎉 PostgreSQL cross-cluster replication setup completed!"
echo ""
echo "📋 Replication Configuration:"
echo "  - Primary: aws-cluster (postgres-primary-0)"
echo "  - Replicas: gcp-cluster, azure-cluster (postgres-replica-0, postgres-replica-1)"
echo "  - Synchronous replication enabled"
echo "  - WAL level: replica"
echo ""
echo "🔍 To check replication status:"
echo "  kubectl exec -it postgres-primary-0 -- /bin/bash"
echo "  kubectl exec -it postgres-replica-0 -- /bin/bash"
echo ""
echo "🧪 Test replication:"
echo "  # On primary:"
echo "  kubectl exec -it postgres-primary-0 -- psql -U cluster_ai -d cluster_ai -c \"CREATE TABLE test (id SERIAL PRIMARY KEY, data TEXT);\""
echo "  kubectl exec -it postgres-primary-0 -- psql -U cluster_ai -d cluster_ai -c \"INSERT INTO test (data) VALUES ('test data');\""
echo ""
echo "  # On replica:"
echo "  kubectl exec -it postgres-replica-0 -- psql -U cluster_ai -d cluster_ai -c \"SELECT * FROM test;\""
echo ""
echo "📊 Monitor replication:"
echo "  kubectl run postgres-monitor --image=postgres:15-alpine --rm -it --restart=Never -- /bin/bash"
echo "  # Inside container:"
echo "  PGPASSWORD=postgres psql -h postgres-primary-0.postgres-primary -U postgres -d cluster_ai -c \"SELECT * FROM pg_stat_replication;\""
