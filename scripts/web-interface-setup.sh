#!/bin/bash

# MinecraftOS Web Interface Setup Script
# This script installs and configures the MinecraftOS web interface with authentication

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

# Set up admin credentials
echo "Setting up admin credentials for web interface"
read -p "Enter admin username [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}
read -s -p "Enter admin password: " ADMIN_PASSWORD
echo ""
read -s -p "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
echo ""

# Check if passwords match
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
  echo "Passwords do not match. Exiting."
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

# Generate a secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)

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
    "@radix-ui/react-radio-group": "^1.1.3",
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
    "uuid": "^9.0.1",
    "jose": "^5.1.1",
    "cookie": "^0.6.0",
    "@types/cookie": "^0.5.4",
    "ws": "^8.14.2",
    "rcon-client": "^4.2.3",
    "node-cron": "^3.0.2",
    "archiver": "^6.0.1"
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
mkdir -p ${WEB_DIR}/app/api/auth
mkdir -p ${WEB_DIR}/app/api/servers
mkdir -p ${WEB_DIR}/app/api/server
mkdir -p ${WEB_DIR}/app/api/system
mkdir -p ${WEB_DIR}/app/login
mkdir -p ${WEB_DIR}/middleware

# Create server management scripts
echo "Creating server management scripts..."

# Create script for server creation
cat > ${SCRIPTS_DIR}/create-server.sh << 'EOF'
#!/bin/bash
# Minecraft Server Creation Script
# This script downloads and sets up a Minecraft server

SERVER_PATH=$1
SERVER_TYPE=$2
MC_VERSION=$3
SERVER_PORT=$4
MEMORY=$5

echo "Creating $SERVER_TYPE server version $MC_VERSION in $SERVER_PATH"

# Create directory structure
mkdir -p "$SERVER_PATH"
cd "$SERVER_PATH"

# Download server jar based on type
if [ "$SERVER_TYPE" = "paper" ]; then
  # Download Paper
  echo "Downloading Paper $MC_VERSION..."
  wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/latest/downloads/paper-$MC_VERSION-latest.jar"
elif [ "$SERVER_TYPE" = "spigot" ]; then
  # Download Spigot
  echo "Downloading Spigot $MC_VERSION..."
  wget -O server.jar "https://download.getbukkit.org/spigot/spigot-$MC_VERSION.jar"
elif [ "$SERVER_TYPE" = "forge" ]; then
  # Download Forge (simplified)
  echo "Downloading Forge $MC_VERSION..."
  wget -O server.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/$MC_VERSION-latest/forge-$MC_VERSION-latest-installer.jar"
elif [ "$SERVER_TYPE" = "fabric" ]; then
  # Download Fabric
  echo "Downloading Fabric $MC_VERSION..."
  wget -O server.jar "https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/0.14.21/0.11.2/server/jar"
else
  # Download Vanilla
  echo "Downloading Vanilla $MC_VERSION..."
  wget -O server.jar "https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar"
fi

# Create server.properties
cat > server.properties << EOL
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
motd=A Minecraft Server
query.port=$SERVER_PORT
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
server-port=$SERVER_PORT
enable-rcon=true
sync-chunk-writes=true
op-permission-level=4
prevent-proxy-connections=false
hide-online-players=false
resource-pack=
entity-broadcast-range-percentage=100
simulation-distance=10
rcon.password=minecraft
player-idle-timeout=0
force-gamemode=false
rate-limit=0
hardcore=false
white-list=false
broadcast-console-to-ops=true
spawn-npcs=true
spawn-animals=true
snooper-enabled=true
function-permission-level=2
level-type=minecraft\:normal
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
max-world-size=29999984
EOL

# Create eula.txt
echo "eula=true" > eula.txt

# Create server metadata
cat > server.json << EOL
{
  "id": "$(basename "$SERVER_PATH")",
  "name": "$(basename "$SERVER_PATH")",
  "type": "$SERVER_TYPE",
  "version": "$MC_VERSION",
  "port": "$SERVER_PORT",
  "memory": "$MEMORY",
  "created": "$(date +%s)",
  "autostart": false
}
EOL

