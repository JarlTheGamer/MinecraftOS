"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Progress } from "@/components/ui/progress"
import { useToast } from "@/hooks/use-toast"
import { Download, RefreshCw } from "lucide-react"

type ServerVersion = {
  id: string
  type: string
  version: string
  releaseDate: string
  downloadUrl: string
}

export function ServerDownloader() {
  const [serverType, setServerType] = useState("paper")
  const [mcVersion, setMcVersion] = useState("")
  const [buildVersion, setBuildVersion] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [isDownloading, setIsDownloading] = useState(false)
  const [downloadProgress, setDownloadProgress] = useState(0)
  const [availableVersions, setAvailableVersions] = useState<string[]>([])
  const [availableBuilds, setAvailableBuilds] = useState<string[]>([])
  const { toast } = useToast()

  // Fetch available Minecraft versions based on server type
  useEffect(() => {
    const fetchVersions = async () => {
      setIsLoading(true)
      try {
        let versions: string[] = []

        if (serverType === "paper") {
          // Fetch Paper versions from PaperMC API
          const response = await fetch("https://api.papermc.io/v2/projects/paper")
          const data = await response.json()
          versions = data.versions || []
          versions.reverse() // Most recent first
        } else if (serverType === "purpur") {
          // Fetch Purpur versions
          const response = await fetch("https://api.purpurmc.org/v2/purpur")
          const data = await response.json()
          versions = data.versions || []
          versions.reverse()
        } else if (serverType === "fabric") {
          // Fetch Fabric versions
          const response = await fetch("https://meta.fabricmc.net/v2/versions/game")
          const data = await response.json()
          versions = data.map((v: any) => v.version) || []
        } else if (serverType === "forge") {
          // Fetch Forge versions
          const response = await fetch("/api/server-versions/forge")
          const data = await response.json()
          versions = data.versions || []
        } else {
          // Vanilla versions from Mojang API
          const response = await fetch("https://launchermeta.mojang.com/mc/game/version_manifest.json")
          const data = await response.json()
          versions = data.versions.filter((v: any) => v.type === "release").map((v: any) => v.id) || []
        }

        setAvailableVersions(versions)
        setMcVersion(versions[0] || "")
      } catch (error) {
        console.error("Error fetching versions:", error)
        toast({
          title: "Error",
          description: "Failed to fetch available versions",
          variant: "destructive",
        })
      } finally {
        setIsLoading(false)
      }
    }

    fetchVersions()
  }, [serverType, toast])

  // Fetch available builds for selected version
  useEffect(() => {
    if (!mcVersion) return

    const fetchBuilds = async () => {
      setIsLoading(true)
      try {
        let builds: string[] = []

        if (serverType === "paper") {
          // Fetch Paper builds for selected version
          const response = await fetch(`https://api.papermc.io/v2/projects/paper/versions/${mcVersion}/builds`)
          const data = await response.json()
          builds = data.builds.map((b: any) => b.build.toString()) || []
          builds.reverse() // Most recent first
        } else if (serverType === "purpur") {
          // Fetch Purpur builds
          const response = await fetch(`https://api.purpurmc.org/v2/purpur/${mcVersion}`)
          const data = await response.json()
          builds = data.builds.all || []
          builds.reverse()
        } else if (serverType === "fabric") {
          // Fetch Fabric loader versions
          const response = await fetch("https://meta.fabricmc.net/v2/versions/loader")
          const data = await response.json()
          builds = data.map((l: any) => l.version) || []
        } else if (serverType === "forge") {
          // Fetch Forge builds for selected version
          const response = await fetch(`/api/server-versions/forge/${mcVersion}`)
          const data = await response.json()
          builds = data.builds || []
        } else {
          // Vanilla has no builds
          builds = ["release"]
        }

        setAvailableBuilds(builds)
        setBuildVersion(builds[0] || "")
      } catch (error) {
        console.error("Error fetching builds:", error)
        toast({
          title: "Error",
          description: "Failed to fetch available builds",
          variant: "destructive",
        })
      } finally {
        setIsLoading(false)
      }
    }

    fetchBuilds()
  }, [mcVersion, serverType, toast])

  const downloadServer = async () => {
    if (!mcVersion || !buildVersion) return

    setIsDownloading(true)
    setDownloadProgress(0)

    try {
      // Start the download on the server
      const response = await fetch("/api/server-download", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          serverType,
          mcVersion,
          buildVersion,
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to start download")
      }

      const data = await response.json()

      // Poll for download progress
      const progressInterval = setInterval(async () => {
        try {
          const progressResponse = await fetch(`/api/server-download/${data.downloadId}`)
          const progressData = await progressResponse.json()

          setDownloadProgress(progressData.progress)

          if (progressData.status === "completed") {
            clearInterval(progressInterval)
            setIsDownloading(false)
            toast({
              title: "Download complete",
              description: `${serverType} ${mcVersion} has been downloaded successfully.`,
            })
          } else if (progressData.status === "failed") {
            clearInterval(progressInterval)
            setIsDownloading(false)
            toast({
              title: "Download failed",
              description: progressData.error || "An error occurred during download",
              variant: "destructive",
            })
          }
        } catch (error) {
          console.error("Error checking download progress:", error)
        }
      }, 1000)

      // Clean up interval if component unmounts
      return () => clearInterval(progressInterval)
    } catch (error) {
      console.error("Error downloading server:", error)
      toast({
        title: "Download failed",
        description: "Failed to start server download",
        variant: "destructive",
      })
      setIsDownloading(false)
    }
  }

  const getDownloadUrl = () => {
    if (!mcVersion || !buildVersion) return ""

    if (serverType === "paper") {
      return `https://api.papermc.io/v2/projects/paper/versions/${mcVersion}/builds/${buildVersion}/downloads/paper-${mcVersion}-${buildVersion}.jar`
    } else if (serverType === "purpur") {
      return `https://api.purpurmc.org/v2/purpur/${mcVersion}/${buildVersion}/download`
    } else if (serverType === "fabric") {
      return `https://meta.fabricmc.net/v2/versions/loader/${mcVersion}/${buildVersion}/server/jar`
    } else if (serverType === "forge") {
      return `/api/server-versions/forge/${mcVersion}/${buildVersion}/download`
    } else {
      // Vanilla
      return `https://piston-data.mojang.com/v1/objects/${buildVersion}/server.jar`
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader>
        <CardTitle>Download Server Software</CardTitle>
        <CardDescription>Download the latest Minecraft server software</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="serverType">Server Type</Label>
          <Select value={serverType} onValueChange={setServerType}>
            <SelectTrigger id="serverType" className="bg-slate-800 border-slate-700">
              <SelectValue placeholder="Select server type" />
            </SelectTrigger>
            <SelectContent className="bg-slate-800 border-slate-700">
              <SelectItem value="vanilla">Vanilla</SelectItem>
              <SelectItem value="paper">Paper</SelectItem>
              <SelectItem value="purpur">Purpur</SelectItem>
              <SelectItem value="fabric">Fabric</SelectItem>
              <SelectItem value="forge">Forge</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <div className="flex justify-between items-center">
            <Label htmlFor="mcVersion">Minecraft Version</Label>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setMcVersion("")
                setServerType(serverType) // Trigger re-fetch
              }}
              disabled={isLoading}
            >
              <RefreshCw className={`h-4 w-4 ${isLoading ? "animate-spin" : ""}`} />
            </Button>
          </div>
          <Select value={mcVersion} onValueChange={setMcVersion} disabled={isLoading || availableVersions.length === 0}>
            <SelectTrigger id="mcVersion" className="bg-slate-800 border-slate-700">
              <SelectValue placeholder={isLoading ? "Loading versions..." : "Select version"} />
            </SelectTrigger>
            <SelectContent className="bg-slate-800 border-slate-700 max-h-[300px]">
              {availableVersions.map((version) => (
                <SelectItem key={version} value={version}>
                  {version}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {serverType !== "vanilla" && (
          <div className="space-y-2">
            <Label htmlFor="buildVersion">Build Version</Label>
            <Select
              value={buildVersion}
              onValueChange={setBuildVersion}
              disabled={isLoading || !mcVersion || availableBuilds.length === 0}
            >
              <SelectTrigger id="buildVersion" className="bg-slate-800 border-slate-700">
                <SelectValue placeholder={isLoading ? "Loading builds..." : "Select build"} />
              </SelectTrigger>
              <SelectContent className="bg-slate-800 border-slate-700 max-h-[300px]">
                {availableBuilds.map((build) => (
                  <SelectItem key={build} value={build}>
                    {build}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        )}

        <div className="space-y-2">
          <Label htmlFor="installPath">Install Path</Label>
          <Input
            id="installPath"
            value="/opt/minecraft/servers/new-server"
            className="bg-slate-800 border-slate-700"
            readOnly
          />
        </div>

        {isDownloading && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Downloading...</span>
              <span>{downloadProgress}%</span>
            </div>
            <Progress value={downloadProgress} className="h-2" />
          </div>
        )}
      </CardContent>
      <CardFooter>
        <Button
          onClick={downloadServer}
          disabled={isDownloading || isLoading || !mcVersion || !buildVersion}
          className="w-full"
        >
          <Download className="h-4 w-4 mr-2" />
          {isDownloading ? "Downloading..." : "Download Server"}
        </Button>
      </CardFooter>
    </Card>
  )
}
