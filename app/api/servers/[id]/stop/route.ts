import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import path from "path"
import fs from "fs/promises"

const execAsync = promisify(exec)

// Base path for server installations
const SERVERS_BASE_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

export async function POST(request: Request, { params }: { params: { id: string } }) {
  const serverId = params.id

  try {
    // Get server details
    const serverDir = path.join(SERVERS_BASE_PATH, `server_${serverId}`)
    const pidFile = path.join(serverDir, "server.pid")

    const pidFileExists = await fs.stat(pidFile).catch(() => false)
    if (!pidFileExists) {
      return NextResponse.json({ error: "Server is not running" }, { status: 400 })
    }

    const pid = (await fs.readFile(pidFile, "utf-8")).trim()

    // In a real implementation, this would use RCON to safely stop the server
    // For demonstration, we'll use the kill command
    await execAsync(`kill ${pid}`)

    // Remove the PID file
    await fs.unlink(pidFile)

    return NextResponse.json({ success: true, message: "Server stopped" })
  } catch (error) {
    console.error(`Error stopping server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to stop server" }, { status: 500 })
  }
}
