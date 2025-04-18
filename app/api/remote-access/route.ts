import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

// Config file path
const CONFIG_PATH = process.env.CONFIG_PATH || "/opt/minecraft/config"
const REMOTE_ACCESS_CONFIG = path.join(CONFIG_PATH, "remote-access.json")

export async function GET() {
  try {
    // Ensure config directory exists
    await fs.mkdir(CONFIG_PATH, { recursive: true })

    // Check if config file exists
    try {
      const configData = await fs.readFile(REMOTE_ACCESS_CONFIG, "utf-8")
      return NextResponse.json(JSON.parse(configData))
    } catch (error) {
      // Config doesn't exist, return defaults
      const defaultConfig = {
        enabled: false,
        pin: "",
        port: 8192,
      }

      // Create default config
      await fs.writeFile(REMOTE_ACCESS_CONFIG, JSON.stringify(defaultConfig, null, 2))

      return NextResponse.json(defaultConfig)
    }
  } catch (error) {
    console.error("Error getting remote access config:", error)
    return NextResponse.json({ error: "Failed to get remote access configuration" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const { enabled, pin, port } = await request.json()

    // Validate input
    if (typeof enabled !== "boolean") {
      return NextResponse.json({ error: "Invalid 'enabled' parameter" }, { status: 400 })
    }

    if (enabled && (!pin || pin.length < 6)) {
      return NextResponse.json({ error: "PIN must be at least 6 digits" }, { status: 400 })
    }

    if (port < 1024 || port > 65535) {
      return NextResponse.json({ error: "Port must be between 1024 and 65535" }, { status: 400 })
    }

    // Ensure config directory exists
    await fs.mkdir(CONFIG_PATH, { recursive: true })

    // Save configuration
    const config = { enabled, pin, port }
    await fs.writeFile(REMOTE_ACCESS_CONFIG, JSON.stringify(config, null, 2))

    // Configure firewall if enabled
    if (enabled) {
      try {
        // Check if port is already open
        const { stdout } = await execAsync(`ufw status | grep ${port}`)

        if (!stdout.includes("ALLOW")) {
          // Open port in firewall
          await execAsync(`ufw allow ${port}/tcp`)
        }
      } catch (firewallError) {
        console.error("Error configuring firewall:", firewallError)
        // Continue even if firewall config fails
      }

      // Start remote access service
      try {
        await execAsync("systemctl restart minecraft-remote-access")
      } catch (serviceError) {
        console.error("Error starting remote access service:", serviceError)
      }
    } else {
      // Stop remote access service
      try {
        await execAsync("systemctl stop minecraft-remote-access")
      } catch (serviceError) {
        console.error("Error stopping remote access service:", serviceError)
      }
    }

    return NextResponse.json({ success: true, ...config })
  } catch (error) {
    console.error("Error saving remote access config:", error)
    return NextResponse.json({ error: "Failed to save remote access configuration" }, { status: 500 })
  }
}
