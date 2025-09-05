#!/bin/bash
echo "🔍 Descobrindo workers automaticamente..."
kubectl get pods -l app=dask,component=worker -o wide
