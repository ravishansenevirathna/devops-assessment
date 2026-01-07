# DevOps Assessment Documentation

**Author:** Ravishan
**Date:** January 7, 2026
**Server:** Ubuntu 24.04 LTS

---

## Table of Contents

- [Part 1: Linux System Setup & Application Deployment](#part-1-linux-system-setup--application-deployment)
  - [Task 1.1: System User and Directory Setup](#task-11-system-user-and-directory-setup)
  - [Task 1.2: Install Application Dependencies](#task-12-install-application-dependencies)
  - [Task 1.3: Deploy Flask Application](#task-13-deploy-flask-application)
  - [Task 1.4: System Monitoring](#task-14-system-monitoring)
- [Part 2: Docker Setup](#part-2-docker-setup)
  - [Task 2.1: Docker Installation](#task-21-docker-installation)
- [Part 3: Kubernetes Orchestration](#part-3-kubernetes-orchestration)
  - [Task 3.1: Setup Local Kubernetes Cluster](#task-31-setup-local-kubernetes-cluster)
  - [Task 3.2: Deploy Application to Kubernetes](#task-32-deploy-application-to-kubernetes)

---

## Part 1: Linux System Setup & Application Deployment

### Task 1.1: System User and Directory Setup

#### Objective
Create a secure service user, directory structure, and logging configuration for the web application.

#### Step 1: Verify Server Operating System

```bash
cat /etc/os-release
```

#### Step 2: Create the Setup Script

Create and execute the following script:

```bash
#!/bin/bash

# Create service user (no login access for security)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin webapp

# Create directory structure
sudo mkdir -p /opt/webapp/app
sudo mkdir -p /opt/webapp/logs

# Set ownership to webapp user
sudo chown -R webapp:webapp /opt/webapp

# Set permissions (755 = rwxr-xr-x)
sudo chmod 755 /opt/webapp/app/
sudo chmod 755 /opt/webapp/logs/

# Create symbolic link for logs
sudo ln -s /opt/webapp/logs/ /var/log/webapp

# Verification
echo "=== User Information ==="
id webapp

echo -e "\n=== Directory Structure ==="
ls -lR /opt/webapp/

echo -e "\n=== Symbolic Link ==="
ls -l /var/log/ | grep webapp
```

#### Understanding the Symbolic Link

```bash
sudo ln -s /opt/webapp/logs/ /var/log/webapp
```

**What it does:** Creates a shortcut from `/var/log/webapp` pointing to `/opt/webapp/logs/`

**Flags explained:**
- `-s` → Creates a symbolic (soft) link

**Why?** System administrators expect logs in `/var/log/`, but we store them in `/opt/webapp/logs/`. The symlink provides both paths to the same location.

---

### Task 1.2: Install Application Dependencies

#### Objective
Install Python, pip, nginx, virtualenv and create a virtual environment.

#### Installation Commands

| Command | Purpose |
|---------|---------|
| `apt update` | Updates package cache to get latest package information |
| `apt install -y python3 python3-pip python3-venv nginx` | Installs all required packages in one command. `-y` auto-confirms |
| `python3 -m venv /opt/webapp/venv` | Creates virtual environment using Python's built-in venv module |
| `chown -R webapp:webapp /opt/webapp/venv` | Gives ownership to webapp user |

#### Quick Setup

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx
sudo python3 -m venv /opt/webapp/venv
sudo chown -R webapp:webapp /opt/webapp/venv
```

---

### Task 1.3: Deploy Flask Application

#### Step 1: Create Flask Application

```bash
sudo nano /opt/webapp/app/app.py
```

Paste the following code:

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

Save with `Ctrl+O`, `Enter`, `Ctrl+X`

Set ownership:

```bash
sudo chown webapp:webapp /opt/webapp/app/app.py
```

#### Step 2: Install Python Packages

```bash
sudo -u webapp /opt/webapp/venv/bin/pip install flask gunicorn
```

#### Step 3: Generate requirements.txt

```bash
sudo -u webapp /opt/webapp/venv/bin/pip freeze > /tmp/requirements.txt
sudo mv /tmp/requirements.txt /opt/webapp/app/requirements.txt
sudo chown webapp:webapp /opt/webapp/app/requirements.txt
```

#### Step 4: Create Log Files

```bash
sudo touch /opt/webapp/logs/webapp.out.log /opt/webapp/logs/webapp.err.log
sudo chown webapp:webapp /opt/webapp/logs/webapp.out.log /opt/webapp/logs/webapp.err.log
```

#### Step 5: Create Systemd Service

```bash
sudo nano /etc/systemd/system/webapp.service
```

Paste the following configuration:

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

Save with `Ctrl+O`, `Enter`, `Ctrl+X`

#### Step 6: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/webapp
```

Paste the following configuration:

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

Save with `Ctrl+O`, `Enter`, `Ctrl+X`

#### Step 7: Enable Nginx Site

```bash
sudo ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

#### Step 8: Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable webapp
sudo systemctl start webapp
```

#### Verification Commands

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

#### Expected Results

**Service status:** `active (running)`
**Enabled:** `enabled`

**Application response:**
```json
{
    "hostname": "mint-candidate-2",
    "message": "Hello from DevOps Training!",
    "version": "1.0"
}
```

**Health check:**
```json
{
    "status": "healthy"
}
```

#### Useful Commands

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

#### Summary

- Flask app at `/opt/webapp/app/app.py`
- Packages: Flask, Gunicorn
- Service: Auto-starts on boot, auto-restarts on failure
- Nginx: Reverse proxy on port 80 → port 5000
- Logs: `/opt/webapp/logs/`

**Architecture:** Client → Nginx (80) → Gunicorn (5000) → Flask

---

### Task 1.4: System Monitoring

#### Monitoring Script

Create a monitoring script that checks:
- Current memory usage (free vs used)
- Disk usage of `/opt/webapp/`
- Number of running processes

#### Check Running Processes

```bash
ps aux | wc -l
# Output: 108
```

#### Configure Cron Job

Set up monitoring to run every 5 minutes:

```bash
crontab -l
*/5 * * * * /opt/webapp/monitor.sh
```

---

## Part 2: Docker Setup

### Task 2.1: Docker Installation

#### Objective
Install Docker and configure for non-root usage.

**Date:** January 7, 2026
**Server:** Ubuntu 24.04 LTS

#### Installation Steps

**Step 1: Run Installation Script**

```bash
chmod +x part_five_docker_install.sh
./part_five_docker_install.sh
```

**Step 2: Apply Group Changes**

```bash
newgrp docker
```

Or logout and login again.

#### Verification

```bash
# Check version
docker --version

# Check info
docker info

# Test Docker
docker run hello-world
```

#### Expected Results

**Docker version:**
```
Docker version 24.0.7, build afdd53b
```

**Hello-world test:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

**Service status:**

```bash
systemctl status docker
# Should show: active (running)

systemctl is-enabled docker
# Should show: enabled
```

#### Summary

- Docker installed (latest stable version)
- Docker service running and enabled on boot
- User added to docker group (can run without sudo)
- Verified with hello-world container

#### Useful Docker Commands

```bash
docker ps              # List running containers
docker ps -a           # List all containers
docker images          # List images
docker --version       # Check version
systemctl status docker # Check service
```

---

## Project Structure

```
/opt/webapp/
├── app/
│   ├── app.py
│   └── requirements.txt
├── logs/
│   ├── webapp.out.log
│   └── webapp.err.log
└── venv/
    └── [virtual environment files]

/var/log/webapp → /opt/webapp/logs/ (symbolic link)

/etc/systemd/system/
└── webapp.service

/etc/nginx/sites-available/
└── webapp
```

---

## Quick Reference

### Service Management
```bash
sudo systemctl status webapp    # Check status
sudo systemctl restart webapp   # Restart service
sudo systemctl enable webapp    # Enable on boot
journalctl -u webapp -f        # Follow logs
```

### Application Testing
```bash
curl http://localhost          # Test via Nginx
curl http://localhost/health   # Health check
```

### Monitoring
```bash
free -h                        # Memory usage
df -h /opt/webapp/             # Disk usage
ps aux | wc -l                 # Process count
```

---

## Part 3: Kubernetes Orchestration

### Overview

**Scenario:** The company wants to move to Kubernetes for better orchestration and scalability.

This section covers setting up a local Kubernetes cluster using K3s and deploying the Flask application with Redis to Kubernetes.

---

### Task 3.1: Setup Local Kubernetes Cluster

#### Objective
Create a local Kubernetes environment using K3s with local-path-provisioner as the default storage class.

#### Why K3s?
- Lightweight Kubernetes distribution (perfect for development/testing)
- Minimal resource requirements
- Includes local-path-provisioner by default
- Production-ready, CNCF certified

#### Installation Steps

**Step 1: Run the K3s Installation Script**

Navigate to the configuration directory:
```bash
cd Part-3/Task-3.1/Config-Files
chmod +x k3s-install.sh
./k3s-install.sh
```

The script performs the following actions:
1. Downloads and installs K3s
2. Configures kubectl access for the current user
3. Sets up kubeconfig in `~/.kube/config`
4. Patches local-path storage class as default
5. Verifies the installation

**Step 2: Verify Installation**

```bash
chmod +x verify-setup.sh
./verify-setup.sh
```

#### Manual Installation (Alternative)

If you prefer to install manually:

```bash
# Install K3s
curl -sfL https://get.k3s.io | sh -

# Configure kubectl access
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Set local-path as default storage class
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### Verification Commands

```bash
# Check K3s service status
sudo systemctl status k3s

# Verify cluster nodes
kubectl get nodes

# Check system pods
kubectl get pods --all-namespaces

# Verify storage classes
kubectl get storageclass
```

#### Expected Results

**K3s Service:**
```
● k3s.service - Lightweight Kubernetes
   Loaded: loaded
   Active: active (running)
```

**Node Status:**
```
NAME              STATUS   ROLES                  AGE   VERSION
mint-candidate-2  Ready    control-plane,master   1m    v1.27.x+k3s1
```

**Storage Classes:**
```
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   1m
```

#### Useful K3s Commands

```bash
# K3s service management
sudo systemctl status k3s
sudo systemctl restart k3s
sudo systemctl stop k3s

# Uninstall K3s (if needed)
/usr/local/bin/k3s-uninstall.sh

# View K3s logs
sudo journalctl -u k3s -f

# Cluster information
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

#### Configuration Files Location

```
Part-3/Task-3.1/Config-Files/
├── k3s-install.sh      # K3s installation script
└── verify-setup.sh     # Verification script
```

---

### Task 3.2: Deploy Application to Kubernetes

#### Objective
Deploy the Flask web application with Redis backend to Kubernetes using proper resource management, health checks, and persistent storage.

#### Prerequisites

1. K3s cluster running (from Task 3.1)
2. Docker image `webapp:v1` available locally
3. kubectl configured and working

#### Architecture Overview

```
┌─────────────────────────────────────────┐
│         Kubernetes Cluster (K3s)        │
│                                         │
│  ┌────────────────────────────────┐    │
│  │     Namespace: webapp          │    │
│  │                                │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  webapp-deployment   │     │    │
│  │  │  - 2 replicas        │     │    │
│  │  │  - Health checks     │     │    │
│  │  │  - Resource limits   │     │    │
│  │  └──────────────────────┘     │    │
│  │            ↓                   │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  webapp-service      │     │    │
│  │  │  ClusterIP :5000     │     │    │
│  │  └──────────────────────┘     │    │
│  │            ↓                   │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  redis-deployment    │     │    │
│  │  │  - 1 replica         │     │    │
│  │  │  - Persistent volume │     │    │
│  │  └──────────────────────┘     │    │
│  │            ↓                   │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  redis-service       │     │    │
│  │  │  ClusterIP :6379     │     │    │
│  │  └──────────────────────┘     │    │
│  │            ↓                   │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  redis-data (PVC)    │     │    │
│  │  │  1Gi storage         │     │    │
│  │  └──────────────────────┘     │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

#### Kubernetes Manifests Overview

**1. namespace.yaml** - Creates isolated namespace
**2. redis-pvc.yaml** - Persistent storage for Redis data
**3. redis-deployment.yaml** - Redis database deployment
**4. redis-service.yaml** - Service to expose Redis
**5. webapp-deployment.yaml** - Flask application deployment
**6. webapp-service.yaml** - Service to expose webapp

#### Deployment Steps

**Quick Deployment (Automated)**

Navigate to the configuration directory and run the deployment script:

```bash
cd Part-3/Task-3.2/Config-Files
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Create the namespace
2. Create Redis PVC
3. Deploy Redis and its service
4. Wait for Redis to be ready
5. Deploy webapp and its service
6. Wait for webapp to be ready
7. Display deployment status

**Manual Deployment (Step by Step)**

```bash
cd Part-3/Task-3.2/Config-Files

# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create Redis PVC
kubectl apply -f redis-pvc.yaml

# 3. Deploy Redis
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml

# 4. Wait for Redis to be ready
kubectl wait --for=condition=ready pod -l app=redis -n webapp --timeout=60s

# 5. Deploy Webapp
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml

# 6. Wait for Webapp to be ready
kubectl wait --for=condition=ready pod -l app=webapp -n webapp --timeout=90s
```

#### Manifest Files Detailed Explanation

**1. namespace.yaml**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: webapp
```
- Creates isolated environment for the application

**2. redis-pvc.yaml**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-data
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```
- Requests 1Gi of persistent storage for Redis data
- Uses local-path storage class (default in K3s)

**3. redis-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "250m"
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-data
```
- Single replica deployment
- Uses Redis 7 Alpine (lightweight)
- Mounts persistent volume at `/data`
- Resource limits prevent over-consumption

**4. redis-service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: webapp
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
```
- ClusterIP service (internal only)
- Exposes Redis on port 6379
- DNS name: `redis-service.webapp.svc.cluster.local`

**5. webapp-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    spec:
      containers:
      - name: webapp
        image: webapp:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
        env:
        - name: REDIS_HOST
          value: "redis-service"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```
Key features:
- **2 replicas** for high availability
- **Resource limits**: 256Mi memory, 250m CPU
- **Resource requests**: 128Mi memory, 100m CPU
- **Liveness probe**: Restarts unhealthy containers
- **Readiness probe**: Controls traffic routing
- **Environment variable**: REDIS_HOST=redis-service

**6. webapp-service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: webapp
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
  selector:
    app: webapp
```
- ClusterIP service
- Load balances across 2 webapp pods
- Port 5000

#### Verification

**Run Verification Script:**
```bash
chmod +x verify.sh
./verify.sh
```

**Manual Verification:**

```bash
# Check all resources in webapp namespace
kubectl get all -n webapp

# Check pods
kubectl get pods -n webapp -o wide

# Check services
kubectl get svc -n webapp

# Check PVC
kubectl get pvc -n webapp

# Describe webapp deployment
kubectl describe deployment webapp -n webapp

# Check pod logs
kubectl logs -l app=webapp -n webapp

# Check Redis logs
kubectl logs -l app=redis -n webapp
```

#### Expected Results

**Pods:**
```
NAME                      READY   STATUS    RESTARTS   AGE
webapp-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
webapp-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
redis-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
```

**Services:**
```
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
webapp-service    ClusterIP   10.43.xxx.xxx   <none>        5000/TCP   1m
redis-service     ClusterIP   10.43.xxx.xxx   <none>        6379/TCP   2m
```

**PVC:**
```
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
redis-data   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi        RWO            local-path     2m
```

#### Testing the Application

**Method 1: Port Forward**
```bash
# Forward service port to localhost
kubectl port-forward svc/webapp-service 8080:5000 -n webapp

# In another terminal, test the application
curl http://localhost:8080
curl http://localhost:8080/health
```

**Method 2: From within the cluster**
```bash
# Run a test pod
kubectl run test-pod --image=alpine/curl --rm -it -n webapp -- sh

# Inside the pod
curl http://webapp-service:5000
curl http://webapp-service:5000/health
```

**Expected Response:**
```json
{
  "hostname": "webapp-xxxxxxxxxx-xxxxx",
  "message": "Hello from DevOps Training!",
  "version": "1.0"
}
```

#### Resource Management Explained

**Resource Requests:**
- Guaranteed minimum resources
- Used by scheduler for pod placement
- webapp: 128Mi memory, 100m CPU per pod
- Total for 2 replicas: 256Mi memory, 200m CPU

**Resource Limits:**
- Maximum resources a pod can use
- Pod gets throttled (CPU) or terminated (memory) if exceeded
- webapp: 256Mi memory, 250m CPU per pod

**Why this matters:**
- Prevents resource starvation
- Ensures fair resource distribution
- Protects cluster stability

#### Health Checks Explained

**Liveness Probe:**
- Checks if container is alive
- Restarts container if probe fails
- Path: `/health`, Port: `5000`
- Initial delay: 10s, Period: 10s

**Readiness Probe:**
- Checks if container is ready to serve traffic
- Removes from service endpoints if probe fails
- Path: `/health`, Port: `5000`
- Initial delay: 5s, Period: 5s

**Probe Flow:**
```
Container Start → Wait 5s → Readiness Check → Pass → Add to Service
                          → Fail → Wait 5s → Retry

                → Wait 10s → Liveness Check → Pass → Continue
                           → Fail → Restart Container
```

#### Scaling the Application

```bash
# Scale webapp to 3 replicas
kubectl scale deployment webapp --replicas=3 -n webapp

# Verify scaling
kubectl get pods -n webapp -l app=webapp

# Scale down to 1 replica
kubectl scale deployment webapp --replicas=1 -n webapp
```

#### Updating the Application

```bash
# Update the image (if you have webapp:v2)
kubectl set image deployment/webapp webapp=webapp:v2 -n webapp

# Check rollout status
kubectl rollout status deployment/webapp -n webapp

# View rollout history
kubectl rollout history deployment/webapp -n webapp

# Rollback to previous version
kubectl rollout undo deployment/webapp -n webapp
```

#### Troubleshooting

**Pod not starting:**
```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n webapp

# Check logs
kubectl logs <pod-name> -n webapp

# Check previous logs (if pod restarted)
kubectl logs <pod-name> -n webapp --previous
```

**Image pull errors:**
```bash
# For local images, ensure imagePullPolicy is set to Never
# Check if image exists
docker images | grep webapp

# Import image to K3s (if needed)
sudo k3s ctr images import webapp-v1.tar
```

**Service not accessible:**
```bash
# Check service endpoints
kubectl get endpoints webapp-service -n webapp

# Should show pod IPs - if empty, check pod readiness probes
kubectl get pods -n webapp
```

**Redis connection issues:**
```bash
# Test Redis connectivity from webapp pod
kubectl exec -n webapp <webapp-pod-name> -- wget -qO- http://redis-service:6379

# Check Redis logs
kubectl logs -l app=redis -n webapp
```

#### Cleanup

**Using cleanup script:**
```bash
chmod +x cleanup.sh
./cleanup.sh
```

**Manual cleanup:**
```bash
# Delete all resources
kubectl delete -f webapp-service.yaml
kubectl delete -f webapp-deployment.yaml
kubectl delete -f redis-service.yaml
kubectl delete -f redis-deployment.yaml
kubectl delete -f redis-pvc.yaml

# Optionally delete namespace (deletes everything inside)
kubectl delete -f namespace.yaml
```

#### Configuration Files Location

```
Part-3/Task-3.2/Config-Files/
├── namespace.yaml          # Namespace definition
├── redis-pvc.yaml          # Redis persistent volume claim
├── redis-deployment.yaml   # Redis deployment
├── redis-service.yaml      # Redis service
├── webapp-deployment.yaml  # Webapp deployment with health checks
├── webapp-service.yaml     # Webapp service
├── deploy.sh               # Automated deployment script
├── verify.sh               # Verification script
└── cleanup.sh              # Cleanup script
```

#### Summary

**Deployed Components:**
- Namespace: `webapp`
- Deployments: `webapp` (2 replicas), `redis` (1 replica)
- Services: `webapp-service` (5000), `redis-service` (6379)
- PVC: `redis-data` (1Gi)

**Key Features:**
- High availability with 2 webapp replicas
- Persistent storage for Redis data
- Resource limits and requests for stability
- Liveness and readiness probes for reliability
- Environment-based configuration
- Service discovery via Kubernetes DNS

**Best Practices Implemented:**
- Namespace isolation
- Resource management
- Health checks
- Persistent storage
- Service abstraction
- Configuration via environment variables

---

## Updated Project Structure

```
devops-assessment/
├── README-DOC.md
│
├── Part-1/
│   └── [Linux setup scripts and configs]
│
├── Part-2/
│   └── [Docker installation scripts]
│
└── Part-3/
    ├── Task-3.1/
    │   └── Config-Files/
    │       ├── k3s-install.sh       # K3s installation
    │       └── verify-setup.sh      # Cluster verification
    │
    └── Task-3.2/
        └── Config-Files/
            ├── namespace.yaml          # Namespace
            ├── redis-pvc.yaml          # Redis storage
            ├── redis-deployment.yaml   # Redis deployment
            ├── redis-service.yaml      # Redis service
            ├── webapp-deployment.yaml  # Webapp deployment
            ├── webapp-service.yaml     # Webapp service
            ├── deploy.sh               # Deploy automation
            ├── verify.sh               # Verification
            └── cleanup.sh              # Cleanup automation
```

---

## Complete Quick Reference

### Part 1: Linux & Application
```bash
# Service Management
sudo systemctl status webapp
sudo systemctl restart webapp

# Testing
curl http://localhost
curl http://localhost/health
```

### Part 2: Docker
```bash
# Docker Management
docker ps                   # Running containers
docker images               # List images
docker run hello-world      # Test installation
```

### Part 3: Kubernetes
```bash
# Cluster Management
kubectl get nodes
kubectl get pods -A
kubectl cluster-info

# Application Management
kubectl get all -n webapp
kubectl get pods -n webapp
kubectl logs <pod-name> -n webapp
kubectl describe pod <pod-name> -n webapp

# Port Forwarding
kubectl port-forward svc/webapp-service 8080:5000 -n webapp

# Scaling
kubectl scale deployment webapp --replicas=3 -n webapp

# Cleanup
kubectl delete namespace webapp
```

---

**End of Documentation**
