#!/bin/bash

# Script to set up storage replication across clusters
set -e

echo "💾 Setting up Storage Replication"
echo "================================"

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Function to setup storage replication on a cluster
setup_storage_replication() {
    local cluster=$1

    echo ""
    echo "📦 Setting up storage replication on cluster: $cluster"

    # Switch to cluster context
    kubectl config use-context "kind-$cluster"

    # Apply storage replication configuration
    kubectl apply -f storage-replication.yaml

    # Wait for deployment to be ready
    echo "⏳ Waiting for storage replicator to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/storage-replicator

    # Verify storage replication setup
    echo "🔍 Verifying storage replication setup..."
    kubectl get pvc shared-data-pvc
    kubectl get pods -l app=storage-replicator
    kubectl get cronjob storage-backup-job

    echo "✅ Storage replication setup completed on $cluster"
}

# Setup storage replication on all clusters
for cluster in "${CLUSTERS[@]}"; do
    setup_storage_replication "$cluster"
done

echo ""
echo "🎉 Storage replication setup completed!"
echo ""
echo "📋 Storage Configuration:"
echo "  - PVC: shared-data-pvc (10Gi)"
echo "  - Replication: Cross-cluster sync every 30s"
echo "  - Backup: Automated every 6 hours"
echo "  - Storage Class: local-storage"
echo ""
echo "🔍 To check storage status:"
echo "  kubectl get pvc shared-data-pvc"
echo "  kubectl get pods -l app=storage-replicator"
echo "  kubectl logs -l app=storage-replicator"
echo ""
echo "📦 To check backup jobs:"
echo "  kubectl get cronjob storage-backup-job"
echo "  kubectl get jobs"
echo ""
echo "🧪 Test storage replication:"
echo "  # Write test data:"
echo "  kubectl exec -it $(kubectl get pods -l app=storage-replicator -o jsonpath='{.items[0].metadata.name}') -- sh"
echo "  echo 'test data' > /data/test.txt"
echo ""
echo "  # Check data sync:"
echo "  kubectl exec -it $(kubectl get pods -l app=storage-replicator -o jsonpath='{.items[0].metadata.name}') -- cat /data/test.txt"
echo ""
echo "📊 Monitor storage:"
echo "  kubectl exec -it $(kubectl get pods -l app=storage-replicator -o jsonpath='{.items[0].metadata.name}') -- df -h /data"
