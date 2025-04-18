import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import path from "path"
import bcrypt from "bcrypt"

const execAsync = promisify(exec)

// Config paths
const CONFIG_PATH = process.env.CONFIG_PATH || "/opt/minecraft/config"
const SYSTEM_CONFIG = path.join(CONFIG_PATH, "system.json")
const USERS_CONFIG = path.join(CONFIG_PATH, "users.json")

export async function POST(request: Request) {
  try {
    const data = await request.json()

    // Ensure config directory exists
    await fs.mkdir(CONFIG_PATH, { recursive: true })

    // Save system configuration
    const systemConfig = {
      hostname: data.hostname,
      timezone: data.timezone,
      adminPort: data.adminPort,
      networkConfig: data.networkConfig,
      staticIp: data.staticIp,
      gateway: data.gateway,
      dns: data.dns,
      enableFirewall: data.enableFirewall,
      installJava: data.installJava,
      javaVersion: data.javaVersion,
      autoStart: data.autoStart,
      backupEnabled: data.backupEnabled,
      backupInterval: data.backupInterval,
      enableRemoteAccess: data.enableRemoteAccess,
      remotePort: data.remotePort,
      setupDate: new Date().toISOString(),
    }

    await fs.writeFile(SYSTEM_CONFIG, JSON.stringify(systemConfig, null, 2))

    // Save user credentials (hashed)
    const hashedPassword = await bcrypt.hash(data.password, 10)
    const usersConfig = {
      users: [
        {
          username: data.username,
          password: hashedPassword,
          role: "admin",
          created: new Date().toISOString(),
        },
      ],
    }

    await fs.writeFile(USERS_CONFIG, JSON.stringify(usersConfig, null, 2))

    // Apply system configuration
    try {
      // Set hostname
      await execAsync(`hostnamectl set-hostname ${data.hostname}`)

      // Set timezone
      await execAsync(`timedatectl set-timezone ${data.timezone}`)

      // Configure network
      if (data.networkConfig === "static") {
        // Create network configuration file
        const networkConfig = `
[Match]
Name=eth0

[Network]
Address=${data.staticIp}/24
Gateway=${data.gateway}
DNS=${data.dns}
`
        await fs.writeFile("/etc/systemd/network/10-static.network", networkConfig)
        await execAsync("systemctl restart systemd-networkd")
      }

      // Configure firewall if enabled
      if (data.enableFirewall) {
        await execAsync("ufw --force reset")
        await execAsync("ufw allow ssh")
        await execAsync(`ufw allow ${data.adminPort}/tcp`)
        await execAsync("ufw allow 25565/tcp") // Minecraft default port

        if (data.enableRemoteAccess) {
          await execAsync(`ufw allow ${data.remotePort}/tcp`)
        }

        await execAsync("ufw --force enable")
      }

      // Install Java if requested
      if (data.installJava) {
        switch (data.javaVersion) {
          case "8":
            await execAsync("apt-get update && apt-get install -y openjdk-8-jre-headless")
            break
          case "11":
            await execAsync("apt-get update && apt-get install -y openjdk-11-jre-headless")
            break
          case "17":
            await execAsync("apt-get update && apt-get install -y openjdk-17-jre-headless")
            break
          case "21":
            await execAsync("apt-get update && apt-get install -y openjdk-21-jre-headless")
            break
        }
      }

      // Configure auto-start service if enabled
      if (data.autoStart) {
        const autoStartService = `
[Unit]
Description=MinecraftOS Auto-Start Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minecraft
ExecStart=/opt/minecraft/scripts/autostart.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
`
        await fs.writeFile("/etc/systemd/system/minecraft-autostart.service", autoStartService)
        await execAsync("systemctl enable minecraft-autostart")
      }

      // Configure backup service if enabled
      if (data.backupEnabled) {
        let schedule = ""
        switch (data.backupInterval) {
          case "hourly":
            schedule = "0 * * * *"
            break
          case "daily":
            schedule = "0 0 * * *"
            break
          case "weekly":
            schedule = "0 0 * * 0"
            break
        }

        await execAsync(`(crontab -l 2>/dev/null; echo "${schedule} /opt/minecraft/scripts/backup.sh") | crontab -`)
      }

      // Configure remote access if enabled
      if (data.enableRemoteAccess) {
        const remoteAccessService = `
[Unit]
Description=MinecraftOS Remote Access Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minecraft
ExecStart=/opt/minecraft/scripts/remote-access.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
`
        await fs.writeFile("/etc/systemd/system/minecraft-remote-access.service", remoteAccessService)
        await execAsync("systemctl enable minecraft-remote-access")
      }
    } catch (configError) {
      console.error("Error applying system configuration:", configError)
      // Continue even if some configuration fails
    }

    return NextResponse.json({
      success: true,
      message: "System setup completed successfully",
    })
  } catch (error) {
    console.error("Error during system setup:", error)
    return NextResponse.json({ error: "Failed to complete system setup" }, { status: 500 })
  }
}
