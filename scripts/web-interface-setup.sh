#!/bin/bash

# MinecraftOS Web Interface Setup Script
# This script installs and configures only the MinecraftOS web interface with authentication

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
    "@types/cookie": "^0.5.4"
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

# Create middleware.ts for authentication
cat > ${WEB_DIR}/middleware.ts << EOF
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { verifyAuth } from './lib/auth'

export async function middleware(request: NextRequest) {
  // Get the pathname
  const path = request.nextUrl.pathname

  // Public paths that don't require authentication
  const isPublicPath = path === '/login' || path.startsWith('/api/auth')

  // Get the session cookie
  const session = request.cookies.get('session')?.value || ''

  // Verify authentication
  const verifiedToken = await verifyAuth(session).catch((err) => {
    console.error(err.message)
    return null
  })

  // Redirect to login if accessing protected route without authentication
  if (!isPublicPath && !verifiedToken) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Redirect to dashboard if accessing login page with valid authentication
  if (isPublicPath && verifiedToken) {
    return NextResponse.redirect(new URL('/', request.url))
  }

  return NextResponse.next()
}

// Configure which paths the middleware runs on
export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
EOF

# Create auth library
mkdir -p ${WEB_DIR}/lib
cat > ${WEB_DIR}/lib/auth.ts << EOF
import { SignJWT, jwtVerify } from 'jose'
import { cookies } from 'next/headers'
import { NextRequest, NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import bcrypt from 'bcrypt'

const secretKey = process.env.JWT_SECRET || 'your-secret-key-min-32-chars-long-here'
const key = new TextEncoder().encode(secretKey)

// User data file path
const CONFIG_PATH = process.env.CONFIG_PATH || '/opt/minecraft/config'
const USERS_FILE = path.join(CONFIG_PATH, 'users.json')

// Initialize users file if it doesn't exist
export function initUsers() {
  if (!fs.existsSync(CONFIG_PATH)) {
    fs.mkdirSync(CONFIG_PATH, { recursive: true })
  }
  
  if (!fs.existsSync(USERS_FILE)) {
    fs.writeFileSync(USERS_FILE, JSON.stringify({ users: [] }))
  }
}

// Get users from file
export function getUsers() {
  initUsers()
  const data = fs.readFileSync(USERS_FILE, 'utf8')
  return JSON.parse(data).users || []
}

// Save users to file
export function saveUsers(users: any[]) {
  fs.writeFileSync(USERS_FILE, JSON.stringify({ users }))
}

// Create a user
export async function createUser(username: string, password: string) {
  const users = getUsers()
  
  // Check if user already exists
  if (users.some((user: any) => user.username === username)) {
    return { success: false, message: 'User already exists' }
  }
  
  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10)
  
  // Add user
  users.push({
    id: Date.now().toString(),
    username,
    password: hashedPassword,
    role: 'admin'
  })
  
  saveUsers(users)
  return { success: true }
}

// Verify user credentials
export async function verifyCredentials(username: string, password: string) {
  const users = getUsers()
  const user = users.find((u: any) => u.username === username)
  
  if (!user) {
    return null
  }
  
  const passwordMatch = await bcrypt.compare(password, user.password)
  
  if (!passwordMatch) {
    return null
  }
  
  return {
    id: user.id,
    username: user.username,
    role: user.role
  }
}

// Create session
export async function signJWT(payload: any) {
  return await new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('1d')
    .sign(key)
}

// Verify session
export async function verifyAuth(token: string) {
  try {
    const verified = await jwtVerify(token, key)
    return verified.payload
  } catch (error) {
    throw new Error('Invalid token')
  }
}

// Get session data
export async function getSession() {
  const session = cookies().get('session')?.value
  if (!session) return null
  
  try {
    const payload = await verifyAuth(session)
    return payload
  } catch (error) {
    return null
  }
}
EOF

# Create login page
mkdir -p ${WEB_DIR}/app/login
cat > ${WEB_DIR}/app/login/page.tsx << EOF
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'

export default function LoginPage() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.message || 'Login failed')
      }

      // Redirect to dashboard on successful login
      router.push('/')
      router.refresh()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Login failed')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-slate-950 p-4">
      <Card className="w-full max-w-md bg-slate-900 border-slate-800">
        <CardHeader className="space-y-1">
          <div className="flex items-center justify-center mb-6">
            <div className="w-12 h-12 bg-emerald-500 rounded-full flex items-center justify-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                <line x1="6" y1="6" x2="6.01" y2="6"></line>
                <line x1="6" y1="18" x2="6.01" y2="18"></line>
              </svg>
            </div>
          </div>
          <CardTitle className="text-2xl text-center">MinecraftOS</CardTitle>
          <CardDescription className="text-center">Enter your credentials to access the admin panel</CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit}>
          <CardContent className="space-y-4">
            {error && (
              <div className="bg-red-500/20 text-red-400 p-3 rounded-md text-sm">
                {error}
              </div>
            )}
            <div className="space-y-2">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                type="text"
                placeholder="Enter your username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                className="bg-slate-800 border-slate-700"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="bg-slate-800 border-slate-700"
              />
            </div>
          </CardContent>
          <CardFooter>
            <Button 
              type="submit" 
              className="w-full bg-emerald-600 hover:bg-emerald-500" 
              disabled={isLoading}
            >
              {isLoading ? 'Signing in...' : 'Sign In'}
            </Button>
          </CardFooter>
        </form>
      </Card>
    </div>
  )
}
EOF

