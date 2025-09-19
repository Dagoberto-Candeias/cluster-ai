#!/bin/bash

# Script to create multiple Kind clusters for multi-cloud simulation
set -e

echo "🚀 Creating Multi-Cluster Local Environment"
echo "=========================================="

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Kind is not installed. Please install Kind first:"
    echo "   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
    echo "   chmod +x ./kind && sudo mv ./kind /usr/local/bin/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Function to create cluster
create_cluster() {
    local cluster_name=$1
    local config_file=$2

    echo "📦 Creating cluster: $cluster_name"
    if kind get clusters | grep -q "^${cluster_name}$"; then
        echo "⚠️  Cluster $cluster_name already exists. Skipping..."
    else
        kind create cluster --config "$config_file" --name "$cluster_name"
        echo "✅ Cluster $cluster_name created successfully"
    fi
}

# Create AWS-like cluster
create_cluster "aws-cluster" "aws-cluster.yaml"

# Create GCP-like cluster
create_cluster "gcp-cluster" "gcp-cluster.yaml"

# Create Azure-like cluster
create_cluster "azure-cluster" "azure-cluster.yaml"

echo ""
echo "🎉 All clusters created successfully!"
echo ""
echo "📋 Cluster Information:"
echo "  AWS Cluster:   kind get kubeconfig --name aws-cluster"
echo "  GCP Cluster:   kind get kubeconfig --name gcp-cluster"
echo "  Azure Cluster: kind get kubeconfig --name azure-cluster"
echo ""
echo "🔄 To switch between clusters:"
echo "  kubectl config use-context kind-aws-cluster"
echo "  kubectl config use-context kind-gcp-cluster"
echo "  kubectl config use-context kind-azure-cluster"
echo ""
echo "🧹 To clean up: ./delete-clusters.sh"