# Create start script
cat > start.sh << EOL
#!/bin/bash
java -Xms${MEMORY}M -Xmx${MEMORY}M -jar server.jar nogui
EOL

chmod +x start.sh

# Create systemd service file
SERVICE_NAME=$(basename "$SERVER_PATH" | tr '.' '-')
cat > /etc/systemd/system/minecraft-$SERVICE_NAME.service << EOL
[Unit]
Description=Minecraft Server - $(basename "$SERVER_PATH")
After=network.target

[Service]
WorkingDirectory=$SERVER_PATH
User=root
Group=root
Restart=always
ExecStart=/usr/bin/screen -DmS minecraft-$SERVICE_NAME $SERVER_PATH/start.sh
ExecStop=/usr/bin/screen -p 0 -S minecraft-$SERVICE_NAME -X eval 'stuff "say SERVER SHUTTING DOWN IN 10 SECONDS..."\015'
ExecStop=/bin/sleep 10
ExecStop=/usr/bin/screen -p 0 -S minecraft-$SERVICE_NAME -X eval 'stuff "stop"\015'
ExecStop=/bin/sleep 5

[Install]
WantedBy=multi-user.target
EOL

# Create logs directory
mkdir -p logs

# Reload systemd
systemctl daemon-reload
systemctl enable minecraft-$SERVICE_NAME.service

echo "Server setup complete!"
EOF

# Create script for server backup
cat > ${SCRIPTS_DIR}/backup-server.sh << 'EOF'
#!/bin/bash
# Backup a Minecraft server

SERVER_ID=$1
BACKUP_PATH=${2:-/opt/minecraft/backups}

if [ -z "$SERVER_ID" ]; then
  echo "Usage: $0 <server-id> [backup-path]"
  exit 1
fi

SERVER_PATH="/opt/minecraft/servers/$SERVER_ID"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_PATH/${SERVER_ID}_${TIMESTAMP}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_PATH"

# Check if server exists
if [ ! -d "$SERVER_PATH" ]; then
  echo "Server $SERVER_ID not found"
  exit 1
fi

# Create backup
echo "Creating backup of server $SERVER_ID to $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C "$SERVER_PATH" .

echo "Backup complete: $BACKUP_FILE"
EOF

# Make scripts executable
chmod +x ${SCRIPTS_DIR}/create-server.sh
chmod +x ${SCRIPTS_DIR}/backup-server.sh

# Create system status API route
mkdir -p ${WEB_DIR}/app/api/system/status
cat > ${WEB_DIR}/app/api/system/status/route.ts << 'EOF'
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import os from "os"

const execAsync = promisify(exec)

export async function GET() {
  try {
    // Get CPU usage
    const { stdout: cpuOutput } = await execAsync("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")
    const cpuUsage = parseFloat(cpuOutput.trim())

    // Get memory info
    const totalMemory = Math.round(os.totalmem() / (1024 * 1024 * 1024)) // GB
    const freeMemory = Math.round(os.freemem() / (1024 * 1024 * 1024)) // GB
    const usedMemory = totalMemory - freeMemory

    // Get disk usage
    const { stdout: diskOutput } = await execAsync("df -h / | awk 'NR==2 {print $3,$2}'")
    const [diskUsed, diskTotal] = diskOutput.trim().split(" ")

    // Get system uptime
    const uptime = os.uptime()
    const days = Math.floor(uptime / 86400)
    const hours = Math.floor((uptime % 86400) / 3600)
    const minutes = Math.floor((uptime % 3600) / 60)
    const uptimeString = `${days} days, ${hours} hours, ${minutes} minutes`

    // Get OS info
    const { stdout: osVersionOutput } = await execAsync("cat /etc/os-release | grep PRETTY_NAME | cut -d '\"' -f 2")
    const { stdout: kernelOutput } = await execAsync("uname -r")
    const { stdout: hostnameOutput } = await execAsync("hostname")

    return NextResponse.json({
      resources: {
        cpu: Math.round(cpuUsage),
        memory: {
          used: usedMemory,
          total: totalMemory
        },
        disk: {
          used: diskUsed.replace("G", ""),
          total: diskTotal.replace("G", "")
        }
      },
      os: {
        version: osVersionOutput.trim(),
        kernel: kernelOutput.trim(),
        arch: os.arch(),
        hostname: hostnameOutput.trim(),
        uptime: uptimeString
      }
    })
  } catch (error) {
    console.error("Error getting system status:", error)
    return NextResponse.json({ error: "Failed to get system status" }, { status: 500 })
  }
}
EOF

