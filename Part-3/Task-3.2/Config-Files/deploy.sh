#!/bin/bash

# Kubernetes Deployment Script
# Author: Ravishan
# Date: January 7, 2026

set -e

echo "=== Deploying Application to Kubernetes ==="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install K3s first."
    exit 1
fi

# Apply namespace
echo "1. Creating namespace..."
kubectl apply -f namespace.yaml

# Wait for namespace
sleep 2

# Apply Redis PVC
echo ""
echo "2. Creating Redis Persistent Volume Claim..."
kubectl apply -f redis-pvc.yaml

# Wait for PVC
sleep 2

# Apply Redis deployment and service
echo ""
echo "3. Deploying Redis..."
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml

# Wait for Redis to be ready
echo ""
echo "4. Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n webapp --timeout=60s

# Apply webapp deployment and service
echo ""
echo "5. Deploying Webapp..."
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml

# Wait for webapp to be ready
echo ""
echo "6. Waiting for Webapp to be ready..."
kubectl wait --for=condition=ready pod -l app=webapp -n webapp --timeout=90s

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Checking deployment status..."
kubectl get all -n webapp

echo ""
echo "=== Useful Commands ==="
echo "View pods:        kubectl get pods -n webapp"
echo "View services:    kubectl get svc -n webapp"
echo "View deployments: kubectl get deployments -n webapp"
echo "View PVC:         kubectl get pvc -n webapp"
echo "Describe pod:     kubectl describe pod <pod-name> -n webapp"
echo "View logs:        kubectl logs <pod-name> -n webapp"
echo "Port forward:     kubectl port-forward svc/webapp-service 8080:5000 -n webapp"
