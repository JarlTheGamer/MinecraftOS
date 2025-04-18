import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

// Configuratie
const INSTALL_DIR = process.env.SERVER_PATH || "/opt/minecraft"
const CURRENT_VERSION_FILE = path.join(INSTALL_DIR, ".version")
const LAST_UPDATE_FILE = path.join(INSTALL_DIR, ".last_update")
const LAST_CHECK_FILE = path.join(INSTALL_DIR, ".last_check")

export async function GET() {
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
    }

    // Laatste controle tijdstip ophalen
    let lastChecked = null
    try {
      const checkData = await fs.readFile(LAST_CHECK_FILE, "utf-8")
      const checkJson = JSON.parse(checkData)
      lastChecked = checkJson.date
    } catch (error) {
      // Bestand bestaat niet, dat is OK
    }

    // Laatste update tijdstip ophalen
    let lastUpdated = null
    try {
      const updateData = await fs.readFile(LAST_UPDATE_FILE, "utf-8")
      const updateJson = JSON.parse(updateData)
      lastUpdated = updateJson.date
    } catch (error) {
      // Bestand bestaat niet, dat is OK
    }

    return NextResponse.json({
      currentVersion,
      latestVersion,
      updateAvailable,
      lastChecked,
      lastUpdated,
    })
  } catch (error) {
    console.error("Error getting update status:", error)
    return NextResponse.json({ error: "Failed to get update status" }, { status: 500 })
  }
}
