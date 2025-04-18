"use client"

import { useState, useEffect } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ServerDashboard } from "@/components/server-dashboard"

type Server = {
  id: string
  name: string
  type: string
  version: string
  status: "online" | "offline" | "starting" | "stopping"
  port: string
  players: {
    online: number
    max: number
  }
  memory: {
    used: number
    allocated: number
  }
  uptime: string
}

export function ServerList() {
  const [servers, setServers] = useState<Server[]>([])
  const [selectedServer, setSelectedServer] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // In a real implementation, this would fetch servers from the API
    const fetchServers = async () => {
      try {
        // Simulate API call
        const response = await fetch("/api/servers")
        const data = await response.json()
        setServers(data.servers || [])
      } catch (error) {
        console.error("Error fetching servers:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchServers()
  }, [])

  const handleServerClick = (serverId: string) => {
    setSelectedServer(serverId === selectedServer ? null : serverId)
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
      </div>
    )
  }

  if (servers.length === 0) {
    return (
      <Card className="bg-slate-900 border-slate-800">
        <CardContent className="flex flex-col items-center justify-center h-64 p-6">
          <h3 className="text-xl font-medium mb-2">No servers found</h3>
          <p className="text-slate-400 text-center mb-4">You don't have any Minecraft servers set up yet.</p>
          <Button>Create Your First Server</Button>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-4">
      {servers.map((server) => (
        <div key={server.id}>
          <Card
            className={`bg-slate-900 border-slate-800 hover:border-slate-700 transition-colors cursor-pointer ${
              selectedServer === server.id ? "border-emerald-500" : ""
            }`}
            onClick={() => handleServerClick(server.id)}
          >
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={`w-3 h-3 rounded-full ${
                      server.status === "online"
                        ? "bg-green-500"
                        : server.status === "starting" || server.status === "stopping"
                          ? "bg-yellow-500"
                          : "bg-red-500"
                    }`}
                  ></div>
                  <h3 className="font-medium">{server.name}</h3>
                  <Badge variant="outline" className="capitalize">
                    {server.type}
                  </Badge>
                  <Badge variant="secondary">{server.version}</Badge>
                </div>

                <div className="flex items-center gap-6">
                  <div className="flex flex-col items-end">
                    <div className="text-xs text-slate-400">Players</div>
                    <div className="text-sm">
                      {server.players.online}/{server.players.max}
                    </div>
                  </div>

                  <div className="flex flex-col items-end">
                    <div className="text-xs text-slate-400">Memory</div>
                    <div className="text-sm">
                      {server.memory.used}/{server.memory.allocated} MB
                    </div>
                  </div>

                  <div className="flex flex-col items-end">
                    <div className="text-xs text-slate-400">Uptime</div>
                    <div className="text-sm">{server.uptime}</div>
                  </div>

                  <Button variant="ghost" size="sm" className="ml-2">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <polyline points="6 9 12 15 18 9"></polyline>
                    </svg>
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>

          {selectedServer === server.id && <ServerDashboard server={server} />}
        </div>
      ))}
    </div>
  )
}
