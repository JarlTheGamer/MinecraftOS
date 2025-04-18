import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import crypto from "crypto"

// Config file path
const CONFIG_PATH = process.env.CONFIG_PATH || "/opt/minecraft/config"
const REMOTE_ACCESS_CONFIG = path.join(CONFIG_PATH, "remote-access.json")

export async function POST() {
  try {
    // Generate a secure random 6-digit PIN
    const pin = crypto.randomInt(100000, 999999).toString()

    // Read existing config
    let config
    try {
      const configData = await fs.readFile(REMOTE_ACCESS_CONFIG, "utf-8")
      config = JSON.parse(configData)
    } catch (error) {
      // Config doesn't exist, create default
      config = {
        enabled: true,
        port: 8192,
      }
    }

    // Update PIN
    config.pin = pin

    // Save updated config
    await fs.mkdir(CONFIG_PATH, { recursive: true })
    await fs.writeFile(REMOTE_ACCESS_CONFIG, JSON.stringify(config, null, 2))

    return NextResponse.json({ success: true, pin })
  } catch (error) {
    console.error("Error generating PIN:", error)
    return NextResponse.json({ error: "Failed to generate PIN" }, { status: 500 })
  }
}
