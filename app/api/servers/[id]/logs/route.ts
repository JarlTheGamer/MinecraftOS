import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"

// Base path for server installations
const SERVERS_BASE_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function GET(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    const serverDir = path.join(SERVERS_BASE_PATH, `server_${serverId}`)
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
