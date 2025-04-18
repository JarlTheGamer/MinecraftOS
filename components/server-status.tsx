"use client"

import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Activity, Users } from "lucide-react"

export function ServerStatus() {
  const [status, setStatus] = useState<"online" | "offline" | "starting" | "stopping">("offline")
  const [uptime, setUptime] = useState("0h 0m")
  const [playerCount, setPlayerCount] = useState(0)

  // In a real implementation, this would fetch data from the server
  useEffect(() => {
    // Simulate server status for demo
    const timer = setTimeout(() => {
      setStatus("online")
      setUptime("2h 45m")
      setPlayerCount(3)
    }, 2000)

    return () => clearTimeout(timer)
  }, [])

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle>Server Status</CardTitle>
        <CardDescription>Current server information</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Status</span>
            <Badge
              variant={
                status === "online"
                  ? "default"
                  : status === "starting" || status === "stopping"
                    ? "outline"
                    : "destructive"
              }
              className="capitalize"
            >
              {status}
            </Badge>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm font-medium flex items-center">
              <Activity className="h-4 w-4 mr-2" />
              Uptime
            </span>
            <span className="text-sm">{uptime}</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm font-medium flex items-center">
              <Users className="h-4 w-4 mr-2" />
              Players
            </span>
            <span className="text-sm">{playerCount} / 20</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Version</span>
            <span className="text-sm">1.19.2 (Paper)</span>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
