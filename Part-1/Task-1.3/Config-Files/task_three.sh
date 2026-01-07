#!/bin/bash

echo "=== Step 1: Creating Flask Application ==="
sudo tee /opt/webapp/app/app.py > /dev/null << 'EOF'
from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Hello from DevOps Training!",
        "hostname": socket.gethostname(),
        "version": "1.0"
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Setting ownership for app.py..."
sudo chown webapp:webapp /opt/webapp/app/app.py

echo -e "\n=== Step 2: Installing Flask and Gunicorn ==="
sudo -u webapp /opt/webapp/venv/bin/pip install flask gunicorn

echo -e "\n=== Step 3: Generating requirements.txt ==="
sudo -u webapp /opt/webapp/venv/bin/pip freeze > /tmp/requirements.txt
sudo mv /tmp/requirements.txt /opt/webapp/app/requirements.txt
sudo chown webapp:webapp /opt/webapp/app/requirements.txt

echo -e "\n=== Step 4: Creating Log Files ==="
sudo touch /opt/webapp/logs/webapp.out.log
sudo touch /opt/webapp/logs/webapp.err.log
sudo chown webapp:webapp /opt/webapp/logs/webapp.out.log
sudo chown webapp:webapp /opt/webapp/logs/webapp.err.log

echo -e "\n=== Step 5: Creating systemd Service File ==="
sudo tee /etc/systemd/system/webapp.service > /dev/null << 'EOF'
[Unit]
Description=Flask Web Application
After=network.target

[Service]
Type=notify
User=webapp
Group=webapp
WorkingDirectory=/opt/webapp/app
Environment="PATH=/opt/webapp/venv/bin"
ExecStart=/opt/webapp/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 app:app
Restart=always
RestartSec=3

# Logging
StandardOutput=append:/opt/webapp/logs/webapp.out.log
StandardError=append:/opt/webapp/logs/webapp.err.log

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n=== Step 6: Configuring Nginx Reverse Proxy ==="
sudo tee /etc/nginx/sites-available/webapp > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:5000/health;
        access_log off;
    }
}
EOF

echo -e "\n=== Step 7: Enabling Nginx Site ==="
sudo ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
sudo rm -f /etc/nginx/sites-enabled/default

echo "Testing Nginx configuration..."
sudo nginx -t

echo -e "\n=== Step 8: Reloading Nginx ==="
sudo systemctl reload nginx

echo -e "\n=== Step 9: Enabling and Starting Service ==="
sudo systemctl daemon-reload
sudo systemctl enable webapp
sudo systemctl start webapp

echo -e "\n=== Waiting for Service to Start ==="
sleep 3

echo -e "\n=== Verification ==="
echo "1. Service Status:"
sudo systemctl status webapp --no-pager -l

echo -e "\n2. Service Enabled:"
systemctl is-enabled webapp

echo -e "\n3. Nginx Status:"
sudo systemctl status nginx --no-pager | head -10

echo -e "\n4. Testing Application (Direct - Port 5000):"
curl -s http://localhost:5000 2>/dev/null && echo "" || echo "Failed to connect to port 5000"

echo -e "\n5. Testing Application (Via Nginx - Port 80):"
curl -s http://localhost 2>/dev/null && echo "" || echo "Failed to connect to port 80"

echo -e "\n6. Testing Health Endpoint:"
curl -s http://localhost/health 2>/dev/null && echo "" || echo "Failed to connect to health endpoint"

echo -e "\n7. Recent Service Logs:"
sudo journalctl -u webapp -n 20 --no-pager

echo -e "\n8. Checking Ports:"
echo "Port 5000 (Gunicorn):"
sudo ss -tlnp | grep :5000
echo "Port 80 (Nginx):"
sudo ss -tlnp | grep :80

echo -e "\n=== Setup Complete ==="
echo "✅ Flask application deployed successfully!"
echo "✅ Accessible at: http://localhost"
echo "✅ Health check: http://localhost/health"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status webapp     # Check service status"
echo "  sudo systemctl restart webapp    # Restart service"
echo "  journalctl -u webapp -f          # Follow logs"
echo "  curl http://localhost            # Test application"