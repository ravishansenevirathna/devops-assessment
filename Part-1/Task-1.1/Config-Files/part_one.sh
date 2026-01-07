#!/bin/bash

# Create service user
sudo useradd --system --no-create-home --shell /usr/sbin/nologin webapp

# Create directory structure
sudo mkdir -p /opt/webapp/app
sudo mkdir -p /opt/webapp/logs

# Set ownership
sudo chown -R webapp:webapp /opt/webapp

# Set permissions
sudo chmod 755 /opt/webapp/app/
sudo chmod 755 /opt/webapp/logs/

# Create symbolic link
sudo ln -s /opt/webapp/logs/ /var/log/webapp

# Verification
echo "=== User Information ==="
id webapp

echo -e "\n=== Directory Structure ==="
tree -L 2 -pugD /opt/webapp/ 2>/dev/null || ls -lR /opt/webapp/

echo -e "\n=== Symbolic Link ==="
ls -l /var/log/ | grep webapp

echo -e "\n=== Permissions Summary ==="
ls -ld /opt/webapp/app/
ls -ld /opt/webapp/logs/