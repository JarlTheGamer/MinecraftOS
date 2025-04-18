#!/bin/bash

# MinecraftOS Setup Script
# This script configures a minimal Linux installation to become MinecraftOS

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Setup"
echo "====================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Set hostname
read -p "Enter hostname [minecraft-server]: " HOSTNAME
HOSTNAME=${HOSTNAME:-minecraft-server}
hostnamectl set-hostname $HOSTNAME

# Configure network
echo "Network Configuration"
echo "1) DHCP (automatic)"
echo "2) Static IP"
read -p "Select option [1]: " NETWORK_OPTION
NETWORK_OPTION=${NETWORK_OPTION:-1}

if [ "$NETWORK_OPTION" = "2" ]; then
  read -p "Enter IP address: " IP_ADDRESS
  read -p "Enter subnet mask [255.255.255.0]: " SUBNET_MASK
  SUBNET_MASK=${SUBNET_MASK:-255.255.255.0}
  read -p "Enter gateway: " GATEWAY
  read -p "Enter DNS server [8.8.8.8]: " DNS
  DNS=${DNS:-8.8.8.8}
  
  # Configure network with static IP
  cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address $IP_ADDRESS
  netmask $SUBNET_MASK
  gateway $GATEWAY
  dns-nameservers $DNS
EOF
  
  # Restart networking
  systemctl restart networking
fi

# Install base packages
echo "Installing base packages..."
apt-get update
apt-get install -y curl wget git unzip zip openjdk-17-jre-headless nginx nodejs npm ufw

# Configure firewall
echo "Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 25565/tcp # Minecraft default port
ufw allow 8080/tcp # Web interface port
ufw allow 8192/tcp # Remote access port
ufw --force enable

# Set up automatic updates
echo "Configuring automatic updates..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
  "\${distro_id}:\${distro_codename}";
  "\${distro_id}:\${distro_codename}-security";
  "\${distro_id}:\${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Run the main installation script
echo "Running main installation script..."
curl -s https://raw.githubusercontent.com/JarlTheGamer/MinecraftOS/main/scripts/install.sh | bash || {
  echo "Failed to download from GitHub. Using fallback installation method..."
  # Create a basic install script locally
  cat > /tmp/install.sh << 'EOFSCRIPT'
#!/bin/bash
# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Installation"
echo "====================================="

# Update package lists
echo "Updating package lists..."
apt update

# Install required packages
echo "Installing required packages..."
apt install -y git screen unzip openjdk-17-jre-headless nodejs npm

# Create base directories
echo "Creating directory structure..."
MINECRAFT_DIR="/opt/minecraft"
WEB_DIR="${MINECRAFT_DIR}/web"
SERVERS_DIR="${MINECRAFT_DIR}/servers"
DOWNLOADS_DIR="${MINECRAFT_DIR}/downloads"
BACKUPS_DIR="${MINECRAFT_DIR}/backups"
CONFIG_DIR="${MINECRAFT_DIR}/config"
LOGS_DIR="${MINECRAFT_DIR}/logs"
SCRIPTS_DIR="${MINECRAFT_DIR}/scripts"

mkdir -p ${MINECRAFT_DIR}
mkdir -p ${WEB_DIR}
mkdir -p ${SERVERS_DIR}
mkdir -p ${DOWNLOADS_DIR}
mkdir -p ${BACKUPS_DIR}
mkdir -p ${CONFIG_DIR}
mkdir -p ${LOGS_DIR}
mkdir -p ${SCRIPTS_DIR}

# Download and install Paperclip (Paper fork)
echo "Downloading and installing Paperclip..."
cd ${MINECRAFT_DIR}
wget -q https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/809/downloads/paper-1.20.4-809.jar -O paper.jar

# Create server.properties file
echo "Creating server.properties file..."
cat > ${MINECRAFT_DIR}/server.properties << EOF
#Minecraft server properties
#Generated $(date)
enable-jmx-monitoring=false
rcon.port=25575
level-seed=
gamemode=survival
enable-command-block=false
enable-query=false
generator-settings={}
enforce-secure-profile=true
level-name=world
motd=A MinecraftOS Server
query.port=25565
pvp=true
generate-structures=true
max-chained-neighbor-updates=1000000
difficulty=easy
network-compression-threshold=256
max-tick-time=60000
require-resource-pack=false
use-native-transport=true
max-players=20
online-mode=true
enable-status=true
allow-flight=false
broadcast-rcon-to-ops=true
view-distance=10
server-ip=
resource-pack-prompt=
allow-nether=true
server-port=25565
enable-rcon=false
sync-chunk-writes=true
op-permission-level=4
prevent-proxy-connections=false
hide-online-players=false
resource-pack=
entity-broadcast-range-percentage=100
simulation-distance=10
rcon.password=
player-idle-timeout=0
force-gamemode=false
rate-limit=0
hardcore=false
white-list=false
broadcast-console-to-ops=true
spawn-npcs=true
spawn-animals=true
snooper-enabled=true
resource-pack-sha1=
level-type=default
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
max-world-size=29999984
EOF

