"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { useToast } from "@/hooks/use-toast"
import QRCode from "qrcode"

export function RemoteAccessSetup() {
  const [enabled, setEnabled] = useState(true)
  const [accessPin, setAccessPin] = useState("")
  const [qrCodeUrl, setQrCodeUrl] = useState("")
  const [isGenerating, setIsGenerating] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [port, setPort] = useState("8192")
  const { toast } = useToast()

  // Load current settings
  useEffect(() => {
    const loadSettings = async () => {
      try {
        const response = await fetch("/api/remote-access")
        if (response.ok) {
          const data = await response.json()
          setEnabled(data.enabled)
          setAccessPin(data.pin)
          setPort(data.port.toString())

          if (data.enabled && data.pin) {
            generateQRCode(data.pin)
          }
        }
      } catch (error) {
        console.error("Error loading remote access settings:", error)
      } finally {
        setIsLoading(false)
      }
    }

    loadSettings()
  }, [])

  const generateNewPin = async () => {
    setIsGenerating(true)

    try {
      // Generate a new PIN on the server
      const response = await fetch("/api/remote-access/generate-pin", {
        method: "POST",
      })

      if (!response.ok) {
        throw new Error("Failed to generate PIN")
      }

      const data = await response.json()
      setAccessPin(data.pin)

      // Generate QR code
      generateQRCode(data.pin)

      toast({
        title: "New PIN generated",
        description: "Your remote access PIN has been updated.",
      })
    } catch (error) {
      console.error("Error generating PIN:", error)
      toast({
        title: "Failed to generate PIN",
        description: "An error occurred while generating a new PIN.",
        variant: "destructive",
      })
    } finally {
      setIsGenerating(false)
    }
  }

  const generateQRCode = async (pin: string) => {
    try {
      // Get server IP or hostname
      const ipResponse = await fetch("/api/system/network")
      const ipData = await ipResponse.json()

      // Create connection string
      const connectionString = JSON.stringify({
        server: ipData.ipAddress || window.location.hostname,
        port: Number.parseInt(port),
        pin: pin,
        name: ipData.hostname || "Minecraft Server",
      })

      // Generate QR code
      const qrDataUrl = await QRCode.toDataURL(connectionString, {
        errorCorrectionLevel: "M",
        margin: 1,
        width: 200,
        color: {
          dark: "#000000",
          light: "#ffffff",
        },
      })

      setQrCodeUrl(qrDataUrl)
    } catch (error) {
      console.error("Error generating QR code:", error)
    }
  }

  const saveSettings = async () => {
    try {
      const response = await fetch("/api/remote-access", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          enabled,
          pin: accessPin,
          port: Number.parseInt(port),
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to save settings")
      }

      if (enabled && accessPin) {
        generateQRCode(accessPin)
      }

      toast({
        title: "Settings saved",
        description: "Remote access settings have been updated.",
      })
    } catch (error) {
      console.error("Error saving settings:", error)
      toast({
        title: "Failed to save settings",
        description: "An error occurred while saving remote access settings.",
        variant: "destructive",
      })
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-2 gap-6">
      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle>Remote Access</CardTitle>
          <CardDescription>Configure remote access to your server manager</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <Label htmlFor="remote-access">Enable Remote Access</Label>
            <Switch id="remote-access" checked={enabled} onCheckedChange={setEnabled} />
          </div>

          {enabled && (
            <>
              <div className="space-y-2">
                <Label>Access PIN</Label>
                <div className="flex gap-2">
                  <div className="flex justify-between gap-2 flex-1">
                    {accessPin ? (
                      accessPin.split("").map((digit, index) => (
                        <div
                          key={index}
                          className="w-10 h-12 bg-slate-800 rounded-md flex items-center justify-center text-xl font-bold"
                        >
                          {digit}
                        </div>
                      ))
                    ) : (
                      <div className="text-slate-500">No PIN generated</div>
                    )}
                  </div>
                  <Button variant="outline" onClick={generateNewPin} disabled={isGenerating}>
                    {isGenerating ? "Generating..." : "Generate New PIN"}
                  </Button>
                </div>
                <p className="text-xs text-slate-400">This PIN will be required when connecting from remote devices</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="port">Remote Access Port</Label>
                <Input
                  id="port"
                  value={port}
                  onChange={(e) => setPort(e.target.value)}
                  className="bg-slate-800 border-slate-700"
                />
                <p className="text-xs text-slate-400">Make sure this port is open in your firewall</p>
              </div>
            </>
          )}
        </CardContent>
        <CardFooter>
          <Button onClick={saveSettings}>Save Settings</Button>
        </CardFooter>
      </Card>

      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle>QR Code Access</CardTitle>
          <CardDescription>Scan this code with the mobile app</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center">
          {enabled ? (
            <>
              {qrCodeUrl ? (
                <div className="w-48 h-48 bg-white p-2 rounded-md mb-4">
                  <img
                    src={qrCodeUrl || "/placeholder.svg"}
                    alt="QR Code for remote access"
                    className="w-full h-full"
                  />
                </div>
              ) : (
                <div className="w-48 h-48 bg-slate-800 rounded-md mb-4 flex items-center justify-center">
                  <p className="text-slate-500 text-center">Generate a PIN first</p>
                </div>
              )}

              <div className="text-center">
                <p className="text-sm mb-2">Access your server from anywhere</p>
                <p className="text-xs text-slate-400">Download our mobile app and scan this QR code to connect</p>
              </div>
            </>
          ) : (
            <div className="text-center py-12">
              <p className="text-slate-400">Remote access is disabled</p>
              <p className="text-xs text-slate-500 mt-2">Enable remote access to generate a QR code</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
