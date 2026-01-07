#!/bin/bash

# Kubernetes Cleanup Script
# Author: Ravishan
# Date: January 7, 2026

echo "=== Cleaning up Kubernetes Resources ==="
echo ""

read -p "This will delete all resources in the webapp namespace. Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Deleting resources..."

# Delete services first
echo "1. Deleting services..."
kubectl delete -f webapp-service.yaml --ignore-not-found=true
kubectl delete -f redis-service.yaml --ignore-not-found=true

# Delete deployments
echo "2. Deleting deployments..."
kubectl delete -f webapp-deployment.yaml --ignore-not-found=true
kubectl delete -f redis-deployment.yaml --ignore-not-found=true

# Delete PVC
echo "3. Deleting PVC..."
kubectl delete -f redis-pvc.yaml --ignore-not-found=true

# Optionally delete namespace
echo ""
read -p "Delete namespace 'webapp'? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "4. Deleting namespace..."
    kubectl delete -f namespace.yaml --ignore-not-found=true
fi

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Checking remaining resources..."
kubectl get all -n webapp 2>/dev/null || echo "Namespace deleted or empty."