# Create eula.txt file
echo "Creating eula.txt file..."
echo "eula=true" > ${MINECRAFT_DIR}/eula.txt

# Create start.sh script
echo "Creating start.sh script..."
cat > ${MINECRAFT_DIR}/start.sh << EOF
#!/bin/bash
while true; do
  java -Xms2G -Xmx4G -jar paper.jar nogui
  echo "Server crashed. Restarting in 5 seconds..."
  sleep 5
done
EOF
chmod +x ${MINECRAFT_DIR}/start.sh

# Set up the web interface
echo "Setting up MinecraftOS web interface..."
cd ${WEB_DIR}

# Try to clone the repository, if it fails, create a basic Next.js app structure
if ! git clone https://github.com/JarlTheGamer/MinecraftOS.git .; then
  echo "GitHub repository not available, creating a basic Next.js app structure"
  
  # Create package.json
  cat > ${WEB_DIR}/package.json << EOF
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
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "bcrypt": "^5.1.1",
    "uuid": "^9.0.1"
  }
}
EOF

  # Create Next.js app directory structure
  mkdir -p ${WEB_DIR}/app
  mkdir -p ${WEB_DIR}/components
  mkdir -p ${WEB_DIR}/public
  mkdir -p ${WEB_DIR}/lib
  mkdir -p ${WEB_DIR}/app/api

  # Create basic Next.js files
  # app/layout.tsx
  cat > ${WEB_DIR}/app/layout.tsx << EOF
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
EOF

  # app/page.tsx
  cat > ${WEB_DIR}/app/page.tsx << EOF
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">MinecraftOS</h1>
      <p className="mt-4">Your Minecraft server management system</p>
    </main>
  )
}
EOF

  # Create next.config.js
  cat > ${WEB_DIR}/next.config.js << EOF
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
}

module.exports = nextConfig
EOF

  # Create tsconfig.json
  cat > ${WEB_DIR}/tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
fi

# Install web interface dependencies
echo "Installing web interface dependencies..."
cd ${WEB_DIR}
npm install

# Create a .env file with environment variables
cat > ${WEB_DIR}/.env.local << EOF
SERVER_PATH=${MINECRAFT_DIR}
SERVER_JAR=${MINECRAFT_DIR}/paper.jar
BACKUP_PATH=${BACKUPS_DIR}
SERVERS_PATH=${SERVERS_DIR}
DOWNLOADS_PATH=${DOWNLOADS_DIR}
CONFIG_PATH=${CONFIG_DIR}
EOF

# Build web interface
echo "Building web interface..."
cd ${WEB_DIR}
npm run build

# Create systemd service file for Minecraft server
echo "Creating Minecraft server systemd service file..."
cat > /etc/systemd/system/minecraft.service << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=${MINECRAFT_DIR}
User=root
Group=root
Restart=always
ExecStart=${MINECRAFT_DIR}/start.sh

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service file for web interface
echo "Creating web interface systemd service file..."
cat > /etc/systemd/system/minecraft-web.service << EOF
[Unit]
Description=MinecraftOS Web Interface
After=network.target

[Service]
WorkingDirectory=${WEB_DIR}
User=root
Group=root
Environment=NODE_ENV=production
Environment=PORT=8080
Environment=SERVER_PATH=${MINECRAFT_DIR}
Environment=SERVER_JAR=${MINECRAFT_DIR}/paper.jar
Environment=BACKUP_PATH=${BACKUPS_DIR}
Environment=SERVERS_PATH=${SERVERS_DIR}
Environment=DOWNLOADS_PATH=${DOWNLOADS_DIR}
Environment=CONFIG_PATH=${CONFIG_DIR}
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Minecraft server
echo "Enabling and starting the Minecraft server..."
systemctl daemon-reload
systemctl enable minecraft.service
systemctl start minecraft.service

# Enable and start the web interface
echo "Enabling and starting the web interface..."
systemctl enable minecraft-web.service
systemctl start minecraft-web.service

echo "====================================="
echo "MinecraftOS installation complete!"
echo "====================================="
echo "You can access the web interface at http://localhost:8080"
echo "====================================="
EOFSCRIPT

  # Make the script executable and run it
  chmod +x /tmp/install.sh
  bash /tmp/install.sh
}

echo "====================================="
echo "MinecraftOS Setup Complete!"
echo "====================================="
echo "System will now reboot in 10 seconds..."
echo "After reboot, access the web interface at http://$HOSTNAME:8080"
echo "====================================="

# Schedule a reboot
(sleep 10 && reboot) &
