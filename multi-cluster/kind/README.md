# Multi-Cluster Local Simulation with Kind

This directory contains configurations and scripts to set up multiple local Kubernetes clusters using Kind (Kubernetes in Docker) to simulate a multi-cloud environment.

## Goals

- Create multiple Kind clusters to simulate different cloud providers (AWS, GCP, Azure).
- Implement cross-cluster networking using MetalLB.
- Configure local load balancing and ingress controllers.
- Set up DNS with failover capabilities.
- Enable testing of high availability, failover, and disaster recovery in a local environment.

## Clusters Configured

- **aws-cluster**: Simulates AWS environment (ports: 8080/8443/30000-30001, subnet: 10.244.0.0/16)
- **gcp-cluster**: Simulates GCP environment (ports: 8081/8444/30002-30003, subnet: 10.245.0.0/16)
- **azure-cluster**: Simulates Azure environment (ports: 8082/8445/30004-30005, subnet: 10.246.0.0/16)

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Helm](https://helm.sh/docs/intro/install/) installed (for ingress)

## Usage

### Full Automated Setup
```bash
# Run the full setup script
./setup-all.sh
```

### Manual Step-by-Step Setup

#### 1. Create Clusters
```bash
./create-clusters.sh
```

#### 2. Setup Networking (MetalLB)
```bash
./setup-metallb.sh
```

#### 3. Setup Load Balancing (Ingress)
```bash
./setup-ingress.sh
```

#### 4. Setup DNS with Failover
```bash
./setup-dns.sh
```

### Switch Between Clusters
```bash
kubectl config use-context kind-aws-cluster
kubectl config use-context kind-gcp-cluster
kubectl config use-context kind-azure-cluster
```

### Verify Setup
```bash
# List active clusters
kind get clusters

# List LoadBalancer services
kubectl get svc -A | grep LoadBalancer

# List ingress controllers
kubectl get svc -n ingress-nginx

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup app.cluster-ai.local
```

### Cleanup
```bash
./delete-clusters.sh
```

## Network Configuration

### MetalLB
- IP Range: 172.18.255.1-172.18.255.250
- Protocol: Layer 2
- Provides LoadBalancer services for all clusters

### Ingress (NGINX)
- Ingress Class: nginx
- Load Balancer: Integrated with MetalLB
- Supports multiple hosts and paths

### DNS (CoreDNS)
- Local Domain: cluster-ai.local
- Failover IPs: 172.18.255.100, 172.18.255.101, 172.18.255.102
- Health Checks: 5s intervals
- Policy: Sequential failover

## Example Multi-Cluster Deployment

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: nginx
        ports:
        - containerPort: 80
```

### Service LoadBalancer
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app.cluster-ai.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

## Next Steps

1. ✅ Configure multiple Kind clusters to simulate multi-cloud
2. ✅ Implement cross-cluster networking with MetalLB
3. ✅ Configure local load balancing with ingress
4. ✅ Implement local DNS with automatic failover
5. [ ] Configure active-active multi-cluster deployments
6. [ ] Implement cross-cluster PostgreSQL replication
7. [ ] Configure cross-cluster Redis Cluster
8. [ ] Implement local service mesh (Istio)
9. [ ] Configure cross-cluster monitoring
10. [ ] Implement local backup and disaster recovery
11. [ ] Test failover and recovery scenarios