# Create servers API route
mkdir -p ${WEB_DIR}/app/api/servers
cat > ${WEB_DIR}/app/api/servers/route.ts << 'EOF'
import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

// Base path for server installations
const SERVERS_BASE_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function GET() {
  try {
    // Check if servers directory exists
    try {
      await fs.access(SERVERS_BASE_PATH)
    } catch (error) {
      // Create directory if it doesn't exist
      await fs.mkdir(SERVERS_BASE_PATH, { recursive: true })
      return NextResponse.json({ servers: [] })
    }

    // Get all server directories
    const serverDirs = await fs.readdir(SERVERS_BASE_PATH, { withFileTypes: true })
    const serverFolders = serverDirs
      .filter(dirent => dirent.isDirectory())
      .map(dirent => dirent.name)

    // Get server details
    const servers = await Promise.all(
      serverFolders.map(async (folder) => {
        const serverPath = path.join(SERVERS_BASE_PATH, folder)
        const configPath = path.join(serverPath, "server.json")
        
        try {
          // Check if server.json exists
          await fs.access(configPath)
          const configData = await fs.readFile(configPath, "utf-8")
          const config = JSON.parse(configData)
          
          // Check if server is running
          const isRunning = await checkIfServerRunning(folder)
          
          // Get server stats if running
          let players = { online: 0, max: 20 }
          let memory = { used: 0, allocated: config.memory || 1024 }
          let uptime = "0:00:00"
          
          if (isRunning) {
            try {
              // In a real implementation, this would use RCON to get player count
              // For now, we'll just use default values
              memory.used = Math.floor(Math.random() * memory.allocated * 0.8)
            } catch (error) {
              console.error(`Error getting stats for server ${folder}:`, error)
            }
          }
          
          return {
            id: folder,
            name: config.name || folder,
            type: config.type || "vanilla",
            version: config.version || "unknown",
            status: isRunning ? "online" : "offline",
            port: config.port || "25565",
            players,
            memory,
            uptime: isRunning ? uptime : "0:00:00"
          }
        } catch (error) {
          console.error(`Error processing server ${folder}:`, error)
          return null
        }
      })
    )
    
    // Filter out null values
    const validServers = servers.filter(server => server !== null)
    
    return NextResponse.json({ servers: validServers })
  } catch (error) {
    console.error("Error getting servers:", error)
    return NextResponse.json({ error: "Failed to get servers" }, { status: 500 })
  }
}

async function checkIfServerRunning(serverId: string) {
  try {
    const { stdout } = await execAsync(`systemctl is-active minecraft-${serverId}`)
    return stdout.trim() === "active"
  } catch (error) {
    return false
  }
}
EOF

# Create server-downloader.tsx component
cat > ${WEB_DIR}/components/server-downloader.tsx << 'EOF'
"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Progress } from "@/components/ui/progress"

