#!/bin/bash

# K3s Setup Verification Script
# Author: Ravishan
# Date: January 7, 2026

echo "=== K3s Cluster Verification ==="
echo ""

echo "1. Checking K3s service status..."
sudo systemctl status k3s --no-pager | head -n 10

echo ""
echo "2. Checking cluster nodes..."
kubectl get nodes -o wide

echo ""
echo "3. Checking system pods..."
kubectl get pods --all-namespaces

echo ""
echo "4. Checking storage classes..."
kubectl get storageclass

echo ""
echo "5. Verifying default storage class..."
kubectl get storageclass | grep "(default)"

echo ""
echo "6. Checking cluster info..."
kubectl cluster-info

echo ""
echo "=== Verification Complete ==="
