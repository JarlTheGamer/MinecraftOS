#!/bin/bash

# MinecraftOS Setup Script (Standalone Version)
# This script configures a minimal Linux installation to become MinecraftOS
# without relying on external downloads from GitHub

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Setup (Standalone)"
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
      <head>
        <title>MinecraftOS</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      </head>
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
      <div className="mt-8">
        <a href="/dashboard" className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600">
          Go to Dashboard
        </a>
      </div>
    </main>
  )
}
EOF

# app/dashboard/page.tsx
mkdir -p ${WEB_DIR}/app/dashboard
cat > ${WEB_DIR}/app/dashboard/page.tsx << EOF
export default function Dashboard() {
  return (
    <div className="p-4">
      <h1 className="text-2xl font-bold mb-4">Minecraft Server Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="border p-4 rounded">
          <h2 className="text-xl font-semibold mb-2">Server Status</h2>
          <p>Status: Offline</p>
          <button className="mt-2 px-3 py-1 bg-green-500 text-white rounded">Start Server</button>
        </div>
        <div className="border p-4 rounded">
          <h2 className="text-xl font-semibold mb-2">Server Info</h2>
          <p>Version: Paper 1.20.4</p>
          <p>Players: 0/20</p>
        </div>
      </div>
    </div>
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

# Create globals.css
mkdir -p ${WEB_DIR}/app
cat > ${WEB_DIR}/app/globals.css << EOF
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 0, 0, 0;
  --background-rgb: 255, 255, 255;
}

body {
  color: rgb(var(--foreground-rgb));
  background: rgb(var(--background-rgb));
}
EOF

# Create tailwind.config.js
cat > ${WEB_DIR}/tailwind.config.js << EOF
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Create postcss.config.js
cat > ${WEB_DIR}/postcss.config.js << EOF
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# Install web interface dependencies
echo "Installing web interface dependencies..."
cd ${WEB_DIR}
npm install
npm install --save-dev tailwindcss postcss autoprefixer
npx tailwindcss init -p

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
echo "You can access the web interface at http://$HOSTNAME:8080"
echo "====================================="

# Schedule a reboot
echo "System will now reboot in 10 seconds..."
(sleep 10 && reboot) &
