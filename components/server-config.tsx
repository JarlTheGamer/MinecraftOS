"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useToast } from "@/hooks/use-toast"

export function ServerConfig() {
  const { toast } = useToast()
  const [saving, setSaving] = useState(false)

  // In a real implementation, these would be loaded from the server
  const [config, setConfig] = useState({
    serverName: "My Minecraft Server",
    serverPort: "25565",
    maxPlayers: "20",
    gameMode: "survival",
    difficulty: "normal",
    allowNether: true,
    enableCommandBlock: false,
    pvp: true,
    spawnProtection: "16",
    viewDistance: "10",
    motd: "Welcome to My Minecraft Server!",
    whitelistEnabled: false,
    onlineMode: true,
  })

  const handleChange = (key: string, value: string | boolean) => {
    setConfig((prev) => ({ ...prev, [key]: value }))
  }

  const saveConfig = async () => {
    setSaving(true)

    // In a real implementation, this would save the config to the server
    try {
      // Simulate saving
      await new Promise((resolve) => setTimeout(resolve, 1500))
      toast({
        title: "Configuration saved",
        description: "Server configuration has been updated successfully.",
      })
    } catch (error) {
      toast({
        title: "Failed to save configuration",
        description: "An error occurred while saving the configuration.",
        variant: "destructive",
      })
    } finally {
      setSaving(false)
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Server Configuration</CardTitle>
        <CardDescription>Manage server settings</CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="general">
          <TabsList className="grid grid-cols-3 w-full max-w-md mb-4">
            <TabsTrigger value="general">General</TabsTrigger>
            <TabsTrigger value="gameplay">Gameplay</TabsTrigger>
            <TabsTrigger value="advanced">Advanced</TabsTrigger>
          </TabsList>

          <TabsContent value="general" className="space-y-4">
            <div className="grid gap-4">
              <div className="grid gap-2">
                <Label htmlFor="serverName">Server Name</Label>
                <Input
                  id="serverName"
                  value={config.serverName}
                  onChange={(e) => handleChange("serverName", e.target.value)}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="serverPort">Server Port</Label>
                <Input
                  id="serverPort"
                  value={config.serverPort}
                  onChange={(e) => handleChange("serverPort", e.target.value)}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="maxPlayers">Max Players</Label>
                <Input
                  id="maxPlayers"
                  value={config.maxPlayers}
                  onChange={(e) => handleChange("maxPlayers", e.target.value)}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="motd">Message of the Day</Label>
                <Input id="motd" value={config.motd} onChange={(e) => handleChange("motd", e.target.value)} />
              </div>
            </div>
          </TabsContent>

          <TabsContent value="gameplay" className="space-y-4">
            <div className="grid gap-4">
              <div className="grid gap-2">
                <Label htmlFor="gameMode">Game Mode</Label>
                <Select value={config.gameMode} onValueChange={(value) => handleChange("gameMode", value)}>
                  <SelectTrigger id="gameMode">
                    <SelectValue placeholder="Select game mode" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="survival">Survival</SelectItem>
                    <SelectItem value="creative">Creative</SelectItem>
                    <SelectItem value="adventure">Adventure</SelectItem>
                    <SelectItem value="spectator">Spectator</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="difficulty">Difficulty</Label>
                <Select value={config.difficulty} onValueChange={(value) => handleChange("difficulty", value)}>
                  <SelectTrigger id="difficulty">
                    <SelectValue placeholder="Select difficulty" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="peaceful">Peaceful</SelectItem>
                    <SelectItem value="easy">Easy</SelectItem>
                    <SelectItem value="normal">Normal</SelectItem>
                    <SelectItem value="hard">Hard</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="pvp">PvP Enabled</Label>
                <Switch id="pvp" checked={config.pvp} onCheckedChange={(checked) => handleChange("pvp", checked)} />
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="allowNether">Allow Nether</Label>
                <Switch
                  id="allowNether"
                  checked={config.allowNether}
                  onCheckedChange={(checked) => handleChange("allowNether", checked)}
                />
              </div>
            </div>
          </TabsContent>

          <TabsContent value="advanced" className="space-y-4">
            <div className="grid gap-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="onlineMode">Online Mode (Verify Players)</Label>
                <Switch
                  id="onlineMode"
                  checked={config.onlineMode}
                  onCheckedChange={(checked) => handleChange("onlineMode", checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="whitelistEnabled">Enable Whitelist</Label>
                <Switch
                  id="whitelistEnabled"
                  checked={config.whitelistEnabled}
                  onCheckedChange={(checked) => handleChange("whitelistEnabled", checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="enableCommandBlock">Enable Command Blocks</Label>
                <Switch
                  id="enableCommandBlock"
                  checked={config.enableCommandBlock}
                  onCheckedChange={(checked) => handleChange("enableCommandBlock", checked)}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="spawnProtection">Spawn Protection Radius</Label>
                <Input
                  id="spawnProtection"
                  value={config.spawnProtection}
                  onChange={(e) => handleChange("spawnProtection", e.target.value)}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="viewDistance">View Distance</Label>
                <Input
                  id="viewDistance"
                  value={config.viewDistance}
                  onChange={(e) => handleChange("viewDistance", e.target.value)}
                />
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
      <CardFooter>
        <Button onClick={saveConfig} disabled={saving}>
          {saving ? "Saving..." : "Save Configuration"}
        </Button>
      </CardFooter>
    </Card>
  )
}
