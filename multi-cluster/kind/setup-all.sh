#!/bin/bash

# Master script to set up complete multi-cluster environment
set -e

echo "🚀 Setting up Complete Multi-Cluster Environment"
echo "==============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Create clusters
echo ""
echo "📦 Step 1: Creating Kind clusters..."
"$SCRIPT_DIR/create-clusters.sh"

# Step 2: Setup MetalLB
echo ""
echo "🔧 Step 2: Setting up MetalLB networking..."
"$SCRIPT_DIR/setup-metallb.sh"

# Step 3: Setup Ingress
echo ""
echo "🌐 Step 3: Setting up NGINX Ingress Controller..."
"$SCRIPT_DIR/setup-ingress.sh"

# Step 4: Setup DNS
echo ""
echo "🗂️  Step 4: Setting up DNS with failover..."
"$SCRIPT_DIR/setup-dns.sh"

# Step 5: Setup PostgreSQL replication
echo ""
echo "🐘 Step 5: Setting up PostgreSQL cross-cluster replication..."
"$SCRIPT_DIR/setup-postgres-replication.sh"

# Step 6: Setup Redis Cluster
echo ""
echo "🔴 Step 6: Setting up Redis cross-cluster..."
"$SCRIPT_DIR/setup-redis-cluster.sh"

echo ""
echo "🎉 Multi-Cluster Environment Setup Complete!"
echo ""
echo "📋 Environment Summary:"
echo "  - Clusters: aws-cluster, gcp-cluster, azure-cluster"
echo "  - Networking: MetalLB (172.18.255.1-172.18.255.250)"
echo "  - Ingress: NGINX Ingress Controller"
echo "  - DNS: CoreDNS with cluster-ai.local domain"
echo "  - Database: PostgreSQL with streaming replication"
echo "  - Cache: Redis Cluster (6 nodes, 3 masters + 3 replicas)"
echo ""
echo "🔄 Switch between clusters:"
echo "  kubectl config use-context kind-aws-cluster"
echo "  kubectl config use-context kind-gcp-cluster"
echo "  kubectl config use-context kind-azure-cluster"
echo ""
echo "🧹 Clean up with: ./delete-clusters.sh"
echo ""
echo "📚 Next steps:"
echo "  - Deploy applications to test multi-cluster setup"
echo "  - Configure cross-cluster service discovery"
echo "  - Set up monitoring and logging"
echo "  - Test failover scenarios"
