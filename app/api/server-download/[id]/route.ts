import { NextResponse } from "next/server"
import fs from "fs/promises"
import path from "path"

// Base path for downloads
const DOWNLOADS_PATH = process.env.DOWNLOADS_PATH || "/opt/minecraft/downloads"

// External reference to the activeDownloads Map from the main route
declare const activeDownloads: Map<string, any>

export async function GET(request: Request, { params }: { params: { id: string } }) {
  const downloadId = params.id

  try {
    // Check if download exists in memory
    if (typeof activeDownloads !== "undefined" && activeDownloads.has(downloadId)) {
      return NextResponse.json(activeDownloads.get(downloadId))
    }

    // If not in memory, try to read progress file
    const progressFilePath = path.join(DOWNLOADS_PATH, `${downloadId}.progress`)

    try {
      const progressContent = await fs.readFile(progressFilePath, "utf-8")
      const progress = Number.parseInt(progressContent.replace("%", ""), 10) || 0

      return NextResponse.json({
        status: progress === 100 ? "completed" : "downloading",
        progress,
      })
    } catch (readError) {
      // Check if there's a completed file
      const completedFilePath = path.join(DOWNLOADS_PATH, `${downloadId}.completed`)

      try {
        const completedData = await fs.readFile(completedFilePath, "utf-8")
        return NextResponse.json({
          status: "completed",
          progress: 100,
          ...JSON.parse(completedData),
        })
      } catch (completedError) {
        // Neither progress nor completed file exists
        return NextResponse.json({ error: "Download not found" }, { status: 404 })
      }
    }
  } catch (error) {
    console.error(`Error checking download status for ${downloadId}:`, error)
    return NextResponse.json({ error: "Failed to check download status" }, { status: 500 })
  }
}
