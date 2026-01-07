#!/bin/bash

echo "=== Docker Installation Script ==="
echo ""

echo "Step 1: Updating package cache..."
sudo apt update

echo ""
echo "Step 2: Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg lsb-release

echo ""
echo "Step 3: Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo ""
echo "Step 4: Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ""
echo "Step 5: Updating package cache with Docker repo..."
sudo apt update

echo ""
echo "Step 6: Installing Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "Step 7: Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo ""
echo "Step 8: Adding current user to docker group..."
sudo usermod -aG docker $USER

echo ""
echo "Step 9: Adding root user to docker group..."
sudo usermod -aG docker root

echo ""
echo "=== Verification ==="
echo ""

echo "Docker Version:"
docker --version

echo ""
echo "Docker Service Status:"
systemctl status docker --no-pager | head -10

echo ""
echo "Docker Info:"
docker info

echo ""
echo "Testing with hello-world..."
docker run hello-world

echo ""
echo "=== Installation Complete ==="
echo ""
echo "✅ Docker installed successfully"
echo "✅ Docker service is running and enabled"
echo "✅ User added to docker group"
echo ""
echo "⚠️  IMPORTANT: You may need to log out and log back in for group changes to take effect"
echo "    Or run: newgrp docker"
echo ""
echo "Verify installation:"
echo "  docker --version"
echo "  docker info"
echo "  docker ps"