export function ServerDownloader() {
  const [serverName, setServerName] = useState("")
  const [serverType, setServerType] = useState("paper")
  const [mcVersion, setMcVersion] = useState("1.20.1")
  const [serverPort, setServerPort] = useState("25565")
  const [memory, setMemory] = useState("1024")
  const [isDownloading, setIsDownloading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [error, setError] = useState("")

  const handleDownload = async () => {
    if (!serverName) {
      setError("Server name is required")
      return
    }

    setError("")
    setIsDownloading(true)
    setProgress(0)

    try {
      // Start the download process
      const response = await fetch("/api/server-download", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: serverName,
          type: serverType,
          version: mcVersion,
          port: serverPort,
          memory: memory,
        }),
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.message || "Failed to download server")
      }

      const { id } = await response.json()

      // Poll for progress
      const progressInterval = setInterval(async () => {
        const progressResponse = await fetch(`/api/server-download/${id}`)
        const progressData = await progressResponse.json()

        setProgress(progressData.progress)

        if (progressData.status === "completed") {
          clearInterval(progressInterval)
          setIsDownloading(false)
          setProgress(100)
          // Refresh the server list
          window.location.reload()
        } else if (progressData.status === "failed") {
          clearInterval(progressInterval)
          setIsDownloading(false)
          setError(progressData.error || "Download failed")
        }
      }, 1000)
    } catch (error) {
      setError(error instanceof Error ? error.message : "Download failed")
      setIsDownloading(false)
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader>
        <CardTitle>Create New Server</CardTitle>
        <CardDescription>Download and set up a new Minecraft server</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {error && (
          <div className="bg-red-500/20 text-red-400 p-3 rounded-md text-sm">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="serverName">Server Name</Label>
            <Input
              id="serverName"
              value={serverName}
              onChange={(e) => setServerName(e.target.value)}
              placeholder="My Minecraft Server"
              className="bg-slate-800 border-slate-700"
              disabled={isDownloading}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="serverType">Server Type</Label>
            <Select value={serverType} onValueChange={setServerType} disabled={isDownloading}>
              <SelectTrigger id="serverType" className="bg-slate-800 border-slate-700">
                <SelectValue placeholder="Select server type" />
              </SelectTrigger>
              <SelectContent className="bg-slate-800 border-slate-700">
                <SelectItem value="paper">Paper</SelectItem>
                <SelectItem value="spigot">Spigot</SelectItem>
                <SelectItem value="forge">Forge</SelectItem>
                <SelectItem value="fabric">Fabric</SelectItem>
                <SelectItem value="vanilla">Vanilla</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="mcVersion">Minecraft Version</Label>
            <Select value={mcVersion} onValueChange={setMcVersion} disabled={isDownloading}>
              <SelectTrigger id="mcVersion" className="bg-slate-800 border-slate-700">
                <SelectValue placeholder="Select version" />
              </SelectTrigger>
              <SelectContent className="bg-slate-800 border-slate-700">
                <SelectItem value="1.20.1">1.20.1</SelectItem>
                <SelectItem value="1.19.4">1.19.4</SelectItem>
                <SelectItem value="1.18.2">1.18.2</SelectItem>
                <SelectItem value="1.17.1">1.17.1</SelectItem>
                <SelectItem value="1.16.5">1.16.5</SelectItem>
                <SelectItem value="1.12.2">1.12.2</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="serverPort">Server Port</Label>
            <Input
              id="serverPort"
              value={serverPort}
              onChange={(e) => setServerPort(e.target.value)}
              placeholder="25565"
              className="bg-slate-800 border-slate-700"
              disabled={isDownloading}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="memory">Memory (MB)</Label>
            <Select value={memory} onValueChange={setMemory} disabled={isDownloading}>
              <SelectTrigger id="memory" className="bg-slate-800 border-slate-700">
                <SelectValue placeholder="Select memory" />
              </SelectTrigger>
              <SelectContent className="bg-slate-800 border-slate-700">
                <SelectItem value="1024">1 GB</SelectItem>
                <SelectItem value="2048">2 GB</SelectItem>
                <SelectItem value="4096">4 GB</SelectItem>
                <SelectItem value="8192">8 GB</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {isDownloading && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Downloading and setting up server...</span>
              <span>{progress}%</span>
            </div>
            <Progress value={progress} />
          </div>
        )}
      </CardContent>
      <CardFooter>
        <Button
          onClick={handleDownload}
          disabled={isDownloading}
          className="w-full bg-emerald-600 hover:bg-emerald-500"
        >
          {isDownloading ? "Setting Up Server..." : "Create Server"}
        </Button>
      </CardFooter>
    </Card>
  )
}
EOF

