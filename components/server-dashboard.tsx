"use client"

import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ServerConsole } from "@/components/server-console"
import { ServerConfig } from "@/components/server-config"
import { ServerPlayers } from "@/components/server-players"
import { ServerMods } from "@/components/server-mods"
import { ServerBackups } from "@/components/server-backups"
import { useToast } from "@/hooks/use-toast"
import { Play, Square, RefreshCw } from "lucide-react"

type ServerDashboardProps = {
  server: {
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
}

export function ServerDashboard({ server }: ServerDashboardProps) {
  const [serverStatus, setServerStatus] = useState(server.status)
  const [isStarting, setIsStarting] = useState(false)
  const [isStopping, setIsStopping] = useState(false)
  const [isRestarting, setIsRestarting] = useState(false)
  const { toast } = useToast()

  const startServer = async () => {
    setIsStarting(true)
    setServerStatus("starting")

    // In a real implementation, this would call a server action to start the Minecraft server
    try {
      // Make API call to start the server
      const response = await fetch(`/api/servers/${server.id}/start`, {
        method: "POST",
      })

      if (!response.ok) throw new Error("Failed to start server")

      // Simulate server starting time
      await new Promise((resolve) => setTimeout(resolve, 3000))
      setServerStatus("online")
      toast({
        title: "Server started",
        description: `${server.name} has been started successfully.`,
      })
    } catch (error) {
      toast({
        title: "Failed to start server",
        description: "An error occurred while starting the server.",
        variant: "destructive",
      })
      setServerStatus("offline")
    } finally {
      setIsStarting(false)
    }
  }

  const stopServer = async () => {
    setIsStopping(true)
    setServerStatus("stopping")

    // In a real implementation, this would call a server action to stop the Minecraft server
    try {
      // Make API call to stop the server
      const response = await fetch(`/api/servers/${server.id}/stop`, {
        method: "POST",
      })

      if (!response.ok) throw new Error("Failed to stop server")

      // Simulate server stopping time
      await new Promise((resolve) => setTimeout(resolve, 2000))
      setServerStatus("offline")
      toast({
        title: "Server stopped",
        description: `${server.name} has been stopped successfully.`,
      })
    } catch (error) {
      toast({
        title: "Failed to stop server",
        description: "An error occurred while stopping the server.",
        variant: "destructive",
      })
      setServerStatus("online")
    } finally {
      setIsStopping(false)
    }
  }

  const restartServer = async () => {
    setIsRestarting(true)
    setServerStatus("stopping")

    // In a real implementation, this would call a server action to restart the Minecraft server
    try {
      // Make API call to restart the server
      const response = await fetch(`/api/servers/${server.id}/restart`, {
        method: "POST",
      })

      if (!response.ok) throw new Error("Failed to restart server")

      // Simulate server restarting time
      await new Promise((resolve) => setTimeout(resolve, 1000))
      setServerStatus("starting")
      await new Promise((resolve) => setTimeout(resolve, 3000))
      setServerStatus("online")
      toast({
        title: "Server restarted",
        description: `${server.name} has been restarted successfully.`,
      })
    } catch (error) {
      toast({
        title: "Failed to restart server",
        description: "An error occurred while restarting the server.",
        variant: "destructive",
      })
    } finally {
      setIsRestarting(false)
    }
  }

  return (
    <div className="mt-2 mb-6 space-y-4">
      <div className="grid grid-cols-4 gap-4">
        <Card className="bg-slate-900 border-slate-800">
          <CardContent className="p-4">
            <div className="flex flex-col space-y-4">
              <Button
                onClick={startServer}
                disabled={
                  isStarting || serverStatus === "online" || isStopping || isRestarting || serverStatus === "starting"
                }
                className="w-full"
              >
                <Play className="h-4 w-4 mr-2" />
                {isStarting ? "Starting..." : "Start Server"}
              </Button>

              <Button
                onClick={stopServer}
                disabled={
                  isStopping || serverStatus === "offline" || isStarting || isRestarting || serverStatus === "stopping"
                }
                variant="outline"
                className="w-full"
              >
                <Square className="h-4 w-4 mr-2" />
                {isStopping ? "Stopping..." : "Stop Server"}
              </Button>

              <Button
                onClick={restartServer}
                disabled={isRestarting || serverStatus === "offline" || isStarting || isStopping}
                variant="outline"
                className="w-full"
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                {isRestarting ? "Restarting..." : "Restart Server"}
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-900 border-slate-800 col-span-3">
          <CardContent className="p-4">
            <div className="grid grid-cols-3 gap-6">
              <div>
                <div className="text-xs text-slate-400 mb-1">CPU Usage</div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm font-medium">24%</span>
                </div>
                <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
                  <div className="bg-emerald-500 h-full rounded-full" style={{ width: "24%" }}></div>
                </div>
              </div>

              <div>
                <div className="text-xs text-slate-400 mb-1">Memory Usage</div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm font-medium">
                    {server.memory.used} MB / {server.memory.allocated} MB
                  </span>
                </div>
                <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
                  <div
                    className="bg-emerald-500 h-full rounded-full"
                    style={{ width: `${(server.memory.used / server.memory.allocated) * 100}%` }}
                  ></div>
                </div>
              </div>

              <div>
                <div className="text-xs text-slate-400 mb-1">Players</div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm font-medium">
                    {server.players.online} / {server.players.max}
                  </span>
                </div>
                <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
                  <div
                    className="bg-emerald-500 h-full rounded-full"
                    style={{ width: `${(server.players.online / server.players.max) * 100}%` }}
                  ></div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="console" className="w-full">
        <TabsList className="bg-slate-800 border-slate-700">
          <TabsTrigger value="console">Console</TabsTrigger>
          <TabsTrigger value="players">Players</TabsTrigger>
          <TabsTrigger value="config">Configuration</TabsTrigger>
          <TabsTrigger value="mods">Mods</TabsTrigger>
          <TabsTrigger value="backups">Backups</TabsTrigger>
          <TabsTrigger value="files">Files</TabsTrigger>
        </TabsList>
        <TabsContent value="console" className="mt-4">
          <ServerConsole serverId={server.id} />
        </TabsContent>
        <TabsContent value="players" className="mt-4">
          <ServerPlayers serverId={server.id} />
        </TabsContent>
        <TabsContent value="config" className="mt-4">
          <ServerConfig serverId={server.id} serverType={server.type} />
        </TabsContent>
        <TabsContent value="mods" className="mt-4">
          <ServerMods serverId={server.id} serverType={server.type} />
        </TabsContent>
        <TabsContent value="backups" className="mt-4">
          <ServerBackups serverId={server.id} />
        </TabsContent>
        <TabsContent value="files" className="mt-4">
          <Card className="bg-slate-900 border-slate-800">
            <CardContent className="p-4">
              <div className="h-[400px] flex items-center justify-center">
                <p className="text-slate-400">File manager coming soon</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
