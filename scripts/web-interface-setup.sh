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