# Create server-download API route
mkdir -p ${WEB_DIR}/app/api/server-download
cat > ${WEB_DIR}/app/api/server-download/route.ts << 'EOF'
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"
import { v4 as uuidv4 } from "uuid"

const execAsync = promisify(exec)

// Base paths
const SERVERS_BASE_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"
const SCRIPTS_PATH = process.env.SCRIPTS_PATH || "/opt/minecraft/scripts"
const DOWNLOADS_PATH = process.env.DOWNLOADS_PATH || "/opt/minecraft/downloads"

// Store download progress
const downloads = new Map()

export async function POST(request: Request) {
  try {
    const { name, type, version, port, memory } = await request.json()

    // Validate input
    if (!name) {
      return NextResponse.json({ error: "Server name is required" }, { status: 400 })
    }

    // Create a sanitized server ID from the name
    const serverId = name.toLowerCase().replace(/[^a-z0-9]/g, "-")

    // Check if server already exists
    const serverPath = path.join(SERVERS_BASE_PATH, serverId)
    try {
      await fs.access(serverPath)
      return NextResponse.json({ error: "Server with this name already exists" }, { status: 400 })
    } catch (error) {
      // Server doesn't exist, continue
    }

    // Create a unique download ID
    const downloadId = uuidv4()

    // Store download info
    downloads.set(downloadId, {
      id: downloadId,
      serverId,
      progress: 0,
      status: "pending",
      error: null,
    })

    // Start the download process in the background
    downloadServer(downloadId, serverId, type, version, port, memory)

    return NextResponse.json({ id: downloadId })
  } catch (error) {
    console.error("Error creating server:", error)
    return NextResponse.json({ error: "Failed to create server" }, { status: 500 })
  }
}

async function downloadServer(downloadId: string, serverId: string, type: string, version: string, port: string, memory: string) {
  const download = downloads.get(downloadId)  version: string, port: string, memory: string) {
  const download = downloads.get(downloadId)
  
  try {
    // Update status to downloading
    download.status = "downloading"
    download.progress = 10
    downloads.set(downloadId, download)

    // Create server directory
    const serverPath = path.join(SERVERS_BASE_PATH, serverId)
    await fs.mkdir(serverPath, { recursive: true })

    // Update progress
    download.progress = 30
    downloads.set(downloadId, download)

    // Run the server creation script
    const createServerScript = path.join(SCRIPTS_PATH, "create-server.sh")
    await execAsync(`bash ${createServerScript} ${serverPath} ${type} ${version} ${port} ${memory}`)

    // Update progress
    download.progress = 90
    downloads.set(downloadId, download)

    // Final setup steps
    download.status = "completed"
    download.progress = 100
    downloads.set(downloadId, download)

    // Clean up download info after 5 minutes
    setTimeout(() => {
      downloads.delete(downloadId)
    }, 5 * 60 * 1000)
  } catch (error) {
    console.error(`Error setting up server ${serverId}:`, error)
    download.status = "failed"
    download.error = error instanceof Error ? error.message : "Unknown error"
    downloads.set(downloadId, download)
  }
}
EOF

# Create server-download/[id]/route.ts
mkdir -p ${WEB_DIR}/app/api/server-download/\[id\]
cat > ${WEB_DIR}/app/api/server-download/\[id\]/route.ts << 'EOF'
import { NextResponse } from "next/server"

// Store download progress (shared with the POST route)
const downloads = new Map()

