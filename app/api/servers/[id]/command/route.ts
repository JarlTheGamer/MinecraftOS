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

    const serverDir = path.join(SERVERS_BASE_PATH, `server_${serverId}`)
    const pidFile = path.join(serverDir, "server.pid")

    // Check if server is running
    try {
      await fs.access(pidFile)
    } catch (error) {
      return NextResponse.json({ error: "Server is not running" }, { status: 400 })
    }

    // In a real implementation, this would use RCON to send commands to the server
    // For now, we'll use a script that sends commands to the server's stdin

    // First, check if we have an RCON tool installed
    try {
      // Try to use mcrcon if available
      await execAsync(`echo "${command}" | mcrcon -p password -H localhost -P 25575`)

      return NextResponse.json({ success: true, message: "Command sent" })
    } catch (rconError) {
      // If mcrcon fails, try using screen
      try {
        const pid = (await fs.readFile(pidFile, "utf-8")).trim()

        // Check if screen session exists
        const { stdout: screenList } = await execAsync("screen -list")
        const screenName = `minecraft-${serverId}`

        if (screenList.includes(screenName)) {
          // Send command to screen session
          await execAsync(`screen -S ${screenName} -p 0 -X stuff "${command}$(printf '\\r')"`)

          return NextResponse.json({ success: true, message: "Command sent via screen" })
        } else {
          // No screen session, try to use the process directly
          // This is less reliable but worth a try
          await execAsync(`echo "${command}" > /proc/${pid}/fd/0`)

          return NextResponse.json({ success: true, message: "Command sent directly to process" })
        }
      } catch (screenError) {
        console.error("Error sending command via screen:", screenError)
        return NextResponse.json({ error: "Failed to send command to server" }, { status: 500 })
      }
    }
  } catch (error) {
    console.error(`Error sending command to server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to send command" }, { status: 500 })
  }
}
