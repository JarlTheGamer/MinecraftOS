"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Play, Square, RefreshCw } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

export function ServerControls() {
  const [isStarting, setIsStarting] = useState(false)
  const [isStopping, setIsStopping] = useState(false)
  const [isRestarting, setIsRestarting] = useState(false)
  const [serverRunning, setServerRunning] = useState(false)
  const { toast } = useToast()

  const startServer = async () => {
    setIsStarting(true)

    // In a real implementation, this would call a server action to start the Minecraft server
    try {
      // Simulate server starting
      await new Promise((resolve) => setTimeout(resolve, 2000))
      setServerRunning(true)
      toast({
        title: "Server started",
        description: "Minecraft server has been started successfully.",
      })
    } catch (error) {
      toast({
        title: "Failed to start server",
        description: "An error occurred while starting the server.",
        variant: "destructive",
      })
    } finally {
      setIsStarting(false)
    }
  }

  const stopServer = async () => {
    setIsStopping(true)

    // In a real implementation, this would call a server action to stop the Minecraft server
    try {
      // Simulate server stopping
      await new Promise((resolve) => setTimeout(resolve, 2000))
      setServerRunning(false)
      toast({
        title: "Server stopped",
        description: "Minecraft server has been stopped successfully.",
      })
    } catch (error) {
      toast({
        title: "Failed to stop server",
        description: "An error occurred while stopping the server.",
        variant: "destructive",
      })
    } finally {
      setIsStopping(false)
    }
  }

  const restartServer = async () => {
    setIsRestarting(true)

    // In a real implementation, this would call a server action to restart the Minecraft server
    try {
      // Simulate server restarting
      await new Promise((resolve) => setTimeout(resolve, 3000))
      setServerRunning(true)
      toast({
        title: "Server restarted",
        description: "Minecraft server has been restarted successfully.",
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
    <Card>
      <CardHeader className="pb-2">
        <CardTitle>Server Controls</CardTitle>
        <CardDescription>Manage server state</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col space-y-2">
          <Button
            onClick={startServer}
            disabled={isStarting || serverRunning || isStopping || isRestarting}
            className="w-full"
          >
            <Play className="h-4 w-4 mr-2" />
            {isStarting ? "Starting..." : "Start Server"}
          </Button>

          <Button
            onClick={stopServer}
            disabled={isStopping || !serverRunning || isStarting || isRestarting}
            variant="outline"
            className="w-full"
          >
            <Square className="h-4 w-4 mr-2" />
            {isStopping ? "Stopping..." : "Stop Server"}
          </Button>

          <Button
            onClick={restartServer}
            disabled={isRestarting || !serverRunning || isStarting || isStopping}
            variant="outline"
            className="w-full"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            {isRestarting ? "Restarting..." : "Restart Server"}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
