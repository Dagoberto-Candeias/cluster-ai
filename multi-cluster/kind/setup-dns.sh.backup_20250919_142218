#!/bin/bash

# Script to set up local DNS with failover using CoreDNS
set -e

echo "🗂️  Setting up Local DNS with Failover"
echo "===================================="

CLUSTERS=("aws-cluster" "gcp-cluster" "azure-cluster")

# Create CoreDNS ConfigMap for each cluster
create_coredns_config() {
    local cluster=$1
    local cluster_ip=$2

    cat <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
    cluster-ai.local:53 {
        errors
        cache 30
        forward . 172.18.255.100 172.18.255.101 172.18.255.102 {
           health_check 5s
           policy sequential
        }
    }
EOF
}

# Deploy CoreDNS to each cluster
for cluster in "${CLUSTERS[@]}"; do
    echo ""
    echo "📦 Setting up DNS on cluster: $cluster"

    # Switch to the cluster context
    kubectl config use-context "kind-$cluster"

    # Create CoreDNS config
    create_coredns_config "$cluster" > coredns-config.yaml

    # Apply CoreDNS config
    kubectl apply -f coredns-config.yaml

    # Restart CoreDNS pods to pick up new config
    kubectl rollout restart deployment coredns -n kube-system

    # Wait for CoreDNS to be ready
    echo "⏳ Waiting for CoreDNS to restart..."
    kubectl wait --for=condition=available --timeout=60s deployment/coredns -n kube-system

    echo "✅ DNS setup completed on $cluster"
done

# Clean up temp file
rm -f coredns-config.yaml

echo ""
echo "🎉 DNS setup completed on all clusters!"
echo ""
echo "📋 DNS Configuration:"
echo "  - Local domain: cluster-ai.local"
echo "  - Failover IPs: 172.18.255.100, 172.18.255.101, 172.18.255.102"
echo "  - Health checks: 5s intervals"
echo "  - Policy: Sequential failover"
echo ""
echo "🔍 To test DNS:"
echo "  kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup app.cluster-ai.local"
echo ""
echo "📝 Add to /etc/hosts for local access:"
echo "  172.18.255.100  app.cluster-ai.local"
echo "  172.18.255.101  app.cluster-ai.local"
echo "  172.18.255.102  app.cluster-ai.local"
