"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { useToast } from "@/hooks/use-toast"
import { RefreshCw, Download, CheckCircle, AlertCircle } from "lucide-react"

type UpdateStatus = {
  checking: boolean
  updating: boolean
  available: boolean
  error: string | null
  currentVersion: string
  latestVersion: string
  lastChecked: string | null
  lastUpdated: string | null
  progress: number
}

export function SystemUpdate() {
  const [status, setStatus] = useState<UpdateStatus>({
    checking: false,
    updating: false,
    available: false,
    error: null,
    currentVersion: "Onbekend",
    latestVersion: "Onbekend",
    lastChecked: null,
    lastUpdated: null,
    progress: 0,
  })
  const { toast } = useToast()

  // Haal de huidige update status op
  useEffect(() => {
    fetchUpdateStatus()
  }, [])

  const fetchUpdateStatus = async () => {
    try {
      const response = await fetch("/api/system/update/status")
      if (!response.ok) throw new Error("Kon update status niet ophalen")

      const data = await response.json()
      setStatus((prev) => ({
        ...prev,
        available: data.updateAvailable,
        currentVersion: data.currentVersion || "Onbekend",
        latestVersion: data.latestVersion || "Onbekend",
        lastChecked: data.lastChecked,
        lastUpdated: data.lastUpdated,
        error: null,
      }))
    } catch (error) {
      console.error("Error fetching update status:", error)
      setStatus((prev) => ({
        ...prev,
        error: "Kon update status niet ophalen",
      }))
    }
  }

  const checkForUpdates = async () => {
    setStatus((prev) => ({ ...prev, checking: true, error: null }))

    try {
      const response = await fetch("/api/system/update/check", {
        method: "POST",
      })

      if (!response.ok) throw new Error("Kon niet controleren op updates")

      const data = await response.json()
      setStatus((prev) => ({
        ...prev,
        checking: false,
        available: data.updateAvailable,
        currentVersion: data.currentVersion,
        latestVersion: data.latestVersion,
        lastChecked: new Date().toISOString(),
      }))

      toast({
        title: data.updateAvailable ? "Update beschikbaar!" : "Geen updates beschikbaar",
        description: data.updateAvailable
          ? `Versie ${data.latestVersion} is beschikbaar voor installatie`
          : "Je systeem is up-to-date",
      })
    } catch (error) {
      console.error("Error checking for updates:", error)
      setStatus((prev) => ({
        ...prev,
        checking: false,
        error: "Kon niet controleren op updates",
      }))

      toast({
        title: "Fout bij controleren op updates",
        description: "Er is een fout opgetreden bij het controleren op updates",
        variant: "destructive",
      })
    }
  }

  const installUpdate = async () => {
    setStatus((prev) => ({ ...prev, updating: true, progress: 0, error: null }))

    try {
      // Start de update
      const response = await fetch("/api/system/update/install", {
        method: "POST",
      })

      if (!response.ok) throw new Error("Kon update niet starten")

      const data = await response.json()
      const updateId = data.updateId

      // Poll voor update voortgang
      const progressInterval = setInterval(async () => {
        try {
          const progressResponse = await fetch(`/api/system/update/progress?id=${updateId}`)
          const progressData = await progressResponse.json()

          setStatus((prev) => ({
            ...prev,
            progress: progressData.progress,
          }))

          if (progressData.status === "completed") {
            clearInterval(progressInterval)
            setStatus((prev) => ({
              ...prev,
              updating: false,
              available: false,
              currentVersion: progressData.version,
              latestVersion: progressData.version,
              lastUpdated: new Date().toISOString(),
              progress: 100,
            }))

            toast({
              title: "Update voltooid",
              description: `MinecraftOS is bijgewerkt naar versie ${progressData.version}`,
            })

            // Herlaad de pagina na 3 seconden om de nieuwe versie te laden
            setTimeout(() => {
              window.location.reload()
            }, 3000)
          } else if (progressData.status === "failed") {
            clearInterval(progressInterval)
            setStatus((prev) => ({
              ...prev,
              updating: false,
              error: progressData.error || "Update mislukt",
              progress: 0,
            }))

            toast({
              title: "Update mislukt",
              description: progressData.error || "Er is een fout opgetreden tijdens de update",
              variant: "destructive",
            })
          }
        } catch (error) {
          console.error("Error checking update progress:", error)
        }
      }, 2000)
    } catch (error) {
      console.error("Error installing update:", error)
      setStatus((prev) => ({
        ...prev,
        updating: false,
        error: "Kon update niet installeren",
        progress: 0,
      }))

      toast({
        title: "Update mislukt",
        description: "Er is een fout opgetreden bij het starten van de update",
        variant: "destructive",
      })
    }
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader>
        <CardTitle>Systeem Updates</CardTitle>
        <CardDescription>Beheer MinecraftOS software updates</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <div className="text-xs text-slate-400">Huidige versie</div>
            <div className="font-medium">{status.currentVersion}</div>
          </div>

          <div className="space-y-1">
            <div className="text-xs text-slate-400">Laatste versie</div>
            <div className="font-medium">{status.latestVersion}</div>
          </div>

          <div className="space-y-1">
            <div className="text-xs text-slate-400">Laatst gecontroleerd</div>
            <div className="font-medium">
              {status.lastChecked ? new Date(status.lastChecked).toLocaleString() : "Nooit"}
            </div>
          </div>

          <div className="space-y-1">
            <div className="text-xs text-slate-400">Laatst bijgewerkt</div>
            <div className="font-medium">
              {status.lastUpdated ? new Date(status.lastUpdated).toLocaleString() : "Nooit"}
            </div>
          </div>
        </div>

        {status.error && (
          <div className="bg-red-900/20 border border-red-900/50 text-red-400 p-3 rounded-md flex items-center">
            <AlertCircle className="h-4 w-4 mr-2" />
            <span>{status.error}</span>
          </div>
        )}

        {status.available && !status.updating && (
          <div className="bg-emerald-900/20 border border-emerald-900/50 text-emerald-400 p-3 rounded-md flex items-center">
            <CheckCircle className="h-4 w-4 mr-2" />
            <span>Update beschikbaar! Versie {status.latestVersion} kan worden geïnstalleerd.</span>
          </div>
        )}

        {status.updating && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Bijwerken naar versie {status.latestVersion}...</span>
              <span>{status.progress}%</span>
            </div>
            <Progress value={status.progress} className="h-2" />
            <p className="text-xs text-slate-400 mt-2">
              {status.progress < 20 && "Voorbereiden van update..."}
              {status.progress >= 20 && status.progress < 40 && "Downloaden van nieuwe versie..."}
              {status.progress >= 40 && status.progress < 60 && "Installeren van update..."}
              {status.progress >= 60 && status.progress < 80 && "Bijwerken van bestanden..."}
              {status.progress >= 80 && "Afronden van update..."}
            </p>
          </div>
        )}
      </CardContent>
      <CardFooter className="flex justify-between">
        <Button variant="outline" onClick={checkForUpdates} disabled={status.checking || status.updating}>
          <RefreshCw className={`h-4 w-4 mr-2 ${status.checking ? "animate-spin" : ""}`} />
          {status.checking ? "Controleren..." : "Controleer op updates"}
        </Button>

        {status.available && (
          <Button onClick={installUpdate} disabled={status.updating}>
            <Download className="h-4 w-4 mr-2" />
            {status.updating ? "Bijwerken..." : "Installeer update"}
          </Button>
        )}
      </CardFooter>
    </Card>
  )
}