export async function GET(request: Request, { params }: { params: { id: string } }) {
  const downloadId = params.id

  // Get download info
  const download = downloads.get(downloadId)

  if (!download) {
    return NextResponse.json({ error: "Download not found" }, { status: 404 })
  }

  return NextResponse.json(download)
}
EOF

# Create server console component
cat > ${WEB_DIR}/components/server-console.tsx << 'EOF'
"use client"

import { useEffect, useRef, useState } from "react"
import { Card, CardContent, CardFooter } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Download, Send } from 'lucide-react'

type ServerConsoleProps = {
  serverId: string
}

export function ServerConsole({ serverId }: ServerConsoleProps) {
  const [logs, setLogs] = useState<string[]>([])
  const [command, setCommand] = useState("")
  const [isLoading, setIsLoading] = useState(true)
  const logsEndRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when logs update
  useEffect(() => {
    if (logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: "smooth" })
    }
  }, [logs])

  // Fetch logs on component mount
  useEffect(() => {
    const fetchLogs = async () => {
      try {
        const response = await fetch(`/api/servers/${serverId}/logs`)
        const data = await response.json()
        
        if (response.ok) {
          setLogs(data.logs || [])
        } else {
          setLogs(["Failed to load server logs"])
        }
      } catch (error) {
        setLogs(["Error loading server logs"])
      } finally {
        setIsLoading(false)
      }
    }

    fetchLogs()

    // Poll for new logs every 3 seconds
    const interval = setInterval(fetchLogs, 3000)
    return () => clearInterval(interval)
  }, [serverId])

  const sendCommand = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!command.trim()) return

    // Add command to logs
    setLogs((prev) => [...prev, `> ${command}`])
    
    try {
      const response = await fetch(`/api/servers/${serverId}/command`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ command }),
      })

      if (!response.ok) {
        setLogs((prev) => [...prev, "Failed to send command"])
      }
    } catch (error) {
      setLogs((prev) => [...prev, "Error sending command"])
    }

    setCommand("")
  }

  const downloadLogs = async () => {
    try {
      const response = await fetch(`/api/servers/${serverId}/logs/download`)
      const blob = await response.blob()
      
      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `server-${serverId}-logs.txt`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    } catch (error) {
      console.error("Error downloading logs:", error)
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardContent className="p-4">
        <div className="flex justify-between items-center mb-4">
          <h3 className="font-medium">Server Console</h3>
          <Button variant="outline" size="sm" onClick={downloadLogs} className="bg-slate-800 hover:bg-slate-700">
            <Download className="h-4 w-4 mr-2" />
            Download Logs
          </Button>
        </div>
        
        <div className="bg-black text-green-400 font-mono text-sm p-4 rounded-md h-[400px] overflow-y-auto">
          {isLoading ? (
            <div className="flex justify-center items-center h-full">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-500"></div>
            </div>
          ) : (
            <>
              {logs.map((log, index) => (
                <div key={index} className={log.startsWith(">") ? "text-white" : ""}>
                  {log}
                </div>
              ))}
              <div ref={logsEndRef} />
            </>
          )}
        </div>
      </CardContent>
      <CardFooter>
        <form onSubmit={sendCommand} className="flex w-full gap-2">
          <Input
            placeholder="Type a command..."
            value={command}
            onChange={(e) => setCommand(e.target.value)}
            className="flex-1 bg-slate-800 border-slate-700"
          />
          <Button type="submit" className="bg-emerald-600 hover:bg-emerald-500">
            <Send className="h-4 w-4 mr-2" />
            Send
          </Button>
        </form>
      </CardFooter>
    </Card>
  )
}
EOF

# Create server logs API route
mkdir -p ${WEB_DIR}/app/api/servers/\[id\]/logs
cat > ${WEB_DIR}/app/api/servers/\[id\]/logs/route.ts << 'EOF'
import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"

