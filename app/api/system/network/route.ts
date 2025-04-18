import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import os from "os"

const execAsync = promisify(exec)

export async function GET() {
  try {
    // Get hostname
    const hostname = os.hostname()

    // Get network interfaces
    const interfaces = os.networkInterfaces()

    // Find the primary interface (usually eth0 or en0)
    let primaryInterface = null
    let ipAddress = ""

    // First try to find a non-internal interface with IPv4
    for (const [name, addrs] of Object.entries(interfaces)) {
      if (name.startsWith("eth") || name.startsWith("en")) {
        const ipv4 = addrs?.find((addr) => addr.family === "IPv4" && !addr.internal)
        if (ipv4) {
          primaryInterface = name
          ipAddress = ipv4.address
          break
        }
      }
    }

    // If no primary interface found, try any non-internal interface
    if (!primaryInterface) {
      for (const [name, addrs] of Object.entries(interfaces)) {
        const ipv4 = addrs?.find((addr) => addr.family === "IPv4" && !addr.internal)
        if (ipv4) {
          primaryInterface = name
          ipAddress = ipv4.address
          break
        }
      }
    }

    // Get external IP if possible
    let externalIp = ""
    try {
      const { stdout } = await execAsync("curl -s https://api.ipify.org")
      externalIp = stdout.trim()
    } catch (error) {
      console.error("Error getting external IP:", error)
    }

    // Get DNS servers
    let dnsServers: string[] = []
    try {
      const { stdout } = await execAsync("cat /etc/resolv.conf | grep nameserver | awk '{print $2}'")
      dnsServers = stdout.trim().split("\n").filter(Boolean)
    } catch (error) {
      console.error("Error getting DNS servers:", error)
    }

    // Get default gateway
    let gateway = ""
    try {
      const { stdout } = await execAsync("ip route | grep default | awk '{print $3}'")
      gateway = stdout.trim()
    } catch (error) {
      console.error("Error getting default gateway:", error)
    }

    return NextResponse.json({
      hostname,
      interfaces,
      primaryInterface,
      ipAddress,
      externalIp,
      dnsServers,
      gateway,
    })
  } catch (error) {
    console.error("Error getting network information:", error)
    return NextResponse.json({ error: "Failed to get network information" }, { status: 500 })
  }
}
