import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"
import { v4 as uuidv4 } from "uuid"

const execAsync = promisify(exec)

// Base path for downloads
const DOWNLOADS_PATH = process.env.DOWNLOADS_PATH || "/opt/minecraft/downloads"
const SERVERS_PATH = process.env.SERVERS_PATH || "/opt/minecraft/servers"

// Track downloads
const activeDownloads = new Map()

export async function POST(request: Request) {
  try {
    const { serverType, mcVersion, buildVersion } = await request.json()

    if (!serverType || !mcVersion || !buildVersion) {
      return NextResponse.json({ error: "Missing required parameters" }, { status: 400 })
    }

    // Create a unique ID for this download
    const downloadId = uuidv4()

    // Ensure download directory exists
    await fs.mkdir(DOWNLOADS_PATH, { recursive: true })

    // Get download URL based on server type
    let downloadUrl = ""
    let outputFileName = ""

    if (serverType === "paper") {
      downloadUrl = `https://api.papermc.io/v2/projects/paper/versions/${mcVersion}/builds/${buildVersion}/downloads/paper-${mcVersion}-${buildVersion}.jar`
      outputFileName = `paper-${mcVersion}-${buildVersion}.jar`
    } else if (serverType === "purpur") {
      downloadUrl = `https://api.purpurmc.org/v2/purpur/${mcVersion}/${buildVersion}/download`
      outputFileName = `purpur-${mcVersion}-${buildVersion}.jar`
    } else if (serverType === "fabric") {
      downloadUrl = `https://meta.fabricmc.net/v2/versions/loader/${mcVersion}/${buildVersion}/server/jar`
      outputFileName = `fabric-server-${mcVersion}-${buildVersion}.jar`
    } else if (serverType === "forge") {
      // Forge requires a more complex installation process
      downloadUrl = `https://maven.minecraftforge.net/net/minecraftforge/forge/${mcVersion}-${buildVersion}/forge-${mcVersion}-${buildVersion}-installer.jar`
      outputFileName = `forge-${mcVersion}-${buildVersion}-installer.jar`
    } else {
      // Vanilla - need to get the server jar URL from version manifest
      const manifestResponse = await fetch("https://launchermeta.mojang.com/mc/game/version_manifest.json")
      const manifest = await manifestResponse.json()

      const versionInfo = manifest.versions.find((v: any) => v.id === mcVersion)
      if (!versionInfo) {
        return NextResponse.json({ error: "Version not found" }, { status: 404 })
      }

      const versionDetailsResponse = await fetch(versionInfo.url)
      const versionDetails = await versionDetailsResponse.json()

      downloadUrl = versionDetails.downloads.server.url
      outputFileName = `minecraft_server.${mcVersion}.jar`
    }

    const outputPath = path.join(DOWNLOADS_PATH, outputFileName)

    // Start download in background
    activeDownloads.set(downloadId, {
      status: "downloading",
      progress: 0,
      serverType,
      mcVersion,
      buildVersion,
      outputPath,
    })

    // Use wget to download with progress tracking
    const downloadScript = `
      wget -O "${outputPath}" "${downloadUrl}" 2>&1 | 
      awk 'BEGIN{ORS=""}
      /[0-9]+%/ {
        print $NF > "/opt/minecraft/downloads/${downloadId}.progress"
      }'
    `

    // Execute download in background
    exec(downloadScript, async (error) => {
      const downloadInfo = activeDownloads.get(downloadId)

      if (error) {
        console.error(`Download error: ${error}`)
        activeDownloads.set(downloadId, {
          ...downloadInfo,
          status: "failed",
          error: error.message,
        })
        return
      }

      try {
        // Create server directory
        const serverDir = path.join(SERVERS_PATH, `server_${downloadId.substring(0, 8)}`)
        await fs.mkdir(serverDir, { recursive: true })

        // Copy JAR file to server directory
        const serverJarPath = path.join(serverDir, "server.jar")
        await fs.copyFile(outputPath, serverJarPath)

        // Create server.properties file
        const serverProperties = `
          server-port=25565
          gamemode=survival
          difficulty=normal
          spawn-protection=16
          max-players=20
          view-distance=10
          enable-command-block=false
          motd=A Minecraft Server
        `
          .split("\n")
          .map((line) => line.trim())
          .filter(Boolean)
          .join("\n")

        await fs.writeFile(path.join(serverDir, "server.properties"), serverProperties)

        // Create eula.txt
        await fs.writeFile(path.join(serverDir, "eula.txt"), "eula=true\n")

        // Create server.json with configuration
        const serverConfig = {
          id: downloadId.substring(0, 8),
          name: `${serverType}-${mcVersion}`,
          type: serverType,
          version: mcVersion,
          build: buildVersion,
          jarFile: "server.jar",
          memory: 2048,
          port: 25565,
          autoStart: false,
          created: new Date().toISOString(),
        }

        await fs.writeFile(path.join(serverDir, "server.json"), JSON.stringify(serverConfig, null, 2))

        // Create logs directory
        await fs.mkdir(path.join(serverDir, "logs"), { recursive: true })

        // Update download status
        activeDownloads.set(downloadId, {
          ...downloadInfo,
          status: "completed",
          progress: 100,
          serverId: downloadId.substring(0, 8),
          serverPath: serverDir,
        })
      } catch (setupError) {
        console.error(`Server setup error: ${setupError}`)
        activeDownloads.set(downloadId, {
          ...downloadInfo,
          status: "failed",
          error: `Server setup failed: ${setupError.message}`,
        })
      }
    })

    return NextResponse.json({
      downloadId,
      message: "Download started",
      status: "downloading",
    })
  } catch (error) {
    console.error("Error starting download:", error)
    return NextResponse.json({ error: "Failed to start download" }, { status: 500 })
  }
}

export async function GET(request: Request) {
  // Return list of active downloads
  const downloads = Array.from(activeDownloads.entries()).map(([id, info]) => ({
    id,
    ...info,
  }))

  return NextResponse.json({ downloads })
}
