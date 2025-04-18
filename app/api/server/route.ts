import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"

const execAsync = promisify(exec)

// In a real implementation, these paths would be configured properly
const SERVER_PATH = process.env.SERVER_PATH || "/path/to/minecraft/server"
const SERVER_JAR = process.env.SERVER_JAR || "server.jar"
const SERVER_PROPERTIES = path.join(SERVER_PATH, "server.properties")

export async function GET() {
  try {
    // Check if server is running
    const { stdout } = await execAsync("ps aux | grep -v grep | grep java | grep minecraft")
    const isRunning = stdout.length > 0

    // Get server properties
    const propertiesExist = await fs.stat(SERVER_PROPERTIES).catch(() => false)
    let properties = {}

    if (propertiesExist) {
      const propertiesFile = await fs.readFile(SERVER_PROPERTIES, "utf-8")
      properties = propertiesFile.split("\n").reduce((acc, line) => {
        const [key, value] = line.split("=")
        if (key && value) {
          acc[key.trim()] = value.trim()
        }
        return acc
      }, {})
    }

    return NextResponse.json({
      status: isRunning ? "online" : "offline",
      properties,
    })
  } catch (error) {
    console.error("Error getting server status:", error)
    return NextResponse.json({ status: "offline", error: "Failed to get server status" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const { action } = await request.json()

  try {
    switch (action) {
      case "start":
        await execAsync(`cd ${SERVER_PATH} && java -Xmx1024M -Xms1024M -jar ${SERVER_JAR} nogui`)
        return NextResponse.json({ success: true, message: "Server started" })

      case "stop":
        // In a real implementation, this would use RCON to safely stop the server
        await execAsync(`pkill -f "${SERVER_JAR}"`)
        return NextResponse.json({ success: true, message: "Server stopped" })

      case "restart":
        await execAsync(`pkill -f "${SERVER_JAR}"`)
        await execAsync(`cd ${SERVER_PATH} && java -Xmx1024M -Xms1024M -jar ${SERVER_JAR} nogui`)
        return NextResponse.json({ success: true, message: "Server restarted" })

      default:
        return NextResponse.json({ error: "Invalid action" }, { status: 400 })
    }
  } catch (error) {
    console.error(`Error performing action ${action}:`, error)
    return NextResponse.json({ error: `Failed to ${action} server` }, { status: 500 })
  }
}
