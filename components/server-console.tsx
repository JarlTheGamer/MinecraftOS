"use client"

import type React from "react"

import { useEffect, useRef, useState } from "react"
import { Card, CardContent, CardFooter } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Download, Send } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

type ServerConsoleProps = {
  serverId: string
}

export function ServerConsole({ serverId }: ServerConsoleProps) {
  const [logs, setLogs] = useState<string[]>([])
  const [command, setCommand] = useState("")
  const [isLoading, setIsLoading] = useState(true)
  const logsEndRef = useRef<HTMLDivElement>(null)
  const { toast } = useToast()
  const logPollingRef = useRef<NodeJS.Timeout | null>(null)

  // Auto-scroll to bottom when logs update
  useEffect(() => {
    if (logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: "smooth" })
    }
  }, [logs])

  // Fetch logs on component mount
  useEffect(() => {
    const fetchLogs = async () => {
      try {
        const response = await fetch(`/api/servers/${serverId}/logs`)

        if (!response.ok) {
          throw new Error("Failed to fetch logs")
        }

        const data = await response.json()
        setLogs(data.logs || [])
      } catch (error) {
        console.error("Error fetching logs:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchLogs()

    // Set up polling for log updates
    logPollingRef.current = setInterval(fetchLogs, 3000)

    // Clean up on unmount
    return () => {
      if (logPollingRef.current) {
        clearInterval(logPollingRef.current)
      }
    }
  }, [serverId])

  const sendCommand = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!command.trim()) return

    try {
      // Add command to logs immediately for better UX
      setLogs((prev) => [...prev, `> ${command}`])

      // Send command to server
      const response = await fetch(`/api/servers/${serverId}/command`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ command }),
      })

      if (!response.ok) {
        throw new Error("Failed to send command")
      }

      setCommand("")
    } catch (error) {
      console.error("Error sending command:", error)
      toast({
        title: "Command failed",
        description: "Failed to send command to the server",
        variant: "destructive",
      })
    }
  }

  const downloadLogs = async () => {
    try {
      const response = await fetch(`/api/servers/${serverId}/logs/download`)

      if (!response.ok) {
        throw new Error("Failed to download logs")
      }

      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `minecraft-server-${serverId}.log`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    } catch (error) {
      console.error("Error downloading logs:", error)
      toast({
        title: "Download failed",
        description: "Failed to download server logs",
        variant: "destructive",
      })
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardContent className="p-0">
        <div className="flex justify-between items-center p-4 border-b border-slate-800">
          <h3 className="font-medium">Server Console</h3>
          <Button variant="outline" size="sm" onClick={downloadLogs}>
            <Download className="h-4 w-4 mr-2" />
            Download Logs
          </Button>
        </div>
        <div className="bg-black text-green-400 font-mono text-sm p-4 h-[400px] overflow-y-auto">
          {isLoading ? (
            <div className="flex justify-center items-center h-full">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-green-500"></div>
            </div>
          ) : logs.length > 0 ? (
            logs.map((log, index) => (
              <div key={index} className={log.startsWith(">") ? "text-white" : ""}>
                {log}
              </div>
            ))
          ) : (
            <div className="text-slate-500">No logs available</div>
          )}
          <div ref={logsEndRef} />
        </div>
      </CardContent>
      <CardFooter className="p-4 border-t border-slate-800">
        <form onSubmit={sendCommand} className="flex w-full gap-2">
          <Input
            placeholder="Type a command..."
            value={command}
            onChange={(e) => setCommand(e.target.value)}
            className="flex-1 bg-slate-800 border-slate-700"
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
