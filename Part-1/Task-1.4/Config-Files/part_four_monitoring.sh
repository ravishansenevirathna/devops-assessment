#!/bin/bash

# Create monitoring script
sudo tee /opt/webapp/monitor.sh > /dev/null << 'EOF'
#!/bin/bash
LOG="/opt/webapp/logs/monitor.log"
TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIME] === Check Started ===" >> "$LOG"

# Check webapp service
systemctl is-active --quiet webapp && echo "[$TIME] ✅ webapp: UP" >> "$LOG" || echo "[$TIME] ❌ webapp: DOWN" >> "$LOG"

# Check nginx
curl -s http://localhost > /dev/null && echo "[$TIME] ✅ nginx: UP" >> "$LOG" || echo "[$TIME] ❌ nginx: DOWN" >> "$LOG"

# System stats
echo "[$TIME] Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')" >> "$LOG"
echo "[$TIME] Disk: $(du -sh /opt/webapp/ | awk '{print $1}')" >> "$LOG"
echo "[$TIME] Load: $(uptime | awk -F'load average:' '{print $2}')" >> "$LOG"
echo "[$TIME] === Check Done ===" >> "$LOG"
echo "" >> "$LOG"
EOF

# Set permissions
sudo chown webapp:webapp /opt/webapp/monitor.sh
sudo chmod +x /opt/webapp/monitor.sh

# Test it
sudo -u webapp /opt/webapp/monitor.sh

# Add cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/webapp/monitor.sh") | crontab -

# Show results
echo "✅ Done!"
echo ""
echo "Cron job:"
crontab -l
echo ""
echo "Log output:"
tail -10 /opt/webapp/logs/monitor.log