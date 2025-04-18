#!/bin/bash

# Set up MinecraftOS
set -e

echo "====================================="
echo "MinecraftOS Setup"
echo "====================================="

# Update and install necessary packages
echo "Updating and installing necessary packages..."
apt update
apt install -y git nodejs npm screen openjdk-17-jre-headless

# Create Minecraft directory structure
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

# Set up Minecraft server
echo "Setting up Minecraft server..."
cd ${MINECRAFT_DIR}
wget https://launcher.mojang.com/v1/objects/125e5adf40c7e8423cb80a72958253a2e48d3b11/server.jar -O server.jar
echo "eula=true" > eula.txt

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
SERVER_JAR=${MINECRAFT_DIR}/server.jar
BACKUP_PATH=${BACKUPS_DIR}
SERVERS_PATH=${SERVERS_DIR}
DOWNLOADS_PATH=${DOWNLOADS_DIR}
CONFIG_PATH=${CONFIG_DIR}
EOF

# Build web interface
echo "Building web interface..."
cd ${WEB_DIR}
npm run build

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
Environment=SERVER_JAR=${MINECRAFT_DIR}/server.jar
Environment=BACKUP_PATH=${BACKUPS_DIR}
Environment=SERVERS_PATH=${SERVERS_DIR}
Environment=DOWNLOADS_PATH=${DOWNLOADS_DIR}
Environment=CONFIG_PATH=${CONFIG_DIR}
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start the Minecraft server in a screen session
echo "Starting the Minecraft server..."
cd ${MINECRAFT_DIR}
screen -dmS minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui

# Enable and start the web interface
echo "Enabling and starting the web interface..."
systemctl daemon-reload
systemctl enable minecraft-web.service
systemctl start minecraft-web.service

echo "====================================="
echo "MinecraftOS setup complete!"
echo "====================================="
echo "You can access the web interface at http://localhost:3000"
echo "====================================="