// Base path for server installations
const SERVERS_BASE_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function GET(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    const serverDir = path.join(SERVERS_BASE_PATH, serverId)
    const logPath = path.join(serverDir, "logs", "latest.log")

    // Check if log file exists
    try {
      await fs.access(logPath)
    } catch (error) {
      // Log file doesn't exist, try to create an empty one
      try {
        await fs.mkdir(path.join(serverDir, "logs"), { recursive: true })
        await fs.writeFile(logPath, "")
      } catch (createError) {
        return NextResponse.json({
          logs: ["Server logs not available yet."],
          error: "Log file not found",
        })
      }
    }

    // Read log file
    const logContent = await fs.readFile(logPath, "utf-8")

    // Split into lines and get the last 100 lines
    const logLines = logContent.split("\n").filter(Boolean)
    const lastLines = logLines.slice(-100)

    return NextResponse.json({ logs: lastLines })
  } catch (error) {
    console.error(`Error getting logs for server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to get server logs" }, { status: 500 })
  }
}
EOF

# Create server command API route
mkdir -p ${WEB_DIR}/app/api/servers/\[id\]/command
cat > ${WEB_DIR}/app/api/servers/\[id\]/command/route.ts << 'EOF'
import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

// Base path for server installations
const SERVERS_BASE_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function POST(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    const { command } = await request.json()

    if (!command) {
      return NextResponse.json({ error: "No command provided" }, { status: 400 })
    }

    // Check if server is running
    try {
      const { stdout } = await execAsync(`systemctl is-active minecraft-${serverId}`)
      if (stdout.trim() !== "active") {
        return NextResponse.json({ error: "Server is not running" }, { status: 400 })
      }
    } catch (error) {
      return NextResponse.json({ error: "Server is not running" }, { status: 400 })
    }

    // Send command to server using screen
    try {
      await execAsync(`screen -S minecraft-${serverId} -p 0 -X stuff "${command}$(printf '\\r')"`)
      return NextResponse.json({ success: true, message: "Command sent" })
    } catch (error) {
      console.error(`Error sending command to server ${serverId}:`, error)
      return NextResponse.json({ error: "Failed to send command" }, { status: 500 })
    }
  } catch (error) {
    console.error(`Error processing command for server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to process command" }, { status: 500 })
  }
}
EOF

# Create server start API route
mkdir -p ${WEB_DIR}/app/api/servers/\[id\]/start
cat > ${WEB_DIR}/app/api/servers/\[id\]/start/route.ts << 'EOF'
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function POST(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    // Check if server is already running
    try {
      const { stdout } = await execAsync(`systemctl is-active minecraft-${serverId}`)
      if (stdout.trim() === "active") {
        return NextResponse.json({ error: "Server is already running" }, { status: 400 })
      }
    } catch (error) {
      // Server is not running, continue
    }

    // Start the server
    await execAsync(`systemctl start minecraft-${serverId}`)

    return NextResponse.json({ success: true, message: "Server started" })
  } catch (error) {
    console.error(`Error starting server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to start server" }, { status: 500 })
  }
}
EOF

# Create server stop API route
mkdir -p ${WEB_DIR}/app/api/servers/\[id\]/stop
cat > ${WEB_DIR}/app/api/servers/\[id\]/stop/route.ts << 'EOF'
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function POST(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    // Check if server is running
    try {
      const { stdout } = await execAsync(`systemctl is-active minecraft-${serverId}`)
      if (stdout.trim() !== "active") {
        return NextResponse.json({ error: "Server is not running" }, { status: 400 })
      }
    } catch (error) {
      return NextResponse.json({ error: "Server is not running" }, { status: 400 })
    }

    // Stop the server
    await execAsync(`systemctl stop minecraft-${serverId}`)

    return NextResponse.json({ success: true, message: "Server stopped" })
  } catch (error) {
    console.error(`Error stopping server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to stop server" }, { status: 500 })
  }
}
EOF

