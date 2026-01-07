#!/bin/bash

echo "=== K3s Installation and Setup ==="
echo ""

echo "Step 1: Installing K3s..."
curl -sfL https://get.k3s.io | sh -

echo ""
echo "Step 2: Waiting for K3s to start..."
sleep 10

echo ""
echo "Step 3: Setting up kubectl access..."
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

echo ""
echo "Step 4: Creating kubectl alias..."
echo "alias kubectl='k3s kubectl'" >> ~/.bashrc
alias kubectl='k3s kubectl'

echo ""
echo "Step 5: Verifying local-path-provisioner (built-in)..."
k3s kubectl get storageclass

echo ""
echo "Step 6: Setting local-path as default (if not already)..."
k3s kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo ""
echo "=== Verification ==="
echo ""

echo "1. Kubectl Version:"
k3s kubectl version --short

echo ""
echo "2. Cluster Info:"
k3s kubectl cluster-info

echo ""
echo "3. Node Status:"
k3s kubectl get nodes

echo ""
echo "4. Storage Classes:"
k3s kubectl get storageclass

echo ""
echo "5. All System Pods:"
k3s kubectl get pods -A

echo ""
echo "=== Installation Complete ==="
echo ""
echo "✅ K3s installed successfully"
echo "✅ kubectl configured"
echo "✅ local-path-provisioner is default storage class"
echo ""
echo "Usage:"
echo "  k3s kubectl get nodes           # Using k3s kubectl"
echo "  kubectl get nodes                # Using alias (after: source ~/.bashrc)"
echo ""
echo "Reload shell to use 'kubectl' alias:"
echo "  source ~/.bashrc"
echo "  OR logout and login again"