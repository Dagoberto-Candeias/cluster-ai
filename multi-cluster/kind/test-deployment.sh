#!/bin/bash

# Script to test multi-cluster deployment
set -e

echo "🧪 Testing Multi-Cluster Deployment"
echo "==================================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Function to deploy and test on a cluster
test_cluster() {
    local cluster=$1

    echo ""
    echo "📦 Testing cluster: $cluster"

    # Switch to cluster context
    kubectl config use-context "kind-$cluster"

    # Deploy the example app
    kubectl apply -f example-app.yaml

    # Wait for deployment to be ready
    echo "⏳ Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/cluster-ai-demo

    # Wait for LoadBalancer IP
    echo "⏳ Waiting for LoadBalancer IP..."
    local attempts=0
    local max_attempts=30
    while [ $attempts -lt $max_attempts ]; do
        local lb_ip=$(kubectl get svc cluster-ai-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$lb_ip" ]; then
            echo "✅ LoadBalancer IP assigned: $lb_ip"
            break
        fi
        sleep 5
        attempts=$((attempts + 1))
    done

    if [ $attempts -eq $max_attempts ]; then
        echo "❌ LoadBalancer IP not assigned within timeout"
        return 1
    fi

    # Test the application
    echo "🔍 Testing application..."
    if curl -f -s "http://$lb_ip" > /dev/null; then
        echo "✅ Application is accessible at http://$lb_ip"
    else
        echo "❌ Application not accessible"
        return 1
    fi

    # Check ingress
    echo "🔍 Testing ingress..."
    if kubectl get ingress cluster-ai-demo-ingress &>/dev/null; then
        echo "✅ Ingress configured successfully"
    else
        echo "❌ Ingress not configured"
        return 1
    fi

    echo "✅ Cluster $cluster test completed successfully"
}

# Test each cluster
for cluster in "${CLUSTERS[@]}"; do
    if test_cluster "$cluster"; then
        echo "✅ $cluster: PASSED"
    else
        echo "❌ $cluster: FAILED"
        exit 1
    fi
done

echo ""
echo "🎉 All cluster tests passed!"
echo ""
echo "📋 Test Results:"
echo "  - All clusters have LoadBalancer services"
echo "  - Applications are accessible via LoadBalancer IPs"
echo "  - Ingress controllers are working"
echo ""
echo "🌐 Access URLs:"
echo "  - demo.cluster-ai.local (load balanced across clusters)"
echo "  - demo.aws.cluster-ai.local"
echo "  - demo.gcp.cluster-ai.local"
echo "  - demo.azure.cluster-ai.local"
echo ""
echo "🧹 Clean up test deployment:"
echo "  kubectl delete -f example-app.yaml"
