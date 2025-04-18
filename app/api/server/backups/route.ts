import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"

const execAsync = promisify(exec)

// In a real implementation, these paths would be configured properly
const SERVER_PATH = process.env.SERVER_PATH || "/path/to/minecraft/server"
const BACKUP_PATH = process.env.BACKUP_PATH || "/path/to/minecraft/backups"

export async function GET() {
  try {
    // Check if backup directory exists
    const backupDirExists = await fs.stat(BACKUP_PATH).catch(() => false)

    if (!backupDirExists) {
      // Create backup directory if it doesn't exist
      await fs.mkdir(BACKUP_PATH, { recursive: true })
      return NextResponse.json({ backups: [] })
    }

    // Get list of backups
    const files = await fs.readdir(BACKUP_PATH)
    const backups = await Promise.all(
      files
        .filter((file) => file.endsWith(".zip"))
        .map(async (file, index) => {
          const filePath = path.join(BACKUP_PATH, file)
          const stats = await fs.stat(filePath)

          return {
            id: String(index + 1),
            name: file.replace(".zip", ""),
            date: stats.mtime.toLocaleString(),
            size: `${Math.round((stats.size / (1024 * 1024)) * 10) / 10} MB`,
            worldName: "world", // In a real implementation, this would be extracted from the backup
          }
        }),
    )

    return NextResponse.json({ backups })
  } catch (error) {
    console.error("Error getting backups:", error)
    return NextResponse.json({ error: "Failed to get backups" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const { action, backupId } = await request.json()

    switch (action) {
      case "create":
        // In a real implementation, this would create a backup of the server
        const timestamp = new Date().toISOString().replace(/:/g, "-").split(".")[0]
        const backupName = `backup-${timestamp}.zip`
        const backupFile = path.join(BACKUP_PATH, backupName)

        // Ensure backup directory exists
        await fs.mkdir(BACKUP_PATH, { recursive: true })

        // Create backup (this is a simplified example)
        await execAsync(`cd ${SERVER_PATH} && zip -r ${backupFile} world`)

        return NextResponse.json({ success: true, message: "Backup created", backupName })

      case "delete":
        if (!backupId) {
          return NextResponse.json({ error: "No backup specified" }, { status: 400 })
        }

        // Get list of backups
        const files = await fs.readdir(BACKUP_PATH)
        const backups = files.filter((file) => file.endsWith(".zip"))

        if (backupId > backups.length) {
          return NextResponse.json({ error: "Backup not found" }, { status: 404 })
        }

        // Delete backup
        await fs.unlink(path.join(BACKUP_PATH, backups[backupId - 1]))

        return NextResponse.json({ success: true, message: "Backup deleted" })

      default:
        return NextResponse.json({ error: "Invalid action" }, { status: 400 })
    }
  } catch (error) {
    console.error("Error performing backup action:", error)
    return NextResponse.json({ error: "Failed to perform backup action" }, { status: 500 })
  }
}
