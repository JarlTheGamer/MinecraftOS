"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { Progress } from "@/components/ui/progress"
import { useToast } from "@/hooks/use-toast"

type SetupWizardProps = {
  onComplete: () => void
  isNewServer?: boolean
}

export function SetupWizard({ onComplete, isNewServer = false }: SetupWizardProps) {
  const [step, setStep] = useState(1)
  const [isLoading, setIsLoading] = useState(false)
  const [progress, setProgress] = useState(0)
  const { toast } = useToast()

  // Form state
  const [formData, setFormData] = useState({
    // System setup
    hostname: "minecraft-server",
    timezone: "UTC",
    networkConfig: "dhcp",
    staticIp: "",
    gateway: "",
    dns: "",

    // Server setup
    serverName: "",
    serverType: "vanilla",
    serverVersion: "1.19.2",
    memory: "2048",
    port: "25565",

    // Mod setup
    enableMods: false,
    modLoader: "fabric",
    modpackUrl: "",

    // Remote access
    enableRemoteAccess: true,
    accessPin: Math.floor(100000 + Math.random() * 900000).toString(), // 6-digit pin
  })

  const updateFormData = (key: string, value: string | boolean) => {
    setFormData((prev) => ({ ...prev, [key]: value }))
  }

  const handleNext = () => {
    if (step < (isNewServer ? 4 : 5)) {
      setStep(step + 1)
    }
  }

  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1)
    }
  }

  const handleComplete = async () => {
    setIsLoading(true)

    // Simulate installation process
    for (let i = 0; i <= 100; i += 5) {
      setProgress(i)
      await new Promise((resolve) => setTimeout(resolve, 300))
    }

    // In a real implementation, this would send the configuration to the server
    try {
      if (isNewServer) {
        // Create a new server
        await fetch("/api/servers", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(formData),
        })

        toast({
          title: "Server created",
          description: `${formData.serverName} has been created successfully.`,
        })
      } else {
        // Complete system setup
        await fetch("/api/system/setup", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(formData),
        })

        toast({
          title: "Setup complete",
          description: "Your Minecraft server OS is ready to use.",
        })
      }

      onComplete()
    } catch (error) {
      console.error("Error completing setup:", error)
      toast({
        title: "Setup failed",
        description: "An error occurred during setup.",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Card className="w-full max-w-4xl mx-auto bg-slate-900 border-slate-800 text-white">
      <CardHeader>
        <CardTitle className="text-2xl">{isNewServer ? "Create New Server" : "Welcome to MinecraftOS"}</CardTitle>
        <CardDescription>
          {isNewServer
            ? "Set up a new Minecraft server with just a few clicks"
            : "Let's set up your dedicated Minecraft server operating system"}
        </CardDescription>
      </CardHeader>
      <CardContent>
        {/* Progress indicator */}
        <div className="mb-8">
          <div className="flex justify-between mb-2">
            {isNewServer
              ? ["Server Setup", "Mod Setup", "Remote Access", "Installation"].map((label, index) => (
                  <div
                    key={index}
                    className={`text-xs font-medium ${step === index + 1 ? "text-emerald-400" : "text-slate-500"}`}
                  >
                    {label}
                  </div>
                ))
              : ["System Setup", "Network Setup", "Server Setup", "Mod Setup", "Installation"].map((label, index) => (
                  <div
                    key={index}
                    className={`text-xs font-medium ${step === index + 1 ? "text-emerald-400" : "text-slate-500"}`}
                  >
                    {label}
                  </div>
                ))}
          </div>
          <div className="h-2 bg-slate-800 rounded-full">
            <div
              className="h-full bg-emerald-500 rounded-full transition-all duration-300"
              style={{ width: `${(step / (isNewServer ? 4 : 5)) * 100}%` }}
            ></div>
          </div>
        </div>

        {/* Step 1: System Setup (only for first-time setup) */}
        {!isNewServer && step === 1 && (
          <div className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="hostname">Hostname</Label>
              <Input
                id="hostname"
                value={formData.hostname}
                onChange={(e) => updateFormData("hostname", e.target.value)}
                className="bg-slate-800 border-slate-700"
              />
              <p className="text-xs text-slate-400">This will be the name of your server on the network</p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="timezone">Timezone</Label>
              <Select value={formData.timezone} onValueChange={(value) => updateFormData("timezone", value)}>
                <SelectTrigger id="timezone" className="bg-slate-800 border-slate-700">
                  <SelectValue placeholder="Select timezone" />
                </SelectTrigger>
                <SelectContent className="bg-slate-800 border-slate-700">
                  <SelectItem value="UTC">UTC</SelectItem>
                  <SelectItem value="America/New_York">America/New_York</SelectItem>
                  <SelectItem value="America/Los_Angeles">America/Los_Angeles</SelectItem>
                  <SelectItem value="Europe/London">Europe/London</SelectItem>
                  <SelectItem value="Europe/Paris">Europe/Paris</SelectItem>
                  <SelectItem value="Asia/Tokyo">Asia/Tokyo</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>System Updates</Label>
              <div className="flex items-center space-x-2">
                <Checkbox id="autoUpdates" defaultChecked />
                <Label htmlFor="autoUpdates">Enable automatic system updates</Label>
              </div>
            </div>
          </div>
        )}

        {/* Step 2: Network Setup (only for first-time setup) */}
        {!isNewServer && step === 2 && (
          <div className="space-y-6">
            <div className="space-y-2">
              <Label>Network Configuration</Label>
              <div className="flex items-center space-x-2 mb-4">
                <Checkbox
                  id="dhcp"
                  checked={formData.networkConfig === "dhcp"}
                  onCheckedChange={() => updateFormData("networkConfig", "dhcp")}
                />
                <Label htmlFor="dhcp">Use DHCP (automatic IP address)</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="static"
                  checked={formData.networkConfig === "static"}
                  onCheckedChange={() => updateFormData("networkConfig", "static")}
                />
                <Label htmlFor="static">Use static IP address</Label>
              </div>
            </div>

            {formData.networkConfig === "static" && (
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="staticIp">IP Address</Label>
                  <Input
                    id="staticIp"
                    value={formData.staticIp}
                    onChange={(e) => updateFormData("staticIp", e.target.value)}
                    placeholder="192.168.1.100"
                    className="bg-slate-800 border-slate-700"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="gateway">Gateway</Label>
                  <Input
                    id="gateway"
                    value={formData.gateway}
                    onChange={(e) => updateFormData("gateway", e.target.value)}
                    placeholder="192.168.1.1"
                    className="bg-slate-800 border-slate-700"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="dns">DNS Server</Label>
                  <Input
                    id="dns"
                    value={formData.dns}
                    onChange={(e) => updateFormData("dns", e.target.value)}
                    placeholder="8.8.8.8"
                    className="bg-slate-800 border-slate-700"
                  />
                </div>
              </div>
            )}

            <div className="space-y-2">
              <Label>Port Forwarding</Label>
              <p className="text-sm text-slate-400">
                For players to connect from the internet, you'll need to set up port forwarding on your router. The
                system will automatically configure UPnP if your router supports it.
              </p>
              <div className="flex items-center space-x-2">
                <Checkbox id="upnp" defaultChecked />
                <Label htmlFor="upnp">Enable UPnP (automatic port forwarding)</Label>
              </div>
            </div>
          </div>
        )}

        {/* Step 2/3: Server Setup */}
        {(isNewServer && step === 1) ||
          (!isNewServer && step === 3 && (
            <div className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="serverName">Server Name</Label>
                <Input
                  id="serverName"
                  value={formData.serverName}
                  onChange={(e) => updateFormData("serverName", e.target.value)}
                  placeholder="My Minecraft Server"
                  className="bg-slate-800 border-slate-700"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="serverType">Server Type</Label>
                  <Select value={formData.serverType} onValueChange={(value) => updateFormData("serverType", value)}>
                    <SelectTrigger id="serverType" className="bg-slate-800 border-slate-700">
                      <SelectValue placeholder="Select server type" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 border-slate-700">
                      <SelectItem value="vanilla">Vanilla</SelectItem>
                      <SelectItem value="paper">Paper</SelectItem>
                      <SelectItem value="spigot">Spigot</SelectItem>
                      <SelectItem value="forge">Forge</SelectItem>
                      <SelectItem value="fabric">Fabric</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="serverVersion">Version</Label>
                  <Select
                    value={formData.serverVersion}
                    onValueChange={(value) => updateFormData("serverVersion", value)}
                  >
                    <SelectTrigger id="serverVersion" className="bg-slate-800 border-slate-700">
                      <SelectValue placeholder="Select version" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 border-slate-700">
                      <SelectItem value="1.19.2">1.19.2</SelectItem>
                      <SelectItem value="1.18.2">1.18.2</SelectItem>
                      <SelectItem value="1.17.1">1.17.1</SelectItem>
                      <SelectItem value="1.16.5">1.16.5</SelectItem>
                      <SelectItem value="1.12.2">1.12.2</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="memory">Memory (MB)</Label>
                  <Input
                    id="memory"
                    type="number"
                    value={formData.memory}
                    onChange={(e) => updateFormData("memory", e.target.value)}
                    className="bg-slate-800 border-slate-700"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="port">Server Port</Label>
                  <Input
                    id="port"
                    value={formData.port}
                    onChange={(e) => updateFormData("port", e.target.value)}
                    className="bg-slate-800 border-slate-700"
                  />
                </div>
              </div>
            </div>
          ))}

        {/* Step 3/4: Mod Setup */}
        {(isNewServer && step === 2) ||
          (!isNewServer && step === 4 && (
            <div className="space-y-6">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="enableMods"
                  checked={formData.enableMods as boolean}
                  onCheckedChange={(checked) => updateFormData("enableMods", Boolean(checked))}
                />
                <Label htmlFor="enableMods">Enable mods for this server</Label>
              </div>

              {formData.enableMods && (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="modLoader">Mod Loader</Label>
                    <Select value={formData.modLoader} onValueChange={(value) => updateFormData("modLoader", value)}>
                      <SelectTrigger id="modLoader" className="bg-slate-800 border-slate-700">
                        <SelectValue placeholder="Select mod loader" />
                      </SelectTrigger>
                      <SelectContent className="bg-slate-800 border-slate-700">
                        <SelectItem value="fabric">Fabric</SelectItem>
                        <SelectItem value="forge">Forge</SelectItem>
                        <SelectItem value="quilt">Quilt</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="modpackUrl">Modpack URL (Optional)</Label>
                    <Input
                      id="modpackUrl"
                      value={formData.modpackUrl}
                      onChange={(e) => updateFormData("modpackUrl", e.target.value)}
                      placeholder="https://www.curseforge.com/minecraft/modpacks/example"
                      className="bg-slate-800 border-slate-700"
                    />
                    <p className="text-xs text-slate-400">Enter a CurseForge, Modrinth, or direct download URL</p>
                  </div>

                  <div className="bg-slate-800 p-4 rounded-md">
                    <h3 className="text-sm font-medium mb-2">Popular Modpacks</h3>
                    <div className="grid grid-cols-3 gap-2">
                      {["All The Mods 7", "Better Minecraft", "RLCraft"].map((modpack) => (
                        <Button
                          key={modpack}
                          variant="outline"
                          className="h-auto py-2 justify-start text-left"
                          onClick={() =>
                            updateFormData(
                              "modpackUrl",
                              `https://www.curseforge.com/minecraft/modpacks/${modpack.toLowerCase().replace(/\s+/g, "-")}`,
                            )
                          }
                        >
                          {modpack}
                        </Button>
                      ))}
                    </div>
                  </div>
                </>
              )}
            </div>
          ))}

        {/* Step 4: Remote Access */}
        {(isNewServer && step === 3) ||
          (!isNewServer && step === 4 && (
            <div className="space-y-6">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="enableRemoteAccess"
                  checked={formData.enableRemoteAccess as boolean}
                  onCheckedChange={(checked) => updateFormData("enableRemoteAccess", Boolean(checked))}
                />
                <Label htmlFor="enableRemoteAccess">Enable remote access to manage server from other devices</Label>
              </div>

              {formData.enableRemoteAccess && (
                <div className="bg-slate-800 p-6 rounded-md flex flex-col items-center">
                  <div className="mb-4 text-center">
                    <h3 className="text-lg font-medium mb-1">Your Access PIN</h3>
                    <p className="text-sm text-slate-400 mb-4">Use this PIN to connect from another device</p>

                    <div className="flex justify-center gap-2 mb-4">
                      {formData.accessPin.split("").map((digit, index) => (
                        <div
                          key={index}
                          className="w-10 h-12 bg-slate-700 rounded-md flex items-center justify-center text-xl font-bold"
                        >
                          {digit}
                        </div>
                      ))}
                    </div>

                    <Button
                      variant="outline"
                      onClick={() =>
                        updateFormData("accessPin", Math.floor(100000 + Math.random() * 900000).toString())
                      }
                    >
                      Generate New PIN
                    </Button>
                  </div>

                  <div className="w-48 h-48 bg-white p-2 rounded-md">
                    <div className="w-full h-full bg-slate-100 flex items-center justify-center">
                      <div className="text-black text-center">
                        <div className="text-xs mb-1">QR Code</div>
                        <div className="grid grid-cols-6 grid-rows-6 gap-1">
                          {Array(36)
                            .fill(0)
                            .map((_, i) => (
                              <div
                                key={i}
                                className={`w-full h-full ${Math.random() > 0.7 ? "bg-black" : "bg-white"}`}
                              ></div>
                            ))}
                        </div>
                      </div>
                    </div>
                  </div>

                  <p className="text-xs text-slate-400 mt-4 text-center">
                    Scan this QR code with your mobile device or enter the PIN manually to connect
                  </p>
                </div>
              )}
            </div>
          ))}

        {/* Step 5: Installation */}
        {(isNewServer && step === 4) ||
          (!isNewServer && step === 5 && (
            <div className="space-y-6">
              <div className="bg-slate-800 p-6 rounded-md">
                <h3 className="text-lg font-medium mb-4">Installation Summary</h3>

                <div className="space-y-3 mb-6">
                  {!isNewServer && (
                    <>
                      <div className="flex justify-between">
                        <span className="text-slate-400">Hostname:</span>
                        <span>{formData.hostname}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-400">Network:</span>
                        <span className="capitalize">{formData.networkConfig}</span>
                      </div>
                      {formData.networkConfig === "static" && (
                        <div className="flex justify-between">
                          <span className="text-slate-400">IP Address:</span>
                          <span>{formData.staticIp}</span>
                        </div>
                      )}
                    </>
                  )}
                  <div className="flex justify-between">
                    <span className="text-slate-400">Server Name:</span>
                    <span>{formData.serverName || "My Minecraft Server"}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Server Type:</span>
                    <span className="capitalize">{formData.serverType}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Version:</span>
                    <span>{formData.serverVersion}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Memory:</span>
                    <span>{formData.memory} MB</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Port:</span>
                    <span>{formData.port}</span>
                  </div>
                  {formData.enableMods && (
                    <>
                      <div className="flex justify-between">
                        <span className="text-slate-400">Mod Loader:</span>
                        <span className="capitalize">{formData.modLoader}</span>
                      </div>
                      {formData.modpackUrl && (
                        <div className="flex justify-between">
                          <span className="text-slate-400">Modpack:</span>
                          <span className="truncate max-w-[300px]">{formData.modpackUrl}</span>
                        </div>
                      )}
                    </>
                  )}
                </div>

                {isLoading ? (
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>Installing...</span>
                      <span>{progress}%</span>
                    </div>
                    <Progress value={progress} className="h-2" />
                    <p className="text-xs text-slate-400 mt-2">
                      {progress < 20 && "Preparing system..."}
                      {progress >= 20 && progress < 40 && "Downloading server files..."}
                      {progress >= 40 && progress < 60 && "Installing server..."}
                      {progress >= 60 && progress < 80 && "Configuring server..."}
                      {progress >= 80 && "Finalizing installation..."}
                    </p>
                  </div>
                ) : (
                  <p className="text-sm text-slate-400">
                    Click "Complete Setup" to start the installation process. This may take a few minutes.
                  </p>
                )}
              </div>
            </div>
          ))}
      </CardContent>
      <CardFooter className="flex justify-between">
        {step > 1 ? (
          <Button variant="outline" onClick={handleBack} disabled={isLoading}>
            Back
          </Button>
        ) : (
          <div></div>
        )}

        {step < (isNewServer ? 4 : 5) ? (
          <Button onClick={handleNext}>Next</Button>
        ) : (
          <Button onClick={handleComplete} disabled={isLoading}>
            {isLoading ? "Installing..." : "Complete Setup"}
          </Button>
        )}
      </CardFooter>
    </Card>
  )
}
