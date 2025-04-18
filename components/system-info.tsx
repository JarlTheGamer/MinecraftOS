"use client"

import { useState, useEffect } from "react"

export function SystemInfo() {
  const [systemInfo, setSystemInfo] = useState({
    cpu: 0,
    memory: {
      used: 0,
      total: 0,
    },
    disk: {
      used: 0,
      total: 0,
    },
    status: "loading",
  })

  // Fetch real system info from the API
  useEffect(() => {
    const fetchSystemInfo = async () => {
      try {
        const response = await fetch("/api/system/status")

        if (!response.ok) {
          throw new Error("Failed to fetch system info")
        }

        const data = await response.json()

        setSystemInfo({
          cpu: data.resources.cpu,
          memory: data.resources.memory,
          disk: data.resources.disk,
          status: "online",
        })
      } catch (error) {
        console.error("Error fetching system info:", error)
        setSystemInfo((prev) => ({ ...prev, status: "error" }))
      }
    }

    fetchSystemInfo()

    // Update system info every 10 seconds
    const interval = setInterval(fetchSystemInfo, 10000)
    return () => clearInterval(interval)
  }, [])

  return (
    <div className="bg-slate-800 rounded-md p-3 text-sm">
      <div className="flex items-center justify-between mb-2">
        <span className="text-slate-400">System Status</span>
        <span className="flex items-center">
          {systemInfo.status === "loading" ? (
            <>
              <span className="h-2 w-2 rounded-full bg-yellow-400 mr-1"></span>
              <span className="text-yellow-400">Loading</span>
            </>
          ) : systemInfo.status === "error" ? (
            <>
              <span className="h-2 w-2 rounded-full bg-red-400 mr-1"></span>
              <span className="text-red-400">Error</span>
            </>
          ) : (
            <>
              <span className="h-2 w-2 rounded-full bg-green-400 mr-1"></span>
              <span className="text-green-400">Online</span>
            </>
          )}
        </span>
      </div>
      <div className="space-y-1 text-xs text-slate-400">
        <div className="flex justify-between">
          <span>CPU</span>
          <span>{systemInfo.cpu}%</span>
        </div>
        <div className="flex justify-between">
          <span>RAM</span>
          <span>
            {systemInfo.memory.used}GB / {systemInfo.memory.total}GB
          </span>
        </div>
        <div className="flex justify-between">
          <span>Disk</span>
          <span>
            {systemInfo.disk.used}GB / {systemInfo.disk.total}GB
          </span>
        </div>
      </div>
    </div>
  )
}
