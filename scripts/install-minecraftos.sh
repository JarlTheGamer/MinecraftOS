#!/bin/bash

# MinecraftOS Installation Script
# This script installs MinecraftOS on a fresh Linux installation

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

# Detect Linux distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "Cannot detect Linux distribution"
  exit 1
fi

echo "Detected Linux distribution: $DISTRO"

# Install dependencies based on distribution
echo "Installing dependencies..."
case $DISTRO in
  ubuntu|debian)
    apt-get update
    apt-get install -y curl wget git unzip zip nodejs npm nginx ufw openjdk-17-jre-headless screen htop
    ;;
  fedora|centos|rhel)
    dnf install -y curl wget git unzip zip nodejs npm nginx firewalld java-17-openjdk-headless screen htop
    ;;
  arch)
    pacman -Sy --noconfirm curl wget git unzip zip nodejs npm nginx ufw jre17-openjdk screen htop
    ;;
  *)
    echo "Unsupported distribution: $DISTRO"
    echo "Please install the following packages manually:"
    echo "- curl, wget, git, unzip, zip"
    echo "- nodejs, npm"
    echo "- nginx"
    echo "- firewall (ufw or firewalld)"
    echo "- Java 17 JRE"
    echo "- screen, htop"
    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
    ;;
esac

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/minecraft/servers
mkdir -p /opt/minecraft/backups
mkdir -p /opt/minecraft/downloads
mkdir -p /opt/minecraft/config
mkdir -p /opt/minecraft/scripts
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

# Enable site configuration
if [ -d /etc/nginx/sites-enabled ]; then
  ln -sf /etc/nginx/sites-available/minecraft /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
else
  # For distributions that don't use sites-enabled
  mv /etc/nginx/sites-available/minecraft /etc/nginx/conf.d/minecraft.conf
fi

# Restart nginx
systemctl restart nginx

# Clone the MinecraftOS web interface
echo "Setting up MinecraftOS web interface..."
cd /opt/minecraft/web
git clone https://github.com/minecraft-os/web-interface.git . || {
  echo "GitHub repository not available, creating placeholder web interface"
  mkdir -p /opt/minecraft/web
  cat > /opt/minecraft/web/package.json << EOF
{
  "name": "minecraft-os",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^13.4.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOF
}

# Install dependencies and build
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

# Create a screen session for the server
screen -dmS "minecraft-\$SERVER_ID" bash -c "java -Xmx\${MEMORY}M -Xms\$((\$MEMORY / 2))M -jar \$JAR_FILE nogui"

# Save the PID
PID=\$(screen -ls | grep "minecraft-\$SERVER_ID" | grep -o '[0-9]*')
echo \$PID > server.pid
echo "Server \$SERVER_ID started with PID \$PID"
EOF

# Create stop server script
cat > /opt/minecraft/scripts/stop-server.sh << EOF
#!/bin/bash
# Stop a Minecraft server

SERVER_ID="\$1"
if [ -z "\$SERVER_ID" ]; then
  echo "Usage: \$0 <server_id>"
  exit 1
fi

SERVER_DIR="/opt/minecraft/servers/\$SERVER_ID"
PID_FILE="\${SERVER_DIR}/server.pid"

if [ ! -f "\$PID_FILE" ]; then
  echo "Server is not running"
  exit 1
fi

SCREEN_NAME="minecraft-\$SERVER_ID"

# Send stop command to the server
screen -S "\$SCREEN_NAME" -p 0 -X stuff "stop$(printf '\r')"

# Wait for server to stop (max 30 seconds)
for i in {1..30}; do
  if ! screen -list | grep -q "\$SCREEN_NAME"; then
    echo "Server stopped"
    rm -f "\$PID_FILE"
    exit 0
  fi
  sleep 1
done

# If server didn't stop gracefully, kill the screen session
screen -S "\$SCREEN_NAME" -X quit
rm -f "\$PID_FILE"
echo "Server \$SERVER_ID stopped forcefully"
EOF

# Create backup script
cat > /opt/minecraft/scripts/backup.sh << EOF
#!/bin/bash
# Backup Minecraft servers

BACKUP_DIR="/opt/minecraft/backups"
DATE=\$(date +%Y-%m-%d_%H-%M-%S)

# Create backup directory if it doesn't exist
mkdir -p "\$BACKUP_DIR"

