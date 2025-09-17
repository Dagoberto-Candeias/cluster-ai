#!/bin/bash

# Script to set up disaster recovery procedures locally
set -e

echo "🛡️  Setting up Disaster Recovery"
echo "==============================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Function to setup disaster recovery on a cluster
setup_disaster_recovery() {
    local cluster=$1

    echo ""
    echo "📦 Setting up disaster recovery on cluster: $cluster"

    # Switch to cluster context
    kubectl config use-context "kind-$cluster"

    # Apply disaster recovery configuration
    kubectl apply -f disaster-recovery.yaml

    # Wait for deployment to be ready
    echo "⏳ Waiting for disaster recovery monitor to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/disaster-recovery-monitor

    # Verify disaster recovery setup
    echo "🔍 Verifying disaster recovery setup..."
    kubectl get configmap disaster-recovery-config
    kubectl get configmap failover-scripts
    kubectl get cronjob disaster-recovery-backup
    kubectl get pods -l app=disaster-recovery-monitor

    echo "✅ Disaster recovery setup completed on $cluster"
}

# Setup disaster recovery on all clusters
for cluster in "${CLUSTERS[@]}"; do
    setup_disaster_recovery "$cluster"
done

echo ""
echo "🎉 Disaster recovery setup completed!"
echo ""
echo "📋 Disaster Recovery Configuration:"
echo "  - Automated backups: Every hour"
echo "  - Retention period: 7 days"
echo "  - Auto-failover: Enabled"
echo "  - Recovery time objective: 5 minutes"
echo ""
echo "🔍 To check disaster recovery status:"
echo "  kubectl get cronjob disaster-recovery-backup"
echo "  kubectl get pods -l app=disaster-recovery-monitor"
echo "  kubectl logs -l app=disaster-recovery-monitor"
echo ""
echo "📦 To check backups:"
echo "  kubectl get jobs"
echo "  ls -la /tmp/disaster-recovery-backups/"
echo ""
echo "🧪 Test disaster recovery:"
echo "  # Simulate cluster failure:"
echo "  kind delete cluster aws-cluster"
echo ""
echo "  # Check failover:"
echo "  kubectl config use-context kind-gcp-cluster"
echo "  kubectl get pods -l app=disaster-recovery-monitor"
echo ""
echo "  # Manual failover:"
echo "  kubectl exec -it $(kubectl get pods -l app=disaster-recovery-monitor -o jsonpath='{.items[0].metadata.name}') -- /scripts/failover.sh"
echo ""
echo "🔄 Test recovery:"
echo "  # Recreate failed cluster:"
echo "  kind create cluster --name aws-cluster --config aws-cluster.yaml"
echo ""
echo "  # Run recovery:"
echo "  kubectl exec -it $(kubectl get pods -l app=disaster-recovery-monitor -o jsonpath='{.items[0].metadata.name}') -- /scripts/recovery.sh"
echo ""
echo "📊 Monitor disaster recovery:"
echo "  kubectl logs -f -l app=disaster-recovery-monitor"
echo ""
echo "📋 Backup locations:"
echo "  - AWS: /tmp/disaster-recovery-backups/aws/"
echo "  - GCP: /tmp/disaster-recovery-backups/gcp/"
echo "  - Azure: /tmp/disaster-recovery-backups/azure/"
