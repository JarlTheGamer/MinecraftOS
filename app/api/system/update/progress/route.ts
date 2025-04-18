import { NextResponse } from "next/server"

// Externe referentie naar de activeUpdates Map uit de install route
declare const activeUpdates: Map<string, any>

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const updateId = searchParams.get("id")

  if (!updateId) {
    return NextResponse.json({ error: "Update ID is required" }, { status: 400 })
  }

  try {
    // Controleer of de update bestaat
    if (typeof activeUpdates !== "undefined" && activeUpdates.has(updateId)) {
      return NextResponse.json(activeUpdates.get(updateId))
    }

    // Update niet gevonden
    return NextResponse.json({ error: "Update not found" }, { status: 404 })
  } catch (error) {
    console.error(`Error checking update progress for ${updateId}:`, error)
    return NextResponse.json({ error: "Failed to check update progress" }, { status: 500 })
  }
}
