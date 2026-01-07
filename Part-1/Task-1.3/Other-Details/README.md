# Flask Web Application Deployment - Part 3: Quick Reference

**Objective:** Deploy Flask app with Gunicorn and Nginx

---

## Quick Setup Commands

### Step 1: Create Flask Application

```bash
sudo nano /opt/webapp/app/app.py
```

Paste this code:

```python
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
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

```bash
sudo chown webapp:webapp /opt/webapp/app/app.py
```

---

### Step 2: Install Packages

```bash
sudo -u webapp /opt/webapp/venv/bin/pip install flask gunicorn
```

---

### Step 3: Generate requirements.txt

```bash
sudo -u webapp /opt/webapp/venv/bin/pip freeze > /tmp/requirements.txt
sudo mv /tmp/requirements.txt /opt/webapp/app/requirements.txt
sudo chown webapp:webapp /opt/webapp/app/requirements.txt
```

---

### Step 4: Create Log Files

```bash
sudo touch /opt/webapp/logs/webapp.out.log /opt/webapp/logs/webapp.err.log
sudo chown webapp:webapp /opt/webapp/logs/webapp.out.log /opt/webapp/logs/webapp.err.log
```

---

### Step 5: Create Systemd Service

```bash
sudo nano /etc/systemd/system/webapp.service
```

Paste this:

```ini
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
StandardOutput=append:/opt/webapp/logs/webapp.out.log
StandardError=append:/opt/webapp/logs/webapp.err.log

[Install]
WantedBy=multi-user.target
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### Step 6: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/webapp
```

Paste this:

```nginx
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
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### Step 7: Enable Nginx Site

```bash
sudo ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

---

### Step 8: Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable webapp
sudo systemctl start webapp
```

---

## Verification Commands

```bash
# Check service status
sudo systemctl status webapp

# Check if enabled for boot
systemctl is-enabled webapp

# Test application
curl http://localhost
curl http://localhost/health

# View logs
journalctl -u webapp -n 20
```

---

## Expected Results

- **Service status:** `active (running)`
- **Enabled:** `enabled`
- **Application response:**
  ```json
  {"hostname":"mint-candidate-2","message":"Hello from DevOps Training!","version":"1.0"}
  ```
- **Health check:**
  ```json
  {"status":"healthy"}
  ```

---

## Useful Commands

```bash
# Service control
sudo systemctl start webapp
sudo systemctl stop webapp
sudo systemctl restart webapp
sudo systemctl status webapp

# View logs
journalctl -u webapp -f                    # Follow logs
tail -f /opt/webapp/logs/webapp.out.log    # App stdout
tail -f /opt/webapp/logs/webapp.err.log    # App stderr

# Test application
curl http://localhost                      # Via Nginx
curl http://localhost:5000                 # Direct to Gunicorn

# Nginx
sudo nginx -t                              # Test config
sudo systemctl reload nginx                # Reload
```

---

## Summary

✅ Flask app at `/opt/webapp/app/app.py`
✅ Packages: Flask, Gunicorn
✅ Service: Auto-starts on boot, auto-restarts on failure
✅ Nginx: Reverse proxy on port 80 → port 5000
✅ Logs: `/opt/webapp/logs/`

**Architecture:** Client → Nginx (80) → Gunicorn (5000) → Flask
