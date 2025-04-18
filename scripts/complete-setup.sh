#!/bin/bash

# MinecraftOS Complete Setup Script
# This script installs and configures MinecraftOS with all components

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Complete Setup"
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

# Install base packages
echo "Installing base packages..."
apt-get update
apt-get install -y curl wget git unzip zip openjdk-17-jre-headless nginx nodejs npm ufw screen

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
    "start": "next start -p 8080"
  },
  "dependencies": {
    "@radix-ui/react-accordion": "^1.1.2",
    "@radix-ui/react-alert-dialog": "^1.0.5",
    "@radix-ui/react-avatar": "^1.0.4",
    "@radix-ui/react-checkbox": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "lucide-react": "^0.292.0",
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "tailwind-merge": "^2.0.0",
    "tailwindcss-animate": "^1.0.7",
    "bcrypt": "^5.1.1",
    "uuid": "^9.0.1"
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
mkdir -p ${WEB_DIR}/components/ui
mkdir -p ${WEB_DIR}/public
mkdir -p ${WEB_DIR}/lib
mkdir -p ${WEB_DIR}/app/api
mkdir -p ${WEB_DIR}/app/api/servers
mkdir -p ${WEB_DIR}/app/api/server
mkdir -p ${WEB_DIR}/app/api/system

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
'use client'

import { useState } from 'react'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { ServerList } from '@/components/server-list'
import { SetupWizard } from '@/components/setup-wizard'
import { NetworkSettings } from '@/components/network-settings'
import { SystemInfo } from '@/components/system-info'

export default function Home() {
  const [isFirstTimeSetup, setIsFirstTimeSetup] = useState(false)
  const [isSetupComplete, setIsSetupComplete] = useState(true)

  const handleSetupComplete = () => {
    setIsSetupComplete(true)
  }

  if (!isSetupComplete) {
    return <SetupWizard onComplete={handleSetupComplete} />
  }

  return (
    <main className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-emerald-500">MinecraftOS</h1>
        <div className="flex gap-2">
          <button className="bg-slate-800 hover:bg-slate-700 px-4 py-2 rounded-md text-sm">
            Settings
          </button>
          <button className="bg-emerald-600 hover:bg-emerald-500 px-4 py-2 rounded-md text-sm">
            Create New Server
          </button>
        </div>
      </div>

      <Tabs defaultValue="servers" className="w-full">
        <TabsList className="bg-slate-800 border-slate-700 mb-8">
          <TabsTrigger value="servers">Servers</TabsTrigger>
          <TabsTrigger value="network">Network</TabsTrigger>
          <TabsTrigger value="system">System</TabsTrigger>
        </TabsList>
        <TabsContent value="servers">
          <ServerList />
        </TabsContent>
        <TabsContent value="network">
          <NetworkSettings />
        </TabsContent>
        <TabsContent value="system">
          <SystemInfo />
        </TabsContent>
      </Tabs>
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
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(217.2 32.6% 17.5%)",
        input: "hsl(217.2 32.6% 17.5%)",
        ring: "hsl(224.3 76.3% 48%)",
        background: "hsl(222.2 84% 4.9%)",
        foreground: "hsl(210 40% 98%)",
        primary: {
          DEFAULT: "hsl(142.1 76.2% 36.3%)",
          foreground: "hsl(355.7 100% 97.3%)",
        },
        secondary: {
          DEFAULT: "hsl(217.2 32.6% 17.5%)",
          foreground: "hsl(210 40% 98%)",
        },
        destructive: {
          DEFAULT: "hsl(0 62.8% 30.6%)",
          foreground: "hsl(210 40% 98%)",
        },
        muted: {
          DEFAULT: "hsl(217.2 32.6% 17.5%)",
          foreground: "hsl(214.3 31.8% 91.4%)",
        },
        accent: {
          DEFAULT: "hsl(217.2 32.6% 17.5%)",
          foreground: "hsl(210 40% 98%)",
        },
        popover: {
          DEFAULT: "hsl(222.2 84% 4.9%)",
          foreground: "hsl(210 40% 98%)",
        },
        card: {
          DEFAULT: "hsl(222.2 84% 4.9%)",
          foreground: "hsl(210 40% 98%)",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
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

# Create lib/utils.ts
mkdir -p ${WEB_DIR}/lib
cat > ${WEB_DIR}/lib/utils.ts << EOF
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"
 
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

# Create a .env file with environment variables
cat > ${WEB_DIR}/.env.local << EOF
SERVER_PATH=${MINECRAFT_DIR}
SERVER_JAR=${MINECRAFT_DIR}/paper.jar
BACKUP_PATH=${BACKUPS_DIR}
SERVERS_PATH=${SERVERS_DIR}
DOWNLOADS_PATH=${DOWNLOADS_DIR}
CONFIG_PATH=${CONFIG_DIR}
EOF

# Create basic API routes
mkdir -p ${WEB_DIR}/app/api/servers
cat > ${WEB_DIR}/app/api/servers/route.ts << EOF
import { NextResponse } from "next/server"

export async function GET() {
  // In a real implementation, this would fetch servers from a database or file system
  return NextResponse.json({
    servers: [
      {
        id: "1",
        name: "Survival Server",
        type: "paper",
        version: "1.20.4",
        status: "online",
        port: "25565",
        players: {
          online: 0,
          max: 20,
        },
        memory: {
          used: 0,
          allocated: 2048,
        },
        uptime: "0h 0m",
      }
    ],
  })
}

export async function POST(request: Request) {
  try {
    const data = await request.json()

    // In a real implementation, this would create a new server
    console.log("Creating new server with config:", data)

    // Generate a new server ID
    const newServerId = Math.floor(Math.random() * 1000).toString()

    return NextResponse.json({
      success: true,
      message: "Server created successfully",
      server: {
        id: newServerId,
        name: data.serverName,
        type: data.serverType,
        version: data.serverVersion,
        status: "offline",
        port: data.port,
        players: {
          online: 0,
          max: 20,
        },
        memory: {
          used: 0,
          allocated: Number.parseInt(data.memory),
        },
        uptime: "0h 0m",
      },
    })
  } catch (error) {
    console.error("Error creating server:", error)
    return NextResponse.json({ error: "Failed to create server" }, { status: 500 })
  }
}
EOF

# Install web interface dependencies
echo "Installing web interface dependencies..."
cd ${WEB_DIR}
npm install

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
echo "MinecraftOS Setup Complete!"
echo "====================================="
echo "System will now reboot in 10 seconds..."
echo "After reboot, access the web interface at http://$HOSTNAME:8080"
echo "====================================="

# Schedule a reboot
(sleep 10 && reboot) &
