import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

// Configuratie
const INSTALL_DIR = process.env.SERVER_PATH || "/opt/minecraft"
const CURRENT_VERSION_FILE = path.join(INSTALL_DIR, ".version")
const LAST_CHECK_FILE = path.join(INSTALL_DIR, ".last_check")

export async function POST() {
  try {
    // Huidige versie ophalen
    let currentVersion = "unknown"
    try {
      currentVersion = await fs.readFile(CURRENT_VERSION_FILE, "utf-8")
    } catch (error) {
      // Bestand bestaat niet, dat is OK
    }

    // Laatste versie ophalen van GitHub
    let latestVersion = "unknown"
    let updateAvailable = false

    try {
      const { stdout } = await execAsync("git ls-remote https://github.com/JarlTheGamer/MinecraftOS HEAD")
      latestVersion = stdout.split("\t")[0].trim()
      updateAvailable = currentVersion !== latestVersion && currentVersion !== "unknown"
    } catch (error) {
      console.error("Error fetching latest version:", error)
      return NextResponse.json({ error: "Failed to check for updates" }, { status: 500 })
    }

    // Update laatste controle tijdstip
    const checkData = {
      date: new Date().toISOString(),
      currentVersion,
      latestVersion,
      updateAvailable,
    }

    await fs.writeFile(LAST_CHECK_FILE, JSON.stringify(checkData))

    return NextResponse.json({
      currentVersion,
      latestVersion,
      updateAvailable,
    })
  } catch (error) {
    console.error("Error checking for updates:", error)
    return NextResponse.json({ error: "Failed to check for updates" }, { status: 500 })
  }
}
