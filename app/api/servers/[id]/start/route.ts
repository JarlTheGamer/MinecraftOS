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
    // Get server details from database or config file
    // In a real implementation, this would fetch from a database
    const serverConfigPath = path.join(SERVERS_BASE_PATH, `server_${serverId}`, "server.json")
    const serverConfigExists = await fs.stat(serverConfigPath).catch(() => false)

    if (!serverConfigExists) {
      return NextResponse.json({ error: "Server not found" }, { status: 404 })
    }

    const serverConfig = JSON.parse(await fs.readFile(serverConfigPath, "utf-8"))
    const serverDir = path.join(SERVERS_BASE_PATH, `server_${serverId}`)

    // Check if server is already running
    const isRunning = await checkIfServerRunning(serverId)
    if (isRunning) {
      return NextResponse.json({ error: "Server is already running" }, { status: 400 })
    }

    // Start the server
    const javaPath = "/usr/bin/java" // In a real implementation, this would be configurable
    const memoryFlag = `-Xmx${serverConfig.memory}M -Xms${Math.floor(serverConfig.memory / 2)}M`
    const jarFile = path.join(serverDir, serverConfig.jarFile || "server.jar")

    // Create start command
    const startCommand = `cd ${serverDir} && ${javaPath} ${memoryFlag} -jar ${jarFile} nogui`

    // In a real implementation, this would use systemd or another service manager
    // For demonstration, we'll use nohup to run in background
    await execAsync(`nohup ${startCommand} > ${serverDir}/logs/latest.log 2>&1 &`)

    // Save the PID to a file for later management
    const { stdout } = await execAsync("echo $!")
    await fs.writeFile(path.join(serverDir, "server.pid"), stdout.trim())

    return NextResponse.json({ success: true, message: "Server started" })
  } catch (error) {
    console.error(`Error starting server ${serverId}:`, error)
    return NextResponse.json({ error: "Failed to start server" }, { status: 500 })
  }
}

async function checkIfServerRunning(serverId: string) {
  try {
    const serverDir = path.join(SERVERS_BASE_PATH, `server_${serverId}`)
    const pidFile = path.join(serverDir, "server.pid")

    const pidFileExists = await fs.stat(pidFile).catch(() => false)
    if (!pidFileExists) return false

    const pid = (await fs.readFile(pidFile, "utf-8")).trim()
    const { stdout } = await execAsync(`ps -p ${pid} -o comm=`)

    return stdout.includes("java")
  } catch (error) {
    return false
  }
}
