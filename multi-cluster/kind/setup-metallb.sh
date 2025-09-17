#!/bin/bash

# Script to set up MetalLB on all Kind clusters for cross-cluster networking
set -e

echo "🔧 Setting up MetalLB for Cross-Cluster Networking"
echo "================================================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

for cluster in "${CLUSTERS[@]}"; do
    echo ""
    echo "📦 Setting up MetalLB on cluster: $cluster"

    # Switch to the cluster context
    kubectl config use-context "kind-$cluster"

    # Create metallb-system namespace
    kubectl create namespace metallb-system --dry-run=client -o yaml | kubectl apply -f -

    # Apply MetalLB configuration
    kubectl apply -f metallb-config.yaml

    # Wait for MetalLB to be ready
    echo "⏳ Waiting for MetalLB to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/metallb-controller -n metallb-system
    kubectl wait --for=condition=ready --timeout=300s pod -l app=metallb,component=speaker -n metallb-system

    echo "✅ MetalLB setup completed on $cluster"
done

echo ""
echo "🎉 MetalLB setup completed on all clusters!"
echo ""
echo "📋 MetalLB provides LoadBalancer services with IPs in range: 172.18.255.1-172.18.255.250"
echo ""
echo "🔍 To verify MetalLB is working:"
echo "  kubectl get svc -A | grep LoadBalancer"