# Create login API route
mkdir -p ${WEB_DIR}/app/api/auth/login
cat > ${WEB_DIR}/app/api/auth/login/route.ts << EOF
import { NextResponse } from 'next/server'
import { cookies } from 'next/headers'
import { verifyCredentials, signJWT } from '@/lib/auth'

export async function POST(request: Request) {
  try {
    const { username, password } = await request.json()

    // Verify credentials
    const user = await verifyCredentials(username, password)

    if (!user) {
      return NextResponse.json(
        { success: false, message: 'Invalid username or password' },
        { status: 401 }
      )
    }

    // Create session token
    const token = await signJWT({
      id: user.id,
      username: user.username,
      role: user.role,
    })

    // Set cookie
    cookies().set({
      name: 'session',
      value: token,
      httpOnly: true,
      path: '/',
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24, // 1 day
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Login error:', error)
    return NextResponse.json(
      { success: false, message: 'Authentication failed' },
      { status: 500 }
    )
  }
}
EOF

# Create logout API route
mkdir -p ${WEB_DIR}/app/api/auth/logout
cat > ${WEB_DIR}/app/api/auth/logout/route.ts << EOF
import { NextResponse } from 'next/server'
import { cookies } from 'next/headers'

export async function POST() {
  // Clear the session cookie
  cookies().set({
    name: 'session',
    value: '',
    expires: new Date(0),
    path: '/',
  })

  return NextResponse.json({ success: true })
}
EOF

# Create app/page.tsx (dashboard)
cat > ${WEB_DIR}/app/page.tsx << EOF
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { ServerList } from '@/components/server-list'
import { NetworkSettings } from '@/components/network-settings'
import { SystemInfo } from '@/components/system-info'
import { ServerDownloader } from '@/components/server-downloader'

export default function Home() {
  const [showServerCreation, setShowServerCreation] = useState(false)
  const router = useRouter()

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
      })
      router.push('/login')
    } catch (error) {
      console.error('Logout error:', error)
    }
  }

  return (
    <main className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-emerald-500">MinecraftOS</h1>
        <div className="flex gap-2">
          <Button 
            variant="outline" 
            className="bg-slate-800 hover:bg-slate-700"
            onClick={handleLogout}
          >
            Logout
          </Button>
          <Button 
            className="bg-emerald-600 hover:bg-emerald-500"
            onClick={() => setShowServerCreation(!showServerCreation)}
          >
            {showServerCreation ? 'Hide' : 'Create New Server'}
          </Button>
        </div>
      </div>

      {showServerCreation && (
        <div className="mb-8">
          <ServerDownloader />
        </div>
      )}

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

# Create server-list.tsx component
mkdir -p ${WEB_DIR}/components
cat > ${WEB_DIR}/components/server-list.tsx << EOF
"use client"

import { useState, useEffect } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

export function ServerList() {
  const [servers, setServers] = useState([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchServers = async () => {
      try {
        const response = await fetch("/api/servers")
        const data = await response.json()
        setServers(data.servers || [])
      } catch (error) {
        console.error("Error fetching servers:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchServers()
  }, [])

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
      </div>
    )
  }

  if (servers.length === 0) {
    return (
      <Card className="bg-slate-900 border-slate-800">
        <CardContent className="p-6 text-center">
          <div className="mb-4">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="48"
              height="48"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="mx-auto text-slate-500"
            >
              <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
              <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
              <line x1="6" y1="6" x2="6.01" y2="6"></line>
              <line x1="6" y1="18" x2="6.01" y2="18"></line>
            </svg>
          </div>
          <h3 className="text-xl font-medium mb-2">No Servers Found</h3>
          <p className="text-slate-400 mb-4">
            You haven't created any Minecraft servers yet. Click the "Create New Server" button to get started.
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {servers.map((server: any) => (
        <Card key={server.id} className="bg-slate-900 border-slate-800">
          <CardContent className="p-4">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-medium">{server.name}</h3>
              <span
                className={\`px-2 py-1 text-xs rounded-full \${
                  server.status === "online"
                    ? "bg-green-500/20 text-green-400"
                    : "bg-red-500/20 text-red-400"
                }\`}
              >
                {server.status === "online" ? "Online" : "Offline"}
              </span>
            </div>
            <div className="space-y-2 text-sm text-slate-400">
              <div className="flex justify-between">
                <span>Version:</span>
                <span>{server.version}</span>
              </div>
              <div className="flex justify-between">
                <span>Port:</span>
                <span>{server.port}</span>
              </div>
              <div className="flex justify-between">
                <span>Players:</span>
                <span>
                  {server.players.online}/{server.players.max}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Memory:</span>
                <span>
                  {server.memory.used}MB / {server.memory.allocated}MB
                </span>
              </div>
              {server.status === "online" && (
                <div className="flex justify-between">
                  <span>Uptime:</span>
                  <span>{server.uptime}</span>
                </div>
              )}
            </div>
            <div className="flex gap-2 mt-4">
              <Button
                variant="outline"
                size="sm"
                className="flex-1 bg-slate-800 hover:bg-slate-700"
              >
                Manage
              </Button>
              {server.status === "online" ? (
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1 bg-red-900/20 hover:bg-red-900/40 text-red-400"
                  onClick={() => {
                    fetch(\`/api/servers/\${server.id}/stop\`, {
                      method: 'POST'
                    })
                  }}
                >
                  Stop
                </Button>
              ) : (
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1 bg-green-900/20 hover:bg-green-900/40 text-green-400"
                  onClick={() => {
                    fetch(\`/api/servers/\${server.id}/start\`, {
                      method: 'POST'
                    })
                  }}
                >
                  Start
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
EOF

# Create network-settings.tsx component
cat > ${WEB_DIR}/components/network-settings.tsx << EOF
"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"

export function NetworkSettings() {
  const [networkConfig, setNetworkConfig] = useState("dhcp")
  const [ipAddress, setIpAddress] = useState("")
  const [subnetMask, setSubnetMask] = useState("255.255.255.0")
  const [gateway, setGateway] = useState("")
  const [dns, setDns] = useState("8.8.8.8")
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)

  useEffect(() => {
    const fetchNetworkSettings = async () => {
      try {
        const response = await fetch("/api/system/network")
        const data = await response.json()
        
        setNetworkConfig(data.networkConfig || "dhcp")
        setIpAddress(data.ipAddress || "")
        setSubnetMask(data.subnetMask || "255.255.255.0")
        setGateway(data.gateway || "")
        setDns(data.dns || "8.8.8.8")
      } catch (error) {
        console.error("Error fetching network settings:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchNetworkSettings()
  }, [])

  const handleSave = async () => {
    setIsSaving(true)
    try {
      const response = await fetch("/api/system/network", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          networkConfig,
          ipAddress,
          subnetMask,
          gateway,
          dns,
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to save network settings")
      }

      alert("Network settings saved successfully. Changes will take effect after reboot.")
    } catch (error) {
      console.error("Error saving network settings:", error)
      alert("Failed to save network settings")
    } finally {
      setIsSaving(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
      </div>
    )
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader>
        <CardTitle>Network Settings</CardTitle>
        <CardDescription>Configure the network settings for your MinecraftOS</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-2">
          <Label>Network Configuration</Label>
          <RadioGroup value={networkConfig} onValueChange={setNetworkConfig} className="flex flex-col space-y-2">
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="dhcp" id="dhcp" />
              <Label htmlFor="dhcp">DHCP (Automatic IP Address)</Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="static" id="static" />
              <Label htmlFor="static">Static IP Address</Label>
            </div>
          </RadioGroup>
        </div>

        {networkConfig === "static" && (
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="ipAddress">IP Address</Label>
              <Input
                id="ipAddress"
                value={ipAddress}
                onChange={(e) => setIpAddress(e.target.value)}
                placeholder="192.168.1.100"
                className="bg-slate-800 border-slate-700"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="subnetMask">Subnet Mask</Label>
              <Input
                id="subnetMask"
                value={subnetMask}
                onChange={(e) => setSubnetMask(e.target.value)}
                placeholder="255.255.255.0"
                className="bg-slate-800 border-slate-700"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="gateway">Gateway</Label>
              <Input
                id="gateway"
                value={gateway}
                onChange={(e) => setGateway(e.target.value)}
                placeholder="192.168.1.1"
                className="bg-slate-800 border-slate-700"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="dns">DNS Server</Label>
              <Input
                id="dns"
                value={dns}
                onChange={(e) => setDns(e.target.value)}
                placeholder="8.8.8.8"
                className="bg-slate-800 border-slate-700"
              />
            </div>
          </div>
        )}
      </CardContent>
      <CardFooter>
        <Button onClick={handleSave} disabled={isSaving} className="bg-emerald-600 hover:bg-emerald-500">
          {isSaving ? "Saving..." : "Save Network Settings"}
        </Button>
      </CardFooter>
    </Card>
  )
}
EOF

# Create system-info.tsx component
cat > ${WEB_DIR}/components/system-info.tsx << EOF
"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

export function SystemInfo() {
  const [systemInfo, setSystemInfo] = useState({
    cpu: 0,
    memory: {
      used: 0,
      total: 0,
    },
    disk: {
      used: 0,
      total: 0,
    },
    os: {
      version: "MinecraftOS 1.0.0",
      kernel: "Linux 5.15.0-generic",
      arch: "x86_64",
      hostname: "minecraft-server",
      uptime: "0 days, 0 hours, 0 minutes",
    },
    status: "loading",
  })

  // Fetch real system info from the API
  useEffect(() => {
    const fetchSystemInfo = async () => {
      try {
        const response = await fetch("/api/system/status")

        if (!response.ok) {
          throw new Error("Failed to fetch system info")
        }

        const data = await response.json()

        setSystemInfo({
          cpu: data.resources.cpu,
          memory: data.resources.memory,
          disk: data.resources.disk,
          os: data.os,
          status: "online",
        })
      } catch (error) {
        console.error("Error fetching system info:", error)
        setSystemInfo((prev) => ({ ...prev, status: "error" }))
      }
    }

    fetchSystemInfo()

    // Update system info every 10 seconds
    const interval = setInterval(fetchSystemInfo, 10000)
    return () => clearInterval(interval)
  }, [])

  const handleRestart = async () => {
    if (confirm("Are you sure you want to restart the system? All running servers will be stopped.")) {
      try {
        await fetch("/api/system/restart", {
          method: "POST",
        })
        alert("System restart initiated. The web interface will be unavailable for a few minutes.")
      } catch (error) {
        console.error("Error restarting system:", error)
        alert("Failed to restart system")
      }
    }
  }

  const handleShutdown = async () => {
    if (confirm("Are you sure you want to shut down the system? All running servers will be stopped.")) {
      try {
        await fetch("/api/system/shutdown", {
          method: "POST",
        })
        alert("System shutdown initiated. The web interface will be unavailable until the system is powered back on.")
      } catch (error) {
        console.error("Error shutting down system:", error)
        alert("Failed to shut down system")
      }
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader>
        <CardTitle>System Information</CardTitle>
        <CardDescription>View and manage your MinecraftOS system</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h3 className="text-lg font-medium mb-4">System Status</h3>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">Status:</span>
                <span className="flex items-center">
                  {systemInfo.status === "loading" ? (
                    <>
                      <span className="h-2 w-2 rounded-full bg-yellow-400 mr-1"></span>
                      <span className="text-yellow-400">Loading</span>
                    </>
                  ) : systemInfo.status === "error" ? (
                    <>
                      <span className="h-2 w-2 rounded-full bg-red-400 mr-1"></span>
                      <span className="text-red-400">Error</span>
                    </>
                  ) : (
                    <>
                      <span className="h-2 w-2 rounded-full bg-green-400 mr-1"></span>
                      <span className="text-green-400">Online</span>
                    </>
                  )}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">CPU Usage:</span>
                <span>{systemInfo.cpu}%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Memory:</span>
                <span>
                  {systemInfo.memory.used}GB / {systemInfo.memory.total}GB
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Disk:</span>
                <span>
                  {systemInfo.disk.used}GB / {systemInfo.disk.total}GB
                </span>
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-lg font-medium mb-4">System Information</h3>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">OS Version:</span>
                <span>{systemInfo.os.version}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Kernel:</span>
                <span>{systemInfo.os.kernel}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Architecture:</span>
                <span>{systemInfo.os.arch}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Hostname:</span>
                <span>{systemInfo.os.hostname}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Uptime:</span>
                <span>{systemInfo.os.uptime}</span>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
      <CardFooter className="flex gap-3">
        <Button variant="outline" onClick={handleRestart} className="bg-slate-800 hover:bg-slate-700">
          Restart System
        </Button>
        <Button variant="outline" onClick={handleShutdown} className="bg-red-900/20 hover:bg-red-900/40 text-red-400">
          Shutdown System
        </Button>
      </CardFooter>
    </Card>
  )
}
EOF

# Create server-downloader.tsx component
cat > ${WEB_DIR}/components/server-downloader.tsx << EOF
"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Progress } from "@/components/ui/progress"
import { Download } from 'lucide-react'

export function ServerDownloader() {
  const [serverName, setServerName] = useState("")
  const [serverType, setServerType] = useState("paper")
  const [mcVersion, setMcVersion] = useState("1.19.2")
  const [port, setPort] = useState("25565")
  const [memory, setMemory] = useState("2048")
  const [isLoading, setIsLoading] = useState(false)
  const [progress, setProgress] = useState(0)

  const handleDownload = async () => {
    if (!serverName) {
      alert("Please enter a server name")
      return
    }

    setIsLoading(true)
    setProgress(0)

    try {
      // Call the server creation script via API
      const response = await fetch("/api/servers", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          serverName,
          serverType,
          serverVersion: mcVersion,
          port,
          memory,
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to create server")
      }

      // Simulate progress updates
      const interval = setInterval(() => {
        setProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval)
            return 100
          }
          return prev + 10
        })
      }, 500)

      // Wait for the simulated progress to complete
      setTimeout(() => {
        clearInterval(interval)
        setProgress(100)
        setIsLoading(false)
        alert("Server created successfully!")
        setServerName("")
      }, 5000)
    } catch (error) {
      console.error("Error creating server:", error)
      setIsLoading(false)
      alert("Failed to create server")
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader>
        <CardTitle>Create New Minecraft Server</CardTitle>
        <CardDescription>Configure and download a new Minecraft server</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="serverName">Server Name</Label>
          <Input
            id="serverName"
            value={serverName}
            onChange={(e) => setServerName(e.target.value)}
            placeholder="My Minecraft Server"
            className="bg-slate-800 border-slate-700"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="serverType">Server Type</Label>
          <Select value={serverType} onValueChange={setServerType}>
            <SelectTrigger id="serverType" className="bg-slate-800 border-slate-700">
              <SelectValue placeholder="Select server type" />
            </SelectTrigger>
            <SelectContent className="bg-slate-800 border-slate-700">
              <SelectItem value="vanilla">Vanilla</SelectItem>
              <SelectItem value="paper">Paper</SelectItem>
              <SelectItem value="spigot">Spigot</SelectItem>
              <SelectItem value="forge">Forge</SelectItem>
              <SelectItem value="fabric">Fabric</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label htmlFor="mcVersion">Minecraft Version</Label>
          <Select value={mcVersion} onValueChange={setMcVersion}>
            <SelectTrigger id="mcVersion" className="bg-slate-800 border-slate-700">
              <SelectValue placeholder="Select version" />
            </SelectTrigger>
            <SelectContent className="bg-slate-800 border-slate-700">
              <SelectItem value="1.19.2">1.19.2</SelectItem>
              <SelectItem value="1.18.2">1.18.2</SelectItem>
              <SelectItem value="1.17.1">1.17.1</SelectItem>
              <SelectItem value="1.16.5">1.16.5</SelectItem>
              <SelectItem value="1.12.2">1.12.2</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label htmlFor="port">Server Port</Label>
          <Input
            id="port"
            type="number"
            value={port}
            onChange={(e) => setPort(e.target.value)}
            className="bg-slate-800 border-slate-700"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="memory">Memory (MB)</Label>
          <Input
            id="memory"
            type="number"
            value={memory}
            onChange={(e) => setMemory(e.target.value)}
            className="bg-slate-800 border-slate-700"
          />
        </div>

        {isLoading && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Creating server...</span>
              <span>{progress}%</span>
            </div>
            <Progress value={progress} className="h-2" />
          </div>
        )}
      </CardContent>
      <CardFooter>
        <Button
          onClick={handleDownload}
          disabled={isLoading || !serverName}
          className="w-full bg-emerald-600 hover:bg-emerald-500"
        >
          <Download className="mr-2 h-4 w-4" />
          {isLoading ? "Creating Server..." : "Create Server"}
        </Button>
      </CardFooter>
    </Card>
  )
}
EOF

# Create API routes for server operations
mkdir -p ${WEB_DIR}/app/api/servers
cat > ${WEB_DIR}/app/api/servers/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"

const execAsync = promisify(exec)
const SERVERS_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"
const SCRIPTS_PATH = process.env.SCRIPTS_PATH || "/opt/minecraft/scripts"

export async function GET() {
  try {
    // Check if servers directory exists
    try {
      await fs.access(SERVERS_PATH)
    } catch (error) {
      await fs.mkdir(SERVERS_PATH, { recursive: true })
      return NextResponse.json({ servers: [] })
    }

    // Read server directories
    const dirs = await fs.readdir(SERVERS_PATH, { withFileTypes: true })
    const serverDirs = dirs.filter(dir => dir.isDirectory())
    
    // Get server info from each directory
    const servers = []
    
    for (const dir of serverDirs) {
      try {
        const serverPath = path.join(SERVERS_PATH, dir.name)
        const configPath = path.join(serverPath, "server.json")
        
        // Check if server.json exists
        try {
          const configData = await fs.readFile(configPath, "utf-8")
          const config = JSON.parse(configData)
          
          // Check if server is running
          const { stdout } = await execAsync(\`ps aux | grep -v grep | grep "java.*\${dir.name}/server.jar" || true\`)
          const isRunning = stdout.trim() !== ""
          
          servers.push({
            id: dir.name,
            name: config.name || dir.name,
            type: config.type || "unknown",
            version: config.version || "unknown",
            status: isRunning ? "online" : "offline",
            port: config.port || "25565",
            players: {
              online: 0,
              max: config.maxPlayers || 20,
            },
            memory: {
              used: isRunning ? Math.floor(Math.random() * config.memory) : 0,
              allocated: config.memory || 1024,
            },
            uptime: isRunning ? "1h 30m" : "0h 0m", // In a real implementation, this would be calculated
          })
        } catch (error) {
          console.error(\`Error reading server config for \${dir.name}:\`, error)
        }
      } catch (error) {
        console.error(\`Error processing server \${dir.name}:\`, error)
      }
    }
    
    return NextResponse.json({ servers })
  } catch (error) {
    console.error("Error getting servers:", error)
    return NextResponse.json({ error: "Failed to get servers" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const data = await request.json()
    const { serverName, serverType, serverVersion, port, memory } = data

    if (!serverName) {
      return NextResponse.json({ error: "Server name is required" }, { status: 400 })
    }

    // Create a safe directory name
    const dirName = serverName.toLowerCase().replace(/[^a-z0-9]/g, "-")
    const serverPath = path.join(SERVERS_PATH, dirName)

    // Check if server directory already exists
    try {
      await fs.access(serverPath)
      return NextResponse.json({ error: "Server with this name already exists" }, { status: 400 })
    } catch (error) {
      // Directory doesn't exist, we can proceed
    }

    // Create server directory
    await fs.mkdir(serverPath, { recursive: true })

    // Create server.json configuration file
    const serverConfig = {
      name: serverName,
      type: serverType || "vanilla",
      version: serverVersion || "1.19.2",
      port: port || "25565",
      memory: parseInt(memory || "2048"),
      maxPlayers: 20,
      created: new Date().toISOString(),
    }

    await fs.writeFile(
      path.join(serverPath, "server.json"),
      JSON.stringify(serverConfig, null, 2)
    )

    // Run the server creation script
    const scriptPath = path.join(SCRIPTS_PATH, "create-server.sh")
    
    // Create the script if it doesn't exist
    try {
      await fs.access(scriptPath)
    } catch (error) {
      // Create a basic server creation script
      const scriptContent = \`#!/bin/bash
# Minecraft Server Creation Script
# This script downloads and sets up a Minecraft server

SERVER_PATH=\$1
SERVER_TYPE=\$2
MC_VERSION=\$3
SERVER_PORT=\$4
MEMORY=\$5

echo "Creating \$SERVER_TYPE server version \$MC_VERSION in \$SERVER_PATH"

# Create directory structure
mkdir -p "\$SERVER_PATH"
cd "\$SERVER_PATH"

# Download server jar based on type
if [ "\$SERVER_TYPE" = "paper" ]; then
  # Download Paper
  echo "Downloading Paper \$MC_VERSION..."
  wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/\$MC_VERSION/builds/latest/downloads/paper-\$MC_VERSION-latest.jar"
elif [ "\$SERVER_TYPE" = "spigot" ]; then
  # Download Spigot
  echo "Downloading Spigot \$MC_VERSION..."
  wget -O server.jar "https://download.getbukkit.org/spigot/spigot-\$MC_VERSION.jar"
elif [ "\$SERVER_TYPE" = "forge" ]; then
  # Download Forge (simplified)
  echo "Downloading Forge \$MC_VERSION..."
  wget -O server.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/\$MC_VERSION-latest/forge-\$MC_VERSION-latest-installer.jar"
elif [ "\$SERVER_TYPE" = "fabric" ]; then
  # Download Fabric
  echo "Downloading Fabric \$MC_VERSION..."
  wget -O server.jar "https://meta.fabricmc.net/v2/versions/loader/\$MC_VERSION/0.14.21/0.11.2/server/jar"
else
  # Download Vanilla
  echo "Downloading Vanilla \$MC_VERSION..."
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
query.port=\$SERVER_PORT
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
server-port=\$SERVER_PORT
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
function-permission-level=2
level-type=minecraft\\\\:normal
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
max-world-size=29999984
EOL

# Create eula.txt
echo "eula=true" > eula.txt

# Create start script
cat > start.sh << EOL
#!/bin/bash
java -Xms\${MEMORY}M -Xmx\${MEMORY}M -jar server.jar nogui
EOL

chmod +x start.sh

# Create systemd service file
SERVICE_NAME=\$(basename "\$SERVER_PATH" | tr '.' '-')
cat > /etc/systemd/system/minecraft-\$SERVICE_NAME.service << EOL
[Unit]
Description=Minecraft Server - \$(basename "\$SERVER_PATH")
After=network.target

[Service]
WorkingDirectory=\$SERVER_PATH
User=root
Group=root
Restart=always
ExecStart=\$SERVER_PATH/start.sh

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd
systemctl daemon-reload
systemctl enable minecraft-\$SERVICE_NAME.service

echo "Server setup complete!"
\`
      
      await fs.writeFile(scriptPath, scriptContent)
      await fs.chmod(scriptPath, 0o755)
    }

    // Execute the script
    await execAsync(\`\${scriptPath} "\${serverPath}" "\${serverType}" "\${serverVersion}" "\${port}" "\${memory}"\`)

    return NextResponse.json({
      success: true,
      message: "Server created successfully",
      server: {
        id: dirName,
        name: serverName,
        type: serverType,
        version: serverVersion,
        status: "offline",
        port: port,
        players: {
          online: 0,
          max: 20,
        },
        memory: {
          used: 0,
          allocated: parseInt(memory),
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

# Create API routes for server control
mkdir -p ${WEB_DIR}/app/api/servers/[id]/start
cat > ${WEB_DIR}/app/api/servers/[id]/start/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"

const execAsync = promisify(exec)
const SERVERS_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function POST(request: Request, { params }: { params: { id: string } }) {
  try {
    const serverId = params.id
    const serverPath = path.join(SERVERS_PATH, serverId)
    
    // Check if server directory exists
    try {
      await fs.access(serverPath)
    } catch (error) {
      return NextResponse.json({ error: "Server not found" }, { status: 404 })
    }
    
    // Check if server is already running
    const { stdout } = await execAsync(\`ps aux | grep -v grep | grep "java.*\${serverId}/server.jar" || true\`)
    if (stdout.trim() !== "") {
      return NextResponse.json({ message: "Server is already running" })
    }
    
    // Start the server using systemd
    await execAsync(\`systemctl start minecraft-\${serverId}\`)
    
    return NextResponse.json({ success: true, message: "Server started" })
  } catch (error) {
    console.error("Error starting server:", error)
    return NextResponse.json({ error: "Failed to start server" }, { status: 500 })
  }
}
EOF

mkdir -p ${WEB_DIR}/app/api/servers/[id]/stop
cat > ${WEB_DIR}/app/api/servers/[id]/stop/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"

const execAsync = promisify(exec)
const SERVERS_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function POST(request: Request, { params }: { params: { id: string } }) {
  try {
    const serverId = params.id
    const serverPath = path.join(SERVERS_PATH, serverId)
    
    // Check if server directory exists
    try {
      await fs.access(serverPath)
    } catch (error) {
      return NextResponse.json({ error: "Server not found" }, { status: 404 })
    }
    
    // Check if server is running
    const { stdout } = await execAsync(\`ps aux | grep -v grep | grep "java.*\${serverId}/server.jar" || true\`)
    if (stdout.trim() === "") {
      return NextResponse.json({ message: "Server is not running" })
    }
    
    // Stop the server using systemd
    await execAsync(\`systemctl stop minecraft-\${serverId}\`)
    
    return NextResponse.json({ success: true, message: "Server stopped" })
  } catch (error) {
    console.error("Error stopping server:", error)
    return NextResponse.json({ error: "Failed to stop server" }, { status: 500 })
  }
}
EOF

# Create API routes for system operations
mkdir -p ${WEB_DIR}/app/api/system/status
cat > ${WEB_DIR}/app/api/system/status/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function GET() {
  try {
    // Get CPU usage
    const { stdout: cpuStdout } = await execAsync("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")
    const cpu = parseFloat(cpuStdout.trim())
    
    // Get memory usage
    const { stdout: memStdout } = await execAsync("free -m | grep Mem")
    const memParts = memStdout.trim().split(/\s+/)
    const memTotal = parseInt(memParts[1]) / 1024
    const memUsed = parseInt(memParts[2]) / 1024
    
    // Get disk usage
    const { stdout:  / 1024
    const memUsed = parseInt(memParts[2]) / 1024
    
    // Get disk usage
    const { stdout: diskStdout } = await execAsync("df -h / | tail -1")
    const diskParts = diskStdout.trim().split(/\s+/)
    const diskTotal = parseFloat(diskParts[1].replace('G', ''))
    const diskUsed = parseFloat(diskParts[2].replace('G', ''))
    
    // Get system info
    const { stdout: hostnameStdout } = await execAsync("hostname")
    const hostname = hostnameStdout.trim()
    
    const { stdout: kernelStdout } = await execAsync("uname -r")
    const kernel = kernelStdout.trim()
    
    const { stdout: archStdout } = await execAsync("uname -m")
    const arch = archStdout.trim()
    
    const { stdout: uptimeStdout } = await execAsync("uptime -p")
    const uptime = uptimeStdout.trim().replace('up ', '')
    
    return NextResponse.json({
      resources: {
        cpu: Math.round(cpu * 10) / 10,
        memory: {
          used: Math.round(memUsed * 10) / 10,
          total: Math.round(memTotal * 10) / 10,
        },
        disk: {
          used: Math.round(diskUsed * 10) / 10,
          total: Math.round(diskTotal * 10) / 10,
        },
      },
      os: {
        version: "MinecraftOS 1.0.0",
        kernel: `Linux ${kernel}`,
        arch: arch,
        hostname: hostname,
        uptime: uptime,
      },
    })
  } catch (error) {
    console.error("Error getting system status:", error)
    return NextResponse.json({ error: "Failed to get system status" }, { status: 500 })
  }
}
EOF

# Create API routes for system network settings
mkdir -p ${WEB_DIR}/app/api/system/network
cat > ${WEB_DIR}/app/api/system/network/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"

const execAsync = promisify(exec)

export async function GET() {
  try {
    // Read network configuration
    const { stdout: ipStdout } = await execAsync("ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1")
    const ipMatch = ipStdout.match(/inet\s+(\d+\.\d+\.\d+\.\d+)\/(\d+)/)
    
    const ipAddress = ipMatch ? ipMatch[1] : ""
    const cidr = ipMatch ? ipMatch[2] : ""
    
    // Convert CIDR to subnet mask
    let subnetMask = "255.255.255.0"
    if (cidr) {
      const { stdout: maskStdout } = await execAsync(`ipcalc ${ipAddress}/${cidr} | grep Netmask | awk '{print $2}'`)
      subnetMask = maskStdout.trim()
    }
    
    // Get gateway
    const { stdout: gwStdout } = await execAsync("ip route | grep default | awk '{print $3}'")
    const gateway = gwStdout.trim()
    
    // Get DNS
    const { stdout: dnsStdout } = await execAsync("cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}'")
    const dns = dnsStdout.trim()
    
    // Determine if using DHCP or static
    const { stdout: dhcpStdout } = await execAsync("ps aux | grep -v grep | grep dhclient || true")
    const networkConfig = dhcpStdout.trim() !== "" ? "dhcp" : "static"
    
    return NextResponse.json({
      networkConfig,
      ipAddress,
      subnetMask,
      gateway,
      dns,
    })
  } catch (error) {
    console.error("Error getting network settings:", error)
    return NextResponse.json({ error: "Failed to get network settings" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const data = await request.json()
    const { networkConfig, ipAddress, subnetMask, gateway, dns } = data
    
    // Create network configuration script
    const scriptContent = \`#!/bin/bash
# Network configuration script

if [ "\${networkConfig}" = "dhcp" ]; then
  # Configure DHCP
  cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
else
  # Configure static IP
  cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address \${ipAddress}
  netmask \${subnetMask}
  gateway \${gateway}
  dns-nameservers \${dns}
EOF
fi

# Update resolv.conf
echo "nameserver \${dns}" > /etc/resolv.conf

# Restart networking
systemctl restart networking
\`
    
    // Write script to temporary file
    const scriptPath = "/tmp/network-config.sh"
    await fs.writeFile(scriptPath, scriptContent)
    await fs.chmod(scriptPath, 0o755)
    
    // Execute script
    await execAsync(scriptPath)
    
    return NextResponse.json({ success: true, message: "Network settings updated" })
  } catch (error) {
    console.error("Error updating network settings:", error)
    return NextResponse.json({ error: "Failed to update network settings" }, { status: 500 })
  }
}
EOF

# Create API routes for system restart/shutdown
mkdir -p ${WEB_DIR}/app/api/system/restart
cat > ${WEB_DIR}/app/api/system/restart/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"

export async function POST() {
  try {
    // Schedule a reboot in 5 seconds
    exec("sleep 5 && reboot &")
    
    return NextResponse.json({ success: true, message: "System restart initiated" })
  } catch (error) {
    console.error("Error restarting system:", error)
    return NextResponse.json({ error: "Failed to restart system" }, { status: 500 })
  }
}
EOF

mkdir -p ${WEB_DIR}/app/api/system/shutdown
cat > ${WEB_DIR}/app/api/system/shutdown/route.ts << EOF
import { NextResponse } from "next/server"
import { exec } from "child_process"

export async function POST() {
  try {
    // Schedule a shutdown in 5 seconds
    exec("sleep 5 && shutdown -h now &")
    
    return NextResponse.json({ success: true, message: "System shutdown initiated" })
  } catch (error) {
    console.error("Error shutting down system:", error)
    return NextResponse.json({ error: "Failed to shut down system" }, { status: 500 })
  }
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
BACKUP_PATH=${BACKUPS_DIR}
SERVERS_PATH=${SERVERS_DIR}
DOWNLOADS_PATH=${DOWNLOADS_DIR}
CONFIG_PATH=${CONFIG_DIR}
JWT_SECRET=${JWT_SECRET}
EOF

# Create server creation script
mkdir -p ${SCRIPTS_DIR}
cat > ${SCRIPTS_DIR}/create-server.sh << EOF
#!/bin/bash
# Minecraft Server Creation Script
# This script downloads and sets up a Minecraft server

SERVER_PATH=\$1
SERVER_TYPE=\$2
MC_VERSION=\$3
SERVER_PORT=\$4
MEMORY=\$5

echo "Creating \$SERVER_TYPE server version \$MC_VERSION in \$SERVER_PATH"

# Create directory structure
mkdir -p "\$SERVER_PATH"
cd "\$SERVER_PATH"

# Download server jar based on type
if [ "\$SERVER_TYPE" = "paper" ]; then
  # Download Paper
  echo "Downloading Paper \$MC_VERSION..."
  wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/\$MC_VERSION/builds/latest/downloads/paper-\$MC_VERSION-latest.jar"
elif [ "\$SERVER_TYPE" = "spigot" ]; then
  # Download Spigot
  echo "Downloading Spigot \$MC_VERSION..."
  wget -O server.jar "https://download.getbukkit.org/spigot/spigot-\$MC_VERSION.jar"
elif [ "\$SERVER_TYPE" = "forge" ]; then
  # Download Forge (simplified)
  echo "Downloading Forge \$MC_VERSION..."
  wget -O server.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/\$MC_VERSION-latest/forge-\$MC_VERSION-latest-installer.jar"
elif [ "\$SERVER_TYPE" = "fabric" ]; then
  # Download Fabric
  echo "Downloading Fabric \$MC_VERSION..."
  wget -O server.jar "https://meta.fabricmc.net/v2/versions/loader/\$MC_VERSION/0.14.21/0.11.2/server/jar"
else
  # Download Vanilla
  echo "Downloading Vanilla \$MC_VERSION..."
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
query.port=\$SERVER_PORT
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
server-port=\$SERVER_PORT
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
function-permission-level=2
level-type=minecraft\\:normal
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
max-world-size=29999984
EOL

# Create eula.txt
echo "eula=true" > eula.txt

# Create start script
cat > start.sh << EOL
#!/bin/bash
java -Xms\${MEMORY}M -Xmx\${MEMORY}M -jar server.jar nogui
EOL

chmod +x start.sh

# Create systemd service file
SERVICE_NAME=\$(basename "\$SERVER_PATH" | tr '.' '-')
cat > /etc/systemd/system/minecraft-\$SERVICE_NAME.service << EOL
[Unit]
Description=Minecraft Server - \$(basename "\$SERVER_PATH")
After=network.target

[Service]
WorkingDirectory=\$SERVER_PATH
User=root
Group=root
Restart=always
ExecStart=\$SERVER_PATH/start.sh

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd
systemctl daemon-reload
systemctl enable minecraft-\$SERVICE_NAME.service

echo "Server setup complete!"
EOF

chmod +x ${SCRIPTS_DIR}/create-server.sh

# Create server start/stop scripts
cat > ${SCRIPTS_DIR}/start-server.sh << EOF
#!/bin/bash
# Start a Minecraft server

SERVER_ID=\$1

if [ -z "\$SERVER_ID" ]; then
  echo "Usage: \$0 <server-id>"
  exit 1
fi

systemctl start minecraft-\$SERVER_ID
EOF

chmod +x ${SCRIPTS_DIR}/start-server.sh

cat > ${SCRIPTS_DIR}/stop-server.sh << EOF
#!/bin/bash
# Stop a Minecraft server

SERVER_ID=\$1

if [ -z "\$SERVER_ID" ]; then
  echo "Usage: \$0 <server-id>"
  exit 1
fi

systemctl stop minecraft-\$SERVER_ID
EOF

chmod +x ${SCRIPTS_DIR}/stop-server.sh

# Create initial admin user
mkdir -p ${CONFIG_DIR}
cat > ${CONFIG_DIR}/users.json << EOF
{
  "users": [
    {
      "id": "1",
      "username": "${ADMIN_USER}",
      "password": "$(echo -n "${ADMIN_PASSWORD}" | node -e "const bcrypt = require('bcrypt'); bcrypt.hash(process.stdin.toString().trim(), 10).then(hash => console.log(hash))")",
      "role": "admin"
    }
  ]
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
Environment=JWT_SECRET=${JWT_SECRET}
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

echo "====================================="
echo "MinecraftOS Web Interface Setup Complete!"
echo "====================================="
echo "Access the web interface at http://$HOSTNAME:8080"
echo "Login with username: ${ADMIN_USER}"
echo "====================================="
