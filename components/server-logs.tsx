"use client"

import type React from "react"

import { useEffect, useRef, useState } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Download, Send } from "lucide-react"

export function ServerLogs() {
  const [logs, setLogs] = useState<string[]>([
    "[INFO] Starting Minecraft server on 0.0.0.0:25565",
    "[INFO] Loading properties",
    "[INFO] Default game type: SURVIVAL",
    "[INFO] Generating keypair",
    "[INFO] Starting Minecraft server on *:25565",
    "[INFO] Using epoll channel type",
    '[INFO] Preparing level "world"',
    "[INFO] Preparing start region for dimension minecraft:overworld",
    "[INFO] Preparing spawn area: 0%",
    "[INFO] Preparing spawn area: 20%",
    "[INFO] Preparing spawn area: 40%",
    "[INFO] Preparing spawn area: 60%",
    "[INFO] Preparing spawn area: 80%",
    "[INFO] Preparing spawn area: 100%",
    '[INFO] Done (12.345s)! For help, type "help"',
    "[INFO] Server is running in online mode",
    "[INFO] Server is running on port 25565",
  ])
  const [command, setCommand] = useState("")
  const logsEndRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when logs update
  useEffect(() => {
    if (logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: "smooth" })
    }
  }, [logs])

  const sendCommand = (e: React.FormEvent) => {
    e.preventDefault()
    if (!command.trim()) return

    // In a real implementation, this would send the command to the Minecraft server
    setLogs((prev) => [...prev, `> ${command}`, "[INFO] Executed command"])
    setCommand("")
  }

  const downloadLogs = () => {
    // In a real implementation, this would download the full server logs
    const logText = logs.join("\n")
    const blob = new Blob([logText], { type: "text/plain" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "minecraft-server.log"
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex justify-between items-center">
          <div>
            <CardTitle>Server Console</CardTitle>
            <CardDescription>View and interact with the server console</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={downloadLogs}>
            <Download className="h-4 w-4 mr-2" />
            Download Logs
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="bg-black text-green-400 font-mono text-sm p-4 rounded-md h-[400px] overflow-y-auto">
          {logs.map((log, index) => (
            <div key={index} className={log.startsWith(">") ? "text-white" : ""}>
              {log}
            </div>
          ))}
          <div ref={logsEndRef} />
        </div>
      </CardContent>
      <CardFooter>
        <form onSubmit={sendCommand} className="flex w-full gap-2">
          <Input
            placeholder="Type a command..."
            value={command}
            onChange={(e) => setCommand(e.target.value)}
            className="flex-1"
          />
          <Button type="submit">
            <Send className="h-4 w-4 mr-2" />
            Send
          </Button>
        </form>
      </CardFooter>
    </Card>
  )
}
