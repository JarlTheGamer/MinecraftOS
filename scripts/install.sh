#!/bin/bash

# MinecraftOS Installation Script
# This script installs the MinecraftOS system on a fresh Linux installation

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Installation"
echo "====================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get install -y curl wget git unzip zip openjdk-17-jre-headless nginx nodejs npm

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/minecraft/servers
mkdir -p /opt/minecraft/backups
mkdir -p /opt/minecraft/downloads
mkdir -p /opt/minecraft/web

# Set up web server
echo "Setting up web server..."
cat > /etc/nginx/sites-available/minecraft << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/minecraft /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Clone the MinecraftOS web interface
echo "Setting up MinecraftOS web interface..."
cd /opt/minecraft/web
git clone https://github.com/minecraft-os/web-interface.git .
npm install
npm run build

# Create systemd service for web interface
cat > /etc/systemd/system/minecraft-web.service << EOF
[Unit]
Description=MinecraftOS Web Interface
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minecraft/web
ExecStart=/usr/bin/npm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for auto-start
cat > /etc/systemd/system/minecraft-autostart.service << EOF
[Unit]
Description=MinecraftOS Auto-Start Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minecraft
ExecStart=/opt/minecraft/scripts/autostart.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create auto-start script
mkdir -p /opt/minecraft/scripts
cat > /opt/minecraft/scripts/autostart.sh << EOF
#!/bin/bash
# This script starts all Minecraft servers marked for auto-start

for SERVER_DIR in /opt/minecraft/servers/*/; do
  CONFIG_FILE="\${SERVER_DIR}server.json"
  if [ -f "\$CONFIG_FILE" ]; then
    AUTO_START=\$(grep -o '"autoStart":[^,}]*' "\$CONFIG_FILE" | grep -o 'true\|false')
    if [ "\$AUTO_START" = "true" ]; then
      SERVER_ID=\$(basename "\$SERVER_DIR")
      echo "Auto-starting server \$SERVER_ID"
      /opt/minecraft/scripts/start-server.sh "\$SERVER_ID"
    fi
  fi
done
EOF

# Create server management scripts
cat > /opt/minecraft/scripts/start-server.sh << EOF
#!/bin/bash
# Start a Minecraft server

SERVER_ID="\$1"
if [ -z "\$SERVER_ID" ]; then
  echo "Usage: \$0 <server_id>"
  exit 1
fi

SERVER_DIR="/opt/minecraft/servers/\$SERVER_ID"
CONFIG_FILE="\${SERVER_DIR}/server.json"

if [ ! -f "\$CONFIG_FILE" ]; then
  echo "Server configuration not found"
  exit 1
fi

MEMORY=\$(grep -o '"memory":[^,}]*' "\$CONFIG_FILE" | grep -o '[0-9]*')
JAR_FILE=\$(grep -o '"jarFile":"[^"]*"' "\$CONFIG_FILE" | cut -d'"' -f4)

cd "\$SERVER_DIR"
nohup java -Xmx\${MEMORY}M -Xms\$((\$MEMORY / 2))M -jar "\$JAR_FILE" nogui > logs/latest.log 2>&1 &
echo \$! > server.pid
echo "Server \$SERVER_ID started"
EOF

# Make scripts executable
chmod +x /opt/minecraft/scripts/*.sh

# Enable services
systemctl enable minecraft-web
systemctl enable minecraft-autostart

# Start services
systemctl start minecraft-web

echo "====================================="
echo "MinecraftOS Installation Complete!"
echo "====================================="
echo "Access the web interface at http://your-server-ip"
echo "Default login: admin / minecraft"
echo "====================================="
