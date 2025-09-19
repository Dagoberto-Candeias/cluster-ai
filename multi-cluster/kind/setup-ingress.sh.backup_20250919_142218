#!/bin/bash

# Script to set up NGINX Ingress Controller on all Kind clusters
set -e

echo "🌐 Setting up NGINX Ingress Controller"
echo "====================================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

for cluster in "${CLUSTERS[@]}"; do
    echo ""
    echo "📦 Setting up Ingress on cluster: $cluster"

    # Switch to the cluster context
    kubectl config use-context "kind-$cluster"

    # Add NGINX Ingress Helm repo
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
    helm repo update

    # Install NGINX Ingress Controller
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --set controller.service.externalIPs=null \
        --set controller.config.use-forwarded-headers=true \
        --set controller.config.proxy-real-ip-cidr="0.0.0.0/0" \
        --wait

    # Wait for ingress controller to be ready
    echo "⏳ Waiting for Ingress Controller to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n ingress-nginx

    echo "✅ Ingress setup completed on $cluster"
done

echo ""
echo "🎉 NGINX Ingress Controller setup completed on all clusters!"
echo ""
echo "📋 Ingress services will be available via LoadBalancer IPs"
echo ""
echo "🔍 To check ingress services:"
echo "  kubectl get svc -n ingress-nginx"
echo ""
echo "📝 Example ingress resource:"
echo "  apiVersion: networking.k8s.io/v1"
echo "  kind: Ingress"
echo "  metadata:"
echo "    name: example-ingress"
echo "  spec:"
echo "    ingressClassName: nginx"
echo "    rules:"
echo "    - host: app.local"
echo "      http:"
echo "        paths:"
echo "        - path: /"
echo "          pathType: Prefix"
echo "          backend:"
echo "            service:"
echo "              name: app-service"
echo "              port:"
echo "                number: 80"
