#!/bin/bash

# connected-users.sh - Monitor and display connected users count
# Add this script to your scriptvps repository

# Create the web directory if it doesn't exist
mkdir -p /var/www/html

# Function to count SSH users
count_ssh_users() {
    who | wc -l
}

# Function to count OpenVPN users  
count_openvpn_users() {
    if [ -f /etc/openvpn/server/openvpn-status.log ]; then
        grep "^CLIENT_LIST" /etc/openvpn/server/openvpn-status.log | wc -l
    else
        echo "0"
    fi
}

# Function to count Dropbear users
count_dropbear_users() {
    ps aux | grep dropbear | grep -v grep | wc -l
}

# Function to count Stunnel users
count_stunnel_users() {
    netstat -tnlp | grep stunnel | wc -l
}

# Function to count XRAY users (active connections)
count_xray_users() {
    if command -v xray &> /dev/null; then
        netstat -tnlp | grep xray | wc -l
    else
        echo "0"
    fi
}

# Function to count Shadowsocks users
count_ss_users() {
    if pgrep ss-server &> /dev/null; then
        netstat -tnlp | grep ss-server | wc -l
    else
        echo "0"
    fi
}

# Function to count Wireguard users
count_wg_users() {
    if command -v wg &> /dev/null; then
        wg show | grep peer | wc -l
    else
        echo "0"
    fi
}

# Function to get total active connections
get_total_connections() {
    local ssh_users=$(count_ssh_users)
    local openvpn_users=$(count_openvpn_users) 
    local dropbear_users=$(count_dropbear_users)
    local stunnel_users=$(count_stunnel_users)
    local xray_users=$(count_xray_users)
    local ss_users=$(count_ss_users)
    local wg_users=$(count_wg_users)
    
    local total=$((ssh_users + openvpn_users + dropbear_users + stunnel_users + xray_users + ss_users + wg_users))
    echo $total
}

# Function to generate detailed JSON report
generate_json_report() {
    cat > /var/www/html/connected.json << EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "server_info": {
        "hostname": "$(hostname)",
        "uptime": "$(uptime -p)",
        "load_average": "$(uptime | awk -F'load average:' '{print $2}')"
    },
    "connections": {
        "total": $(get_total_connections),
        "breakdown": {
            "ssh": $(count_ssh_users),
            "openvpn": $(count_openvpn_users),
            "dropbear": $(count_dropbear_users),
            "stunnel": $(count_stunnel_users),
            "xray": $(count_xray_users),
            "shadowsocks": $(count_ss_users),
            "wireguard": $(count_wg_users)
        }
    }
}
EOF
}

# Function to generate simple text report
generate_text_report() {
    local total=$(get_total_connections)
    echo "$total" > /var/www/html/connected.txt
    
    # Generate detailed text report
    cat > /var/www/html/connected-detail.txt << EOF
=== CONNECTED USERS REPORT ===
Generated: $(date)
Total Connected Users: $total

Service Breakdown:
- SSH Users: $(count_ssh_users)
- OpenVPN Users: $(count_openvpn_users)
- Dropbear Users: $(count_dropbear_users)
- Stunnel Users: $(count_stunnel_users)
- XRAY Users: $(count_xray_users)
- Shadowsocks Users: $(count_ss_users)
- Wireguard Users: $(count_wg_users)

Server Info:
- Hostname: $(hostname)
- Uptime: $(uptime -p)
- Load Average: $(uptime | awk -F'load average:' '{print $2}')
EOF
}

# Function to generate HTML report
generate_html_report() {
    cat > /var/www/html/connected.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Connected Users - $(hostname)</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #333; color: white; padding: 10px; border-radius: 5px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 20px 0; }
        .stat-box { background: #f5f5f5; padding: 15px; border-radius: 5px; text-align: center; }
        .total { background: #4CAF50; color: white; font-size: 24px; }
        .service { background: #2196F3; color: white; }
        .timestamp { color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Connected Users Monitor</h1>
        <p>Server: $(hostname) | Last Updated: $(date)</p>
    </div>
    
    <div class="stats">
        <div class="stat-box total">
            <h2>Total Users</h2>
            <h1>$(get_total_connections)</h1>
        </div>
        <div class="stat-box service">
            <h3>SSH</h3>
            <h2>$(count_ssh_users)</h2>
        </div>
        <div class="stat-box service">
            <h3>OpenVPN</h3>
            <h2>$(count_openvpn_users)</h2>
        </div>
        <div class="stat-box service">
            <h3>Dropbear</h3>
            <h2>$(count_dropbear_users)</h2>
        </div>
        <div class="stat-box service">
            <h3>XRAY</h3>
            <h2>$(count_xray_users)</h2>
        </div>
        <div class="stat-box service">
            <h3>Shadowsocks</h3>
            <h2>$(count_ss_users)</h2>
        </div>
        <div class="stat-box service">
            <h3>Wireguard</h3>
            <h2>$(count_wg_users)</h2>
        </div>
    </div>
    
    <div class="timestamp">
        Auto-refresh every 30 seconds
    </div>
</body>
</html>
EOF
}

# Main execution
case "$1" in
    "json")
        generate_json_report
        echo "JSON report generated at /var/www/html/connected.json"
        ;;
    "html")
        generate_html_report
        echo "HTML report generated at /var/www/html/connected.html"
        ;;
    "detail")
        generate_text_report
        echo "Detailed report generated at /var/www/html/connected-detail.txt"
        ;;
    *)
        generate_text_report
        generate_json_report
        echo "Reports generated:"
        echo "- Simple count: /var/www/html/connected.txt"
        echo "- JSON format: /var/www/html/connected.json"
        echo "- Detailed text: /var/www/html/connected-detail.txt"
        ;;
esac