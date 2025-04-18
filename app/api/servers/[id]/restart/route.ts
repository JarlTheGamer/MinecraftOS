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
    const serverConfigPath = path.join(serverDir, "server.json")
    const pidFile = path.join(serverDir, "server.pid")

    const serverConfigExists = await fs.stat(serverConfigPath).catch(() => false)
    if (!serverConfigExists) {
      return NextResponse.json({ error: "Server not found" }, { status: 404 })
    }

    const serverConfig = JSON.parse(await fs.readFile(serverConfigPath, "utf-8"))

    // Check if server is running
    const pidFileExists = await fs.stat(pidFile).catch(() => false)
    if (pidFileExists) {
      const pid = (await fs.readFile(pidFile, "utf-8")).trim()

      // Stop the server
      await execAsync(`kill ${pid}`)
      await fs.unlink(pidFile)

      // Wait for server to fully stop
      await new Promise((resolve) => setTimeout(resolve, 2000))
    }

    // Start the server
    const javaPath = "/usr/bin/java"
    const memoryFlag = `-Xmx${serverConfig.memory}M -Xms${Math.floor(serverConfig.memory / 2)}M`
    const jarFile = path.join(serverDir, serverConfig.jarFile || "server.jar")

    // Create start command
    const startCommand = `cd ${serverDir} && ${javaPath} ${memoryFlag} -jar ${jarFile} nogui`

    // Start the server
    await execAsync(`nohup ${startCommand} > ${serverDir}/logs/latest.log 2>&1 &`)

    // Save the PID
    const { stdout } = await execAsync("echo $!")
    await fs.writeFile(pidFile, stdout.trim())

    return NextResponse.json({ success: true, message: "Server restarted" })
  } catch (error) {
    console.error(`Error restarting server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to restart server" }, { status: 500 })
  }
}
