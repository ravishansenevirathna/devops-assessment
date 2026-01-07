#!/bin/bash

echo "=== Containerizing Flask Application ==="
echo ""

echo "Step 1: Creating .dockerignore file..."
cat << 'EOF' > /opt/webapp/.dockerignore
__pycache__
*.pyc
*.pyo
*.pyd
.Python
*.so
*.log
*.pot
*.pyc
.env
.venv
venv/
logs/
*.md
.git
.gitignore
Dockerfile
.dockerignore
EOF
sudo chown webapp:webapp /opt/webapp/.dockerignore
echo "✅ .dockerignore created"

echo ""
echo "Step 2: Creating Dockerfile..."
cat << 'EOF' > /opt/webapp/Dockerfile
# Use Python 3.11 slim image
FROM python:3.11-slim

# Add labels
LABEL maintainer="ravishan@example.com"
LABEL version="1.0"
LABEL description="Flask Web Application with Gunicorn"

# Set working directory
WORKDIR /app

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app

# Copy requirements and install dependencies (as root for installation)
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/app.py .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Run with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "3", "app:app"]
EOF
sudo chown webapp:webapp /opt/webapp/Dockerfile
echo "✅ Dockerfile created"

echo ""
echo "Step 3: Building Docker image..."
cd /opt/webapp
docker build -t webapp:v1 .

echo ""
echo "=== Verification ==="
echo ""

echo "Docker Images:"
docker images webapp:v1

echo ""
echo "Docker History:"
docker history webapp:v1

echo ""
echo "Image Details:"
docker inspect webapp:v1 --format='{{json .Config.Labels}}' | python3 -m json.tool

echo ""
echo "=== Build Complete ==="
echo "✅ Docker image 'webapp:v1' created successfully"
echo ""
echo "Test the container:"
echo "  docker run -d -p 5000:5000 --name webapp-test webapp:v1"
echo "  curl http://localhost:5000"
echo "  docker logs webapp-test"
echo "  docker stop webapp-test"
echo "  docker rm webapp-test"