"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { useToast } from "@/hooks/use-toast"

export function NetworkSettings() {
  const [networkConfig, setNetworkConfig] = useState("dhcp")
  const [staticIp, setStaticIp] = useState("192.168.1.100")
  const [gateway, setGateway] = useState("192.168.1.1")
  const [dns, setDns] = useState("8.8.8.8")
  const [enableUpnp, setEnableUpnp] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const { toast } = useToast()

  const handleSave = async () => {
    setIsSaving(true)

    // In a real implementation, this would save the network settings
    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 2000))

      toast({
        title: "Network settings saved",
        description: "Your network settings have been updated successfully.",
      })
    } catch (error) {
      console.error("Error saving network settings:", error)
      toast({
        title: "Failed to save settings",
        description: "An error occurred while saving network settings.",
        variant: "destructive",
      })
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle>Network Configuration</CardTitle>
          <CardDescription>Configure your server's network settings</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>IP Configuration</Label>
            <Select value={networkConfig} onValueChange={setNetworkConfig}>
              <SelectTrigger className="bg-slate-800 border-slate-700">
                <SelectValue placeholder="Select IP configuration" />
              </SelectTrigger>
              <SelectContent className="bg-slate-800 border-slate-700">
                <SelectItem value="dhcp">DHCP (Automatic)</SelectItem>
                <SelectItem value="static">Static IP</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {networkConfig === "static" && (
            <>
              <div className="space-y-2">
                <Label htmlFor="staticIp">IP Address</Label>
                <Input
                  id="staticIp"
                  value={staticIp}
                  onChange={(e) => setStaticIp(e.target.value)}
                  className="bg-slate-800 border-slate-700"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="gateway">Gateway</Label>
                <Input
                  id="gateway"
                  value={gateway}
                  onChange={(e) => setGateway(e.target.value)}
                  className="bg-slate-800 border-slate-700"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="dns">DNS Server</Label>
                <Input
                  id="dns"
                  value={dns}
                  onChange={(e) => setDns(e.target.value)}
                  className="bg-slate-800 border-slate-700"
                />
              </div>
            </>
          )}

          <div className="flex items-center justify-between">
            <Label htmlFor="upnp">Enable UPnP</Label>
            <Switch id="upnp" checked={enableUpnp} onCheckedChange={setEnableUpnp} />
          </div>
        </CardContent>
        <CardFooter>
          <Button onClick={handleSave} disabled={isSaving}>
            {isSaving ? "Saving..." : "Save Settings"}
          </Button>
        </CardFooter>
      </Card>

      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle>Port Forwarding</CardTitle>
          <CardDescription>Configure port forwarding for your Minecraft servers</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <p className="text-sm text-slate-400">
              For players to connect from the internet, you need to forward these ports on your router:
            </p>

            <div className="bg-slate-800 p-4 rounded-md">
              <h3 className="text-sm font-medium mb-2">Active Ports</h3>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Minecraft (TCP)</span>
                  <span>25565</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Web Interface (TCP)</span>
                  <span>8080</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Remote Access (TCP)</span>
                  <span>8192</span>
                </div>
              </div>
            </div>

            <div className="bg-slate-800 p-4 rounded-md">
              <h3 className="text-sm font-medium mb-2">UPnP Status</h3>
              <div className="flex items-center">
                <div className="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
                <span className="text-sm">Active - Ports are automatically forwarded</span>
              </div>
            </div>

            <p className="text-xs text-slate-400">
              If UPnP is not available on your router, you'll need to manually forward these ports. Check your router's
              documentation for instructions.
            </p>
          </div>
        </CardContent>
        <CardFooter>
          <Button variant="outline">Test Connection</Button>
        </CardFooter>
      </Card>
    </div>
  )
}
