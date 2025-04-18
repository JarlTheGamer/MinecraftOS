import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"

// In a real implementation, these paths would be configured properly
const SERVER_PATH = process.env.SERVER_PATH || "/path/to/minecraft/server"
const SERVER_PROPERTIES = path.join(SERVER_PATH, "server.properties")

export async function GET() {
  try {
    // Get server properties
    const propertiesExist = await fs.stat(SERVER_PROPERTIES).catch(() => false)

    if (!propertiesExist) {
      return NextResponse.json({ error: "Server properties file not found" }, { status: 404 })
    }

    const propertiesFile = await fs.readFile(SERVER_PROPERTIES, "utf-8")
    const properties = propertiesFile.split("\n").reduce((acc, line) => {
      const [key, value] = line.split("=")
      if (key && value) {
        acc[key.trim()] = value.trim()
      }
      return acc
    }, {})

    return NextResponse.json(properties)
  } catch (error) {
    console.error("Error getting server config:", error)
    return NextResponse.json({ error: "Failed to get server config" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const config = await request.json()

    // Get existing properties
    const propertiesExist = await fs.stat(SERVER_PROPERTIES).catch(() => false)
    let existingProperties = {}

    if (propertiesExist) {
      const propertiesFile = await fs.readFile(SERVER_PROPERTIES, "utf-8")
      existingProperties = propertiesFile.split("\n").reduce((acc, line) => {
        const [key, value] = line.split("=")
        if (key && value) {
          acc[key.trim()] = value.trim()
        }
        return acc
      }, {})
    }

    // Merge with new config
    const newProperties = { ...existingProperties, ...config }

    // Convert to properties format
    const propertiesContent = Object.entries(newProperties)
      .map(([key, value]) => `${key}=${value}`)
      .join("\n")

    // Write to file
    await fs.writeFile(SERVER_PROPERTIES, propertiesContent)

    return NextResponse.json({ success: true, message: "Configuration updated" })
  } catch (error) {
    console.error("Error updating server config:", error)
    return NextResponse.json({ error: "Failed to update server config" }, { status: 500 })
  }
}