# Backup each server
for SERVER_DIR in /opt/minecraft/servers/*/; do
  SERVER_ID=\$(basename "\$SERVER_DIR")
  
  # Skip if server doesn't have a world directory
  if [ ! -d "\${SERVER_DIR}world" ]; then
    continue
  fi
  
  BACKUP_FILE="\$BACKUP_DIR/\$SERVER_ID-\$DATE.zip"
  
  echo "Backing up server \$SERVER_ID to \$BACKUP_FILE"
  
  # Create backup
  cd "\$SERVER_DIR"
  zip -r "\$BACKUP_FILE" world world_nether world_the_end
done

# Clean up old backups (keep last 10)
cd "\$BACKUP_DIR"
ls -t | grep -v "latest" | tail -n +11 | xargs -r rm
EOF

# Create remote access script
cat > /opt/minecraft/scripts/remote-access.sh << EOF
#!/bin/bash
# Remote access service for MinecraftOS

CONFIG_FILE="/opt/minecraft/config/remote-access.json"

if [ ! -f "\$CONFIG_FILE" ]; then
  echo "Remote access configuration not found"
  exit 1
fi

PORT=\$(grep -o '"port":[^,}]*' "\$CONFIG_FILE" | grep -o '[0-9]*')
PIN=\$(grep -o '"pin":"[^"]*"' "\$CONFIG_FILE" | cut -d'"' -f4)

if [ -z "\$PORT" ] || [ -z "\$PIN" ]; then
  echo "Invalid remote access configuration"
  exit 1
fi

# Start a simple web server for remote access
cd /opt/minecraft/web
node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const pin = url.searchParams.get('pin');
  
  if (pin === '\$PIN') {
    // Authenticated
    if (req.method === 'POST' && url.pathname === '/api/command') {
      let body = '';
      req.on('data', chunk => {
        body += chunk.toString();
      });
      req.on('end', () => {
        try {
          const data = JSON.parse(body);
          if (data.command) {
            exec(data.command, (error, stdout, stderr) => {
              res.writeHead(200, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ 
                success: !error, 
                output: stdout, 
                error: stderr 
              }));
            });
          } else {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'No command provided' }));
          }
        } catch (e) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid JSON' }));
        }
      });
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: 'Authenticated' }));
    }
  } else {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Invalid PIN' }));
  }
});

server.listen(\$PORT, () => {
  console.log('Remote access server listening on port \$PORT');
});
"
EOF

# Make scripts executable
chmod +x /opt/minecraft/scripts/*.sh

# Enable services
systemctl enable minecraft-web
systemctl enable minecraft-autostart

# Start web service
systemctl start minecraft-web

# Configure firewall
echo "Configuring firewall..."
if command -v ufw &> /dev/null; then
  ufw allow ssh
  ufw allow http
  ufw allow https
  ufw allow 25565/tcp # Minecraft default port
  ufw allow 8080/tcp # Admin panel
  ufw allow 8192/tcp # Remote access
  ufw --force enable
elif command -v firewall-cmd &> /dev/null; then
  firewall-cmd --permanent --add-service=ssh
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --permanent --add-port=25565/tcp # Minecraft default port
  firewall-cmd --permanent --add-port=8080/tcp # Admin panel
  firewall-cmd --permanent --add-port=8192/tcp # Remote access
  firewall-cmd --reload
else
  echo "No firewall detected. Please configure your firewall manually."
fi

# Create default configuration
echo "Creating default configuration..."
cat > /opt/minecraft/config/system.json << EOF
{
  "hostname": "minecraft-server",
  "timezone": "UTC",
  "adminPort": "8080",
  "networkConfig": "dhcp",
  "enableFirewall": true,
  "installJava": true,
  "javaVersion": "17",
  "autoStart": true,
  "backupEnabled": true,
  "backupInterval": "daily",
  "enableRemoteAccess": true,
  "remotePort": "8192",
  "setupDate": "$(date -Iseconds)"
}
EOF

# Create default user
echo "Creating default user..."
cat > /opt/minecraft/config/users.json << EOF
{
  "users": [
    {
      "username": "admin",
      "password": "\$(echo -n 'minecraft' | sha256sum | awk '{print $1}')",
      "role": "admin",
      "created": "$(date -Iseconds)"
    }
  ]
}
EOF

echo "====================================="
echo "MinecraftOS Installation Complete!"
echo "====================================="
echo "Access the web interface at http://your-server-ip:8080"
echo "Default login: admin / minecraft"
echo "====================================="
echo "For security, please change the default password after logging in."
echo "====================================="

# Ask if user wants to reboot
read -p "Do you want to reboot now? (recommended) [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reboot
fi
