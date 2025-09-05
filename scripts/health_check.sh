#!/bin/bash
echo "✅ Verificando saúde do Cluster-AI..."
kubectl get pods -l app=dask -o wide