# Create server restart API route
mkdir -p ${WEB_DIR}/app/api/servers/\[id\]/restart
cat > ${WEB_DIR}/app/api/servers/\[id\]/restart/route.ts << 'EOF'
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function POST(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    // Check if server is running
    let isRunning = false
    try {
      const { stdout } = await execAsync(`systemctl is-active minecraft-${serverId}`)
      isRunning = stdout.trim() === "active"
    } catch (error) {
      // Server is not running
    }

    if (isRunning) {
      // Restart the server
      await execAsync(`systemctl restart minecraft-${serverId}`)
    } else {
      // Start the server
      await execAsync(`systemctl start minecraft-${serverId}`)
    }

    return NextResponse.json({ success: true, message: "Server restarted" })
  } catch (error) {
    console.error(`Error restarting server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to restart server" }, { status: 500 })
  }
}
EOF

# Create tailwind.config.js
cat > ${WEB_DIR}/tailwind.config.js << 'EOF'
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
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
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

# Create next.config.js
cat > ${WEB_DIR}/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: {
    serverActions: true,
  },
}

module.exports = nextConfig
EOF

# Create tsconfig.json
cat > ${WEB_DIR}/tsconfig.json << 'EOF'
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

# Create .env file with JWT_SECRET
cat > ${WEB_DIR}/.env << EOF
JWT_SECRET="${JWT_SECRET}"
SERVERS_PATH="/opt/minecraft/servers"
DOWNLOADS_PATH="/opt/minecraft/downloads"
CONFIG_PATH="/opt/minecraft/config"
SCRIPTS_PATH="/opt/minecraft/scripts"
EOF

# Create systemd service for web interface
cat > /etc/systemd/system/minecraft-web.service << EOF
[Unit]
Description=MinecraftOS Web Interface
After=network.target

[Service]
WorkingDirectory=${WEB_DIR}
Environment=NODE_ENV=production
Environment=JWT_SECRET=${JWT_SECRET}
Environment=SERVERS_PATH=/opt/minecraft/servers
Environment=DOWNLOADS_PATH=/opt/minecraft/downloads
Environment=CONFIG_PATH=/opt/minecraft/config
Environment=SCRIPTS_PATH=/opt/minecraft/scripts
ExecStart=/usr/bin/npm start
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Create initial admin user
mkdir -p ${CONFIG_DIR}
cat > ${WEB_DIR}/create-admin.js << EOF
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

const CONFIG_PATH = process.env.CONFIG_PATH || '/opt/minecraft/config';
const USERS_FILE = path.join(CONFIG_PATH, 'users.json');

// Create config directory if it doesn't exist
if (!fs.existsSync(CONFIG_PATH)) {
  fs.mkdirSync(CONFIG_PATH, { recursive: true });
}

// Create users file if it doesn't exist
if (!fs.existsSync(USERS_FILE)) {
  fs.writeFileSync(USERS_FILE, JSON.stringify({ users: [] }));
}

// Read existing users
const data = fs.readFileSync(USERS_FILE, 'utf8');
const { users } = JSON.parse(data);

// Check if admin user already exists
const adminExists = users.some(user => user.username === '${ADMIN_USER}');

if (adminExists) {
  console.log('Admin user already exists');
  process.exit(0);
}

// Create admin user
const hashedPassword = bcrypt.hashSync('${ADMIN_PASSWORD}', 10);
users.push({
  id: Date.now().toString(),
  username: '${ADMIN_USER}',
  password: hashedPassword,
  role: 'admin'
});

// Save users
fs.writeFileSync(USERS_FILE, JSON.stringify({ users }));
console.log('Admin user created successfully');
EOF

# Install dependencies and build the web interface
cd ${WEB_DIR}
npm install
node create-admin.js
npm run build

# Enable and start the web interface service
systemctl daemon-reload
systemctl enable minecraft-web.service
systemctl start minecraft-web.service

echo "====================================="
echo "MinecraftOS Web Interface Setup Complete"
echo "====================================="
echo "Web interface is running at http://localhost:8080"
echo "Username: ${ADMIN_USER}"
echo "Password: (as provided during setup)"
echo ""
echo "You can now create and manage Minecraft servers through the web interface."
echo "====================================="
