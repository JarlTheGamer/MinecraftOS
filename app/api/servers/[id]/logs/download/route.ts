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
      return NextResponse.json({ error: "Log file not found" }, { status: 404 })
    }

    // Read log file
    const logContent = await fs.readFile(logPath, "utf-8")

    // Create response with log file content
    const response = new NextResponse(logContent)
    response.headers.set("Content-Type", "text/plain")
    response.headers.set("Content-Disposition", `attachment; filename="minecraft-server-${serverId}.log"`)

    return response
  } catch (error) {
    console.error(`Error downloading logs for server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to download server logs" }, { status: 500 })
  }
}
