import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"
import { exec } from "child_process"
import { promisify } from "util"
import { v4 as uuidv4 } from "uuid"

const execAsync = promisify(exec)

// Configuratie
const INSTALL_DIR = process.env.SERVER_PATH || "/opt/minecraft"
const UPDATE_SCRIPT = path.join(INSTALL_DIR, "scripts", "auto-update.sh")

// Bijhoud van actieve updates
const activeUpdates = new Map()

export async function POST() {
  try {
    // Controleer of het update script bestaat
    try {
      await fs.access(UPDATE_SCRIPT)
    } catch (error) {
      return NextResponse.json({ error: "Update script not found" }, { status: 404 })
    }

    // Genereer een unieke ID voor deze update
    const updateId = uuidv4()

    // Registreer de update
    activeUpdates.set(updateId, {
      status: "preparing",
      progress: 0,
      startTime: new Date().toISOString(),
    })

    // Start het update script in de achtergrond
    const updateProcess = exec(`bash ${UPDATE_SCRIPT}`, (error, stdout, stderr) => {
      if (error) {
        console.error(`Update error: ${error.message}`)
        activeUpdates.set(updateId, {
          ...activeUpdates.get(updateId),
          status: "failed",
          error: error.message,
          stderr,
          endTime: new Date().toISOString(),
        })
        return
      }

      // Update succesvol
      activeUpdates.set(updateId, {
        ...activeUpdates.get(updateId),
        status: "completed",
        progress: 100,
        stdout,
        endTime: new Date().toISOString(),
      })

      // Probeer de nieuwe versie op te halen
      fs.readFile(path.join(INSTALL_DIR, ".version"), "utf-8")
        .then((version) => {
          activeUpdates.set(updateId, {
            ...activeUpdates.get(updateId),
            version: version.trim(),
          })
        })
        .catch((err) => console.error("Error reading version after update:", err))
    })

    // Simuleer voortgang updates
    simulateUpdateProgress(updateId)

    return NextResponse.json({
      updateId,
      message: "Update started",
    })
  } catch (error) {
    console.error("Error starting update:", error)
    return NextResponse.json({ error: "Failed to start update" }, { status: 500 })
  }
}

// Functie om update voortgang te simuleren
function simulateUpdateProgress(updateId: string) {
  let progress = 0
  const interval = setInterval(() => {
    const update = activeUpdates.get(updateId)

    if (!update || update.status === "failed" || update.status === "completed") {
      clearInterval(interval)
      return
    }

    // Verhoog de voortgang
    progress += Math.floor(Math.random() * 10) + 1
    if (progress > 95) progress = 95 // Max 95% voor simulatie

    // Update de status
    activeUpdates.set(updateId, {
      ...update,
      status: progress >= 95 ? "finalizing" : "installing",
      progress,
    })
  }, 2000)
}
