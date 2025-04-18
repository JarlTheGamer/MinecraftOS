#!/bin/bash

# This script installs MinecraftOS and its dependencies.
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

  # Create .gitignore
  cat > ${WEB_DIR}/.gitignore << EOF
# See https://help.github.com/articles/ignoring-files/ for more about ignoring files.

# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
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

# Copy scripts to scripts directory
echo "Setting up scripts..."
if [ -d "${WEB_DIR}/scripts" ]; then
  cp -r ${WEB_DIR}/scripts/* ${SCRIPTS_DIR}/
else
  # Create basic scripts if they don't exist
  cat > ${SCRIPTS_DIR}/backup.sh << EOF
#!/bin/bash
# Basic backup script
TIMESTAMP=\$(date +"%Y%m%d-%H%M%S")
tar -czf ${BACKUPS_DIR}/minecraft-backup-\${TIMESTAMP}.tar.gz -C ${MINECRAFT_DIR} world
echo "Backup created at ${BACKUPS_DIR}/minecraft-backup-\${TIMESTAMP}.tar.gz"
EOF
  chmod +x ${SCRIPTS_DIR}/backup.sh
  
  cat > ${SCRIPTS_DIR}/autostart.sh << EOF
#!/bin/bash
# Auto-start script for Minecraft servers
for SERVER_DIR in ${SERVERS_DIR}/*; do
  if [ -d "\${SERVER_DIR}" ]; then
    if [ -f "\${SERVER_DIR}/server.json" ]; then
      AUTO_START=\$(grep -o '"autoStart":[^,}]*' "\${SERVER_DIR}/server.json" | cut -d ':' -f2 | tr -d ' ')
      if [ "\${AUTO_START}" = "true" ]; then
        echo "Starting server in \${SERVER_DIR}"
        cd "\${SERVER_DIR}"
        screen -dmS minecraft-\$(basename "\${SERVER_DIR}") java -jar server.jar nogui
      fi
    fi
  fi
done
EOF
  chmod +x ${SCRIPTS_DIR}/autostart.sh
fi

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
echo "You can access the web interface at http://localhost:3000"
echo "====================================="
