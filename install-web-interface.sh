#!/bin/bash

# MinecraftOS Web Interface Setup Script
# This script installs only the web interface component

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Web Interface Setup"
echo "====================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

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

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y curl wget git unzip zip openjdk-17-jre-headless nodejs npm ufw

# Configure firewall
echo "Configuring firewall..."
ufw allow ssh
ufw allow 8080/tcp # Web interface port
ufw allow 25565/tcp # Default Minecraft port
ufw --force enable

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
    "start": "next start -p 8080"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "lucide-react": "^0.292.0"
  },
  "devDependencies": {
    "@types/node": "^20.8.10",
    "@types/react": "^18.2.33",
    "@types/react-dom": "^18.2.14",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.3.5",
    "typescript": "^5.2.2"
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
import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'MinecraftOS',
  description: 'Minecraft Server Management System',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="bg-slate-950 text-white">
        <div className="min-h-screen">
          {children}
        </div>
      </body>
    </html>
  )
}
EOF

# app/globals.css
cat > ${WEB_DIR}/app/globals.css << EOF
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 255, 255, 255;
  --background-start-rgb: 0, 0, 0;
  --background-end-rgb: 0, 0, 0;
}

body {
  color: rgb(var(--foreground-rgb));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background-end-rgb))
    )
    rgb(var(--background-start-rgb));
}
EOF

# app/page.tsx
cat > ${WEB_DIR}/app/page.tsx << EOF
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-center font-mono text-sm">
        <h1 className="text-4xl font-bold text-center mb-8">MinecraftOS</h1>
        
        <div className="bg-slate-800 p-8 rounded-lg shadow-lg">
          <h2 className="text-2xl font-semibold mb-4">Welcome to MinecraftOS</h2>
          <p className="mb-4">Your Minecraft server management system is now installed.</p>
          <p className="mb-6">Use the buttons below to get started:</p>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <a href="/servers" className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3 px-4 rounded text-center">
              Manage Servers
            </a>
            <a href="/create" className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded text-center">
              Create New Server
            </a>
          </div>
        </div>
      </div>
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

# Create a .env file with environment variables
cat > ${WEB_DIR}/.env.local << EOF
SERVER_PATH=${MINECRAFT_DIR}
BACKUP_PATH=${BACKUPS_DIR}
SERVERS_PATH=${SERVERS_DIR}
DOWNLOADS_PATH=${DOWNLOADS_DIR}
CONFIG_PATH=${CONFIG_DIR}
EOF

# Install web interface dependencies
echo "Installing web interface dependencies..."
cd ${WEB_DIR}
npm install

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
Environment=PORT=8080
Environment=SERVER_PATH=${MINECRAFT_DIR}
Environment=BACKUP_PATH=${BACKUPS_DIR}
Environment=SERVERS_PATH=${SERVERS_DIR}
Environment=DOWNLOADS_PATH=${DOWNLOADS_DIR}
Environment=CONFIG_PATH=${CONFIG_DIR}
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the web interface
echo "Enabling and starting the web interface..."
systemctl daemon-reload
systemctl enable minecraft-web.service
systemctl start minecraft-web.service

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "====================================="
echo "MinecraftOS Web Interface Setup Complete!"
echo "====================================="
echo "Access the web interface at: http://${IP_ADDRESS}:8080"
echo "====================================="
