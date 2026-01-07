#!/bin/bash

echo "=== SYSTEM STATUS DOCUMENTATION ==="
echo "Generated: $(date)"
echo ""

echo "=== 1. Memory Usage (Free vs Used) ==="
free -h
echo ""

echo "=== 2. Disk Usage of /opt/webapp/ ==="
du -sh /opt/webapp/
du -h --max-depth=1 /opt/webapp/
echo ""

echo "=== 3. Number of Running Processes ==="
echo "Total processes: $(ps aux --no-headers | wc -l)"
echo ""

echo "=== 4. Current System Load ==="
uptime
echo ""

echo "=== 5. Top 5 Processes by Memory Usage ==="
ps aux --sort=-%mem | head -6
echo ""