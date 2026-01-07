#!/bin/bash

# Kubernetes Deployment Verification Script
# Author: Ravishan
# Date: January 7, 2026

echo "=== Kubernetes Deployment Verification ==="
echo ""

echo "1. Checking namespace..."
kubectl get namespace webapp

echo ""
echo "2. Checking all resources in webapp namespace..."
kubectl get all -n webapp

echo ""
echo "3. Checking pods details..."
kubectl get pods -n webapp -o wide

echo ""
echo "4. Checking services..."
kubectl get svc -n webapp

echo ""
echo "5. Checking deployments..."
kubectl get deployments -n webapp

echo ""
echo "6. Checking Persistent Volume Claims..."
kubectl get pvc -n webapp

echo ""
echo "7. Checking pod status and readiness..."
echo "Webapp pods:"
kubectl get pods -n webapp -l app=webapp -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?(@.type==\"Ready\")].status

echo ""
echo "Redis pods:"
kubectl get pods -n webapp -l app=redis -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?(@.type==\"Ready\")].status

echo ""
echo "8. Testing webapp health endpoint..."
WEBAPP_POD=$(kubectl get pods -n webapp -l app=webapp -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$WEBAPP_POD" ]; then
    echo "Testing health endpoint on pod: $WEBAPP_POD"
    kubectl exec -n webapp $WEBAPP_POD -- wget -qO- http://localhost:5000/health || echo "Health check failed"
else
    echo "No webapp pod found"
fi

echo ""
echo "9. Checking resource usage..."
kubectl top pods -n webapp 2>/dev/null || echo "Metrics server not available. Install metrics-server to view resource usage."

echo ""
echo "=== Verification Complete ==="
echo ""
echo "To access the application:"
echo "  kubectl port-forward svc/webapp-service 8080:5000 -n webapp"
echo "  Then visit: http://localhost:8080"
