#!/bin/bash

# setup-connected-monitor.sh
# Setup script to integrate connected users monitoring into your VPS script

echo "Setting up Connected Users Monitor..."

# Create necessary directories
mkdir -p /var/www/html
mkdir -p /usr/local/bin

# Download the connected users script
wget -O /usr/local/bin/connected-users.sh "https://raw.githubusercontent.com/senowahyu62/scriptvps/main/connected-users.sh"
chmod +x /usr/local/bin/connected-users.sh

# Configure Nginx to serve the files (if not already configured)
if [ -f /etc/nginx/sites-available/default ]; then
    # Backup original config
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    
    # Add location block for connected users if not exists
    if ! grep -q "location /connected" /etc/nginx/sites-available/default; then
        sed -i '/location \/ {/a\\n\t# Connected users monitoring\n\tlocation /connected.txt {\n\t\troot /var/www/html;\n\t\texpires 30s;\n\t\tadd_header Cache-Control "public, no-cache";\n\t}\n\n\tlocation /connected.json {\n\t\troot /var/www/html;\n\t\texpires 30s;\n\t\tadd_header Cache-Control "public, no-cache";\n\t\tadd_header Content-Type "application/json";\n\t}\n\n\tlocation /connected.html {\n\t\troot /var/www/html;\n\t\texpires 30s;\n\t\tadd_header Cache-Control "public, no-cache";\n\t}' /etc/nginx/sites-available/default
        
        # Restart nginx
        systemctl reload nginx
    fi
fi

# Create systemd service for continuous monitoring
cat > /etc/systemd/system/connected-monitor.service << EOF
[Unit]
Description=Connected Users Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/connected-users.sh
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer for regular updates
cat > /etc/systemd/system/connected-monitor.timer << EOF
[Unit]
Description=Update Connected Users Count
Requires=connected-monitor.service

[Timer]
OnBootSec=30sec
OnUnitActiveSec=30sec
AccuracySec=1sec

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
systemctl daemon-reload
systemctl enable connected-monitor.timer
systemctl start connected-monitor.timer

# Add cron job as backup (every minute)
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/connected-users.sh >/dev/null 2>&1") | crontab -

# Initial run to create files
/usr/local/bin/connected-users.sh
/usr/local/bin/connected-users.sh html

echo "==================================="
echo "Connected Users Monitor Setup Complete!"
echo "==================================="
echo ""
echo "Access URLs:"
echo "- Simple count: http://YOUR_IP/connected.txt"
echo "- JSON format: http://YOUR_IP/connected.json" 
echo "- HTML dashboard: http://YOUR_IP/connected.html"
echo "- Detailed report: http://YOUR_IP/connected-detail.txt"
echo ""
echo "The counter updates every 30 seconds automatically."
echo ""
echo "Service Status:"
systemctl status connected-monitor.timer --no-pager -l
echo ""
echo "Test the endpoints:"
echo "curl http://$(curl -s ipinfo.io/ip)/connected.txt"