#!/bin/bash

echo "=== Updating Package Cache ==="
sudo apt update

echo -e "\n=== Installing Required Packages ==="
sudo apt install -y python3 python3-pip python3-venv nginx

echo -e "\n=== Creating Virtual Environment ==="
sudo python3 -m venv /opt/webapp/venv

echo -e "\n=== Setting Ownership ==="
sudo chown -R webapp:webapp /opt/webapp/venv

echo -e "\n=== Verification ==="
echo "Python Version:"
python3 --version

echo -e "\nPip Version:"
pip3 --version

echo -e "\nVirtualenv Module:"
python3 -m venv --help > /dev/null 2>&1 && echo "✅ venv module available" || echo "❌ venv module not found"

echo -e "\nNginx Version:"
nginx -v

echo -e "\nVirtual Environment Directory:"
ls -la /opt/webapp/venv/

echo -e "\n=== Setup Complete ==="