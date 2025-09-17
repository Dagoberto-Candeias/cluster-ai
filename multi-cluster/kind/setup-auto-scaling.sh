#!/bin/bash

# Script to set up auto-scaling for local multi-cluster
set -e

echo "📈 Setting up Auto-Scaling"
echo "=========================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Function to setup auto-scaling on a cluster
setup_auto_scaling() {
    local cluster=$1

    echo ""
    echo "📦 Setting up auto-scaling on cluster: $cluster"

    # Switch to cluster context
    kubectl config use-context "kind-$cluster"

    # Apply auto-scaling configuration
    kubectl apply -f auto-scaling.yaml

    # Wait for deployments to be ready
    echo "⏳ Waiting for auto-scaling components to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/predictive-scaler

    # Verify auto-scaling setup
    echo "🔍 Verifying auto-scaling setup..."
    kubectl get hpa
    kubectl get configmap autoscaling-config
    kubectl get configmap predictive-scaling-config
    kubectl get cronjob cluster-autoscaler-check
    kubectl get pods -l app=predictive-scaler

    echo "✅ Auto-scaling setup completed on $cluster"
}

# Setup auto-scaling on all clusters
for cluster in "${CLUSTERS[@]}"; do
    setup_auto_scaling "$cluster"
done

echo ""
echo "🎉 Auto-scaling setup completed!"
echo ""
echo "📋 Auto-Scaling Configuration:"
echo "  - HPA: CPU 70%, Memory 80%"
echo "  - Min replicas: 1"
echo "  - Max replicas: 10"
echo "  - Predictive scaling: Enabled"
echo "  - Check interval: Every 5 minutes"
echo ""
echo "🔍 To check auto-scaling status:"
echo "  kubectl get hpa"
echo "  kubectl describe hpa cluster-ai-demo-hpa"
echo "  kubectl get pods -l app=predictive-scaler"
echo ""
echo "📊 To monitor scaling events:"
echo "  kubectl get events --sort-by=.metadata.creationTimestamp"
echo "  kubectl logs -l app=predictive-scaler"
echo ""
echo "🧪 Test auto-scaling:"
echo "  # Generate load to trigger scaling:"
echo "  kubectl run load-generator --image=busybox --rm -it --restart=Never -- sh"
echo "  while true; do wget -q -O- http://cluster-ai-demo-service; done"
echo ""
echo "  # Check scaling:"
echo "  kubectl get hpa"
echo "  kubectl get pods -l app=cluster-ai-demo"
echo ""
echo "  # Stop load generation:"
echo "  kubectl delete pod load-generator"
echo ""
echo "🔮 Test predictive scaling:"
echo "  kubectl logs -f -l app=predictive-scaler"
echo ""
echo "📈 Manual scaling:"
echo "  kubectl scale deployment cluster-ai-demo --replicas=3"
echo "  kubectl autoscale deployment cluster-ai-demo --cpu-percent=70 --min=1 --max=10"
echo ""
echo "📊 Monitor resource usage:"
echo "  kubectl top pods"
echo "  kubectl top nodes"
echo ""
echo "⚙️  Configure custom metrics:"
echo "  # For custom metrics scaling:"
echo "  kubectl apply -f custom-metrics.yaml"
echo "  kubectl autoscale deployment cluster-ai-demo --cpu-percent=70 --min=1 --max=10"
