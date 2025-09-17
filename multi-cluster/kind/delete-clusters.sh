#!/bin/bash

# Script to delete all Kind clusters
set -e

echo "🧹 Deleting Multi-Cluster Local Environment"
echo "==========================================="

# Function to delete cluster
delete_cluster() {
    local cluster_name=$1

    echo "🗑️  Deleting cluster: $cluster_name"
    if kind get clusters | grep -q "^${cluster_name}$"; then
        kind delete cluster --name "$cluster_name"
        echo "✅ Cluster $cluster_name deleted successfully"
    else
        echo "⚠️  Cluster $cluster_name does not exist. Skipping..."
    fi
}

# Delete clusters
delete_cluster "aws-cluster"
delete_cluster "gcp-cluster"
delete_cluster "azure-cluster"

echo ""
echo "🎉 All clusters deleted successfully!"
