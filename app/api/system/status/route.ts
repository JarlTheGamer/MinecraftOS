import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import os from "os"
import fs from "fs/promises"

const execAsync = promisify(exec)

export async function GET() {
  try {
    // Get real system information
    const uptime = os.uptime()
    const uptimeHours = Math.floor(uptime / 3600)
    const uptimeMinutes = Math.floor((uptime % 3600) / 60)

    // Get CPU usage
    const { stdout: cpuStdout } = await execAsync("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")
    const cpuUsage = Number.parseFloat(cpuStdout) || 0

    // Get memory information
    const totalMemory = Math.round((os.totalmem() / (1024 * 1024 * 1024)) * 10) / 10 // GB
    const freeMemory = Math.round((os.freemem() / (1024 * 1024 * 1024)) * 10) / 10 // GB
    const usedMemory = Math.round((totalMemory - freeMemory) * 10) / 10

    // Get disk information
    const { stdout: diskStdout } = await execAsync("df -h / | awk 'NR==2 {print $2,$3,$4}'")
    const [totalDisk, usedDisk, freeDisk] = diskStdout.trim().split(" ")

    // Convert to GB if needed
    const parseDiskSize = (size: string) => {
      const num = Number.parseFloat(size)
      if (size.endsWith("T")) return num * 1024
      if (size.endsWith("G")) return num
      if (size.endsWith("M")) return num / 1024
      return num
    }

    // Check if setup is complete
    let setupComplete = false
    try {
      await fs.access("/opt/minecraft/setup_complete")
      setupComplete = true
    } catch {
      // File doesn't exist, setup not complete
    }

    // Get kernel version
    const { stdout: kernelStdout } = await execAsync("uname -r")

    // Get hostname
    const hostname = os.hostname()

    return NextResponse.json({
      setupComplete,
      version: "1.0.0",
      uptime: `${uptimeHours}h ${uptimeMinutes}m`,
      kernel: kernelStdout.trim(),
      hostname,
      resources: {
        cpu: Math.round(cpuUsage),
        memory: {
          used: usedMemory,
          total: totalMemory,
        },
        disk: {
          used: parseDiskSize(usedDisk),
          total: parseDiskSize(totalDisk),
          free: parseDiskSize(freeDisk),
        },
      },
    })
  } catch (error) {
    console.error("Error getting system status:", error)

    // Fallback to basic information if we can't get real data
    return NextResponse.json({
      setupComplete: false,
      version: "1.0.0",
      uptime: "Unknown",
      resources: {
        cpu: 0,
        memory: {
          used: 0,
          total: 0,
        },
        disk: {
          used: 0,
          total: 0,
          free: 0,
        },
      },
      error: "Failed to get system information",
    })
  }
}
