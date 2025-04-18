import { NextResponse } from "next/server"
import fs from "fs/promises"

export async function POST() {
  try {
    // Create a file to indicate setup is complete
    await fs.writeFile("/opt/minecraft/setup_complete", new Date().toISOString())

    return NextResponse.json({
      success: true,
      message: "Setup marked as complete",
    })
  } catch (error) {
    console.error("Error marking setup as complete:", error)
    return NextResponse.json({ error: "Failed to mark setup as complete" }, { status: 500 })
  }
}
