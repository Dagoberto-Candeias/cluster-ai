#!/bin/bash

# Script to set up Redis Cluster across all clusters
set -e

echo "🔴 Setting up Redis Cross-Cluster"
echo "================================"

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Function to setup Redis on a cluster
setup_redis_cluster() {
    local cluster=$1

    echo ""
    echo "📦 Setting up Redis on cluster: $cluster"

    # Switch to cluster context
    kubectl config use-context "kind-$cluster"

    # Apply Redis configuration
    kubectl apply -f redis-cluster.yaml

    # Wait for Redis pods to be ready
    echo "⏳ Waiting for Redis pods to be ready..."
    kubectl wait --for=condition=ready --timeout=300s pod/redis-cluster-0
    kubectl wait --for=condition=ready --timeout=300s pod/redis-cluster-1
    kubectl wait --for=condition=ready --timeout=300s pod/redis-cluster-2
    kubectl wait --for=condition=ready --timeout=300s pod/redis-cluster-3
    kubectl wait --for=condition=ready --timeout=300s pod/redis-cluster-4
    kubectl wait --for=condition=ready --timeout=300s pod/redis-cluster-5

    # Wait for cluster initialization job to complete
    echo "⏳ Waiting for Redis cluster initialization..."
    kubectl wait --for=condition=complete --timeout=300s job/redis-cluster-init

    # Wait for LoadBalancer IP
    echo "⏳ Waiting for LoadBalancer IP..."
    local attempts=0
    local max_attempts=30
    while [ $attempts -lt $max_attempts ]; do
        local lb_ip=$(kubectl get svc redis-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$lb_ip" ]; then
            echo "✅ Redis LoadBalancer IP: $lb_ip"
            break
        fi
        sleep 5
        attempts=$((attempts + 1))
    done

    # Verify cluster status
    echo "🔍 Verifying Redis cluster status..."
    kubectl exec redis-cluster-0 -- redis-cli cluster info | grep -E "(cluster_state|cluster_slots_assigned|cluster_slots_ok)"

    echo "✅ Redis setup completed on $cluster"
}

# Setup Redis on all clusters
for cluster in "${CLUSTERS[@]}"; do
    setup_redis_cluster "$cluster"
done

echo ""
echo "🎉 Redis cross-cluster setup completed!"
echo ""
echo "📋 Redis Configuration:"
echo "  - 6-node cluster (3 masters + 3 replicas)"
echo "  - Cluster mode enabled"
echo "  - Automatic failover enabled"
echo "  - Memory limit: 256MB per node"
echo ""
echo "🔍 To check cluster status:"
echo "  kubectl exec -it redis-cluster-0 -- redis-cli cluster info"
echo "  kubectl exec -it redis-cluster-0 -- redis-cli cluster nodes"
echo ""
echo "🧪 Test Redis cluster:"
echo "  # Connect to cluster:"
echo "  kubectl exec -it redis-cluster-0 -- redis-cli -c"
echo ""
echo "  # Test operations:"
echo "  set test-key \"Hello Redis Cluster\""
echo "  get test-key"
echo "  cluster nodes"
echo "  cluster info"
echo ""
echo "📊 Monitor cluster:"
echo "  kubectl run redis-monitor --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h redis-cluster-0.redis-cluster cluster info"
echo ""
echo "🔄 Test failover:"
echo "  # Stop a master node:"
echo "  kubectl exec redis-cluster-0 -- redis-cli shutdown"
echo "  # Check if cluster elects new master:"
echo "  kubectl exec redis-cluster-1 -- redis-cli cluster nodes"
