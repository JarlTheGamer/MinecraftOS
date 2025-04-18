"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Progress } from "@/components/ui/progress"
import { useToast } from "@/hooks/use-toast"

type FirstTimeSetupProps = {
  onComplete: () => void
}

export function FirstTimeSetup({ onComplete }: FirstTimeSetupProps) {
  const [step, setStep] = useState(1)
  const [isLoading, setIsLoading] = useState(false)
  const [progress, setProgress] = useState(0)
  const { toast } = useToast()

  // Form state
  const [formData, setFormData] = useState({
    // System setup
    hostname: "minecraft-server",
    timezone: "UTC",
    adminPort: "8080",

    // Network setup
    networkConfig: "dhcp",
    staticIp: "",
    gateway: "",
    dns: "",

    // Security setup
    username: "admin",
    password: "",
    confirmPassword: "",
    enableFirewall: true,

    // Minecraft setup
    installJava: true,
    javaVersion: "17",
    autoStart: true,
    backupEnabled: true,
    backupInterval: "daily",

    // Remote access
    enableRemoteAccess: true,
    remotePort: "8192",
  })

  const updateFormData = (key: string, value: string | boolean | number) => {
    setFormData((prev) => ({ ...prev, [key]: value }))
  }

  const handleNext = () => {
    if (step < 6) {
      setStep(step + 1)
    }
  }

  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1)
    }
  }

  const validateCurrentStep = () => {
    switch (step) {
      case 1:
        // Welcome step - no validation needed
        return true
      case 2:
        // System setup
        if (!formData.hostname.trim()) {
          toast({
            title: "Validation Error",
            description: "Hostname is required",
            variant: "destructive",
          })
          return false
        }
        if (!formData.adminPort || Number.isNaN(Number(formData.adminPort))) {
          toast({
            title: "Validation Error",
            description: "Admin port must be a valid number",
            variant: "destructive",
          })
          return false
        }
        return true
      case 3:
        // Network setup
        if (formData.networkConfig === "static") {
          if (!formData.staticIp.trim()) {
            toast({
              title: "Validation Error",
              description: "IP address is required for static configuration",
              variant: "destructive",
            })
            return false
          }
          if (!formData.gateway.trim()) {
            toast({
              title: "Validation Error",
              description: "Gateway is required for static configuration",
              variant: "destructive",
            })
            return false
          }
          if (!formData.dns.trim()) {
            toast({
              title: "Validation Error",
              description: "DNS server is required for static configuration",
              variant: "destructive",
            })
            return false
          }
        }
        return true
      case 4:
        // Security setup
        if (!formData.username.trim()) {
          toast({
            title: "Validation Error",
            description: "Username is required",
            variant: "destructive",
          })
          return false
        }
        if (!formData.password.trim()) {
          toast({
            title: "Validation Error",
            description: "Password is required",
            variant: "destructive",
          })
          return false
        }
        if (formData.password !== formData.confirmPassword) {
          toast({
            title: "Validation Error",
            description: "Passwords do not match",
            variant: "destructive",
          })
          return false
        }
        return true
      case 5:
        // Minecraft setup - no validation needed
        return true
      default:
        return true
    }
  }

  const handleNextWithValidation = () => {
    if (validateCurrentStep()) {
      handleNext()
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
      const response = await fetch("/api/system/setup", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        throw new Error("Failed to complete setup")
      }

      toast({
        title: "Setup complete",
        description: "Your Minecraft server OS is ready to use.",
      })

      // Create setup_complete file to indicate setup is done
      await fetch("/api/system/setup-complete", {
        method: "POST",
      })

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
        <CardTitle className="text-2xl">Welcome to MinecraftOS</CardTitle>
        <CardDescription>Let's set up your dedicated Minecraft server operating system</CardDescription>
      </CardHeader>
      <CardContent>
        {/* Progress indicator */}
        <div className="mb-8">
          <div className="flex justify-between mb-2">
            {["Welcome", "System", "Network", "Security", "Minecraft", "Complete"].map((label, index) => (
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
              style={{ width: `${(step / 6) * 100}%` }}
            ></div>
          </div>
        </div>

        {/* Step 1: Welcome */}
        {step === 1 && (
          <div className="space-y-6">
            <div className="flex justify-center mb-6">
              <div className="w-32 h-32 bg-emerald-500 rounded-full flex items-center justify-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="64"
                  height="64"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                  <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                  <line x1="6" y1="6" x2="6.01" y2="6"></line>
                  <line x1="6" y1="18" x2="6.01" y2="18"></line>
                </svg>
              </div>
            </div>

            <div className="text-center space-y-4">
              <h2 className="text-xl font-bold">Welcome to MinecraftOS Setup</h2>
              <p className="text-slate-400">
                This wizard will guide you through setting up your Minecraft server operating system. We'll configure
                your system, network, security, and Minecraft server settings.
              </p>
              <p className="text-slate-400">Click "Next" to begin the setup process.</p>
            </div>

            <div className="grid grid-cols-2 gap-4 mt-8">
              <div className="bg-slate-800 p-4 rounded-lg flex items-center">
                <div className="bg-emerald-500/20 p-2 rounded-full mr-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500"
                  >
                    <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path>
                  </svg>
                </div>
                <div>
                  <h3 className="font-medium">Easy Server Management</h3>
                  <p className="text-xs text-slate-400">Manage all your Minecraft servers from one place</p>
                </div>
              </div>

              <div className="bg-slate-800 p-4 rounded-lg flex items-center">
                <div className="bg-emerald-500/20 p-2 rounded-full mr-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500"
                  >
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="17 8 12 3 7 8"></polyline>
                    <line x1="12" y1="3" x2="12" y2="15"></line>
                  </svg>
                </div>
                <div>
                  <h3 className="font-medium">Automatic Backups</h3>
                  <p className="text-xs text-slate-400">Keep your worlds safe with scheduled backups</p>
                </div>
              </div>

              <div className="bg-slate-800 p-4 rounded-lg flex items-center">
                <div className="bg-emerald-500/20 p-2 rounded-full mr-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500"
                  >
                    <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"></path>
                    <polyline points="10 17 15 12 10 7"></polyline>
                    <line x1="15" y1="12" x2="3" y2="12"></line>
                  </svg>
                </div>
                <div>
                  <h3 className="font-medium">Remote Access</h3>
                  <p className="text-xs text-slate-400">Manage your server from anywhere with secure remote access</p>
                </div>
              </div>

              <div className="bg-slate-800 p-4 rounded-lg flex items-center">
                <div className="bg-emerald-500/20 p-2 rounded-full mr-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500"
                  >
                    <circle cx="12" cy="12" r="3"></circle>
                    <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
                  </svg>
                </div>
                <div>
                  <h3 className="font-medium">Advanced Configuration</h3>
                  <p className="text-xs text-slate-400">Fine-tune every aspect of your Minecraft servers</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 2: System Setup */}
        {step === 2 && (
          <div className="space-y-6">
            <div className="flex gap-6">
              <div className="flex-1 space-y-6">
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
                  <Label htmlFor="adminPort">Admin Panel Port</Label>
                  <Input
                    id="adminPort"
                    value={formData.adminPort}
                    onChange={(e) => updateFormData("adminPort", e.target.value)}
                    className="bg-slate-800 border-slate-700"
                  />
                  <p className="text-xs text-slate-400">The port used to access the admin panel (default: 8080)</p>
                </div>
              </div>

              <div className="w-64 flex flex-col items-center justify-center">
                <div className="bg-slate-800 p-4 rounded-lg mb-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="64"
                    height="64"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500 mx-auto"
                  >
                    <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                    <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                    <line x1="6" y1="6" x2="6.01" y2="6"></line>
                    <line x1="6" y1="18" x2="6.01" y2="18"></line>
                  </svg>
                </div>
                <p className="text-sm text-slate-400 text-center">
                  Configure your system settings to ensure optimal performance for your Minecraft server.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Step 3: Network Setup */}
        {step === 3 && (
          <div className="space-y-6">
            <div className="flex gap-6">
              <div className="flex-1 space-y-6">
                <div className="space-y-2">
                  <Label>Network Configuration</Label>
                  <div className="flex items-center space-x-2 mb-4">
                    <input
                      type="radio"
                      id="dhcp"
                      checked={formData.networkConfig === "dhcp"}
                      onChange={() => updateFormData("networkConfig", "dhcp")}
                      className="text-emerald-500"
                    />
                    <Label htmlFor="dhcp">Use DHCP (automatic IP address)</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <input
                      type="radio"
                      id="static"
                      checked={formData.networkConfig === "static"}
                      onChange={() => updateFormData("networkConfig", "static")}
                      className="text-emerald-500"
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
              </div>

              <div className="w-64 flex flex-col items-center justify-center">
                <div className="bg-slate-800 p-4 rounded-lg mb-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="64"
                    height="64"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500 mx-auto"
                  >
                    <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                    <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                    <line x1="6" y1="6" x2="6.01" y2="6"></line>
                    <line x1="6" y1="18" x2="6.01" y2="18"></line>
                  </svg>
                </div>
                <p className="text-sm text-slate-400 text-center">
                  Configure your network settings to ensure players can connect to your Minecraft server.
                </p>
                <div className="mt-4 bg-slate-800 p-3 rounded-lg">
                  <p className="text-xs text-slate-400">
                    <strong>Note:</strong> For players to connect from the internet, you'll need to set up port
                    forwarding on your router for port 25565.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 4: Security Setup */}
        {step === 4 && (
          <div className="space-y-6">
            <div className="flex gap-6">
              <div className="flex-1 space-y-6">
                <div className="space-y-2">
                  <Label htmlFor="username">Admin Username</Label>
                  <Input
                    id="username"
                    value={formData.username}
                    onChange={(e) => updateFormData("username", e.target.value)}
                    className="bg-slate-800 border-slate-700"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="password">Admin Password</Label>
                  <Input
                    id="password"
                    type="password"
                    value={formData.password}
                    onChange={(e) => updateFormData("password", e.target.value)}
                    className="bg-slate-800 border-slate-700"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="confirmPassword">Confirm Password</Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    value={formData.confirmPassword}
                    onChange={(e) => updateFormData("confirmPassword", e.target.value)}
                    className="bg-slate-800 border-slate-700"
                  />
                </div>

                <div className="flex items-center justify-between">
                  <Label htmlFor="enableFirewall">Enable Firewall</Label>
                  <Switch
                    id="enableFirewall"
                    checked={formData.enableFirewall as boolean}
                    onCheckedChange={(checked) => updateFormData("enableFirewall", checked)}
                  />
                </div>
              </div>

              <div className="w-64 flex flex-col items-center justify-center">
                <div className="bg-slate-800 p-4 rounded-lg mb-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="64"
                    height="64"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500 mx-auto"
                  >
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                  </svg>
                </div>
                <p className="text-sm text-slate-400 text-center">
                  Set up security measures to protect your Minecraft server from unauthorized access.
                </p>
                <div className="mt-4 bg-slate-800 p-3 rounded-lg">
                  <p className="text-xs text-slate-400">
                    <strong>Security Tip:</strong> Use a strong password with a mix of letters, numbers, and special
                    characters.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 5: Minecraft Setup */}
        {step === 5 && (
          <div className="space-y-6">
            <div className="flex gap-6">
              <div className="flex-1 space-y-6">
                <div className="flex items-center justify-between">
                  <Label htmlFor="installJava">Install Java</Label>
                  <Switch
                    id="installJava"
                    checked={formData.installJava as boolean}
                    onCheckedChange={(checked) => updateFormData("installJava", checked)}
                  />
                </div>

                {formData.installJava && (
                  <div className="space-y-2">
                    <Label htmlFor="javaVersion">Java Version</Label>
                    <Select
                      value={formData.javaVersion.toString()}
                      onValueChange={(value) => updateFormData("javaVersion", value)}
                    >
                      <SelectTrigger id="javaVersion" className="bg-slate-800 border-slate-700">
                        <SelectValue placeholder="Select Java version" />
                      </SelectTrigger>
                      <SelectContent className="bg-slate-800 border-slate-700">
                        <SelectItem value="8">Java 8</SelectItem>
                        <SelectItem value="11">Java 11</SelectItem>
                        <SelectItem value="17">Java 17 (Recommended)</SelectItem>
                        <SelectItem value="21">Java 21</SelectItem>
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-slate-400">Java 17 is recommended for Minecraft 1.18+</p>
                  </div>
                )}

                <div className="flex items-center justify-between">
                  <Label htmlFor="autoStart">Auto-start servers on boot</Label>
                  <Switch
                    id="autoStart"
                    checked={formData.autoStart as boolean}
                    onCheckedChange={(checked) => updateFormData("autoStart", checked)}
                  />
                </div>

                <div className="flex items-center justify-between">
                  <Label htmlFor="backupEnabled">Enable automatic backups</Label>
                  <Switch
                    id="backupEnabled"
                    checked={formData.backupEnabled as boolean}
                    onCheckedChange={(checked) => updateFormData("backupEnabled", checked)}
                  />
                </div>

                {formData.backupEnabled && (
                  <div className="space-y-2">
                    <Label htmlFor="backupInterval">Backup Interval</Label>
                    <Select
                      value={formData.backupInterval}
                      onValueChange={(value) => updateFormData("backupInterval", value)}
                    >
                      <SelectTrigger id="backupInterval" className="bg-slate-800 border-slate-700">
                        <SelectValue placeholder="Select backup interval" />
                      </SelectTrigger>
                      <SelectContent className="bg-slate-800 border-slate-700">
                        <SelectItem value="hourly">Hourly</SelectItem>
                        <SelectItem value="daily">Daily</SelectItem>
                        <SelectItem value="weekly">Weekly</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                )}
              </div>

              <div className="w-64 flex flex-col items-center justify-center">
                <div className="bg-slate-800 p-4 rounded-lg mb-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="64"
                    height="64"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-emerald-500 mx-auto"
                  >
                    <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path>
                  </svg>
                </div>
                <p className="text-sm text-slate-400 text-center">
                  Configure Minecraft-specific settings for your server environment.
                </p>
                <div className="mt-4 bg-slate-800 p-3 rounded-lg">
                  <p className="text-xs text-slate-400">
                    <strong>Tip:</strong> Java 17 is recommended for the best performance with modern Minecraft
                    versions.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 6: Installation */}
        {step === 6 && (
          <div className="space-y-6">
            <div className="bg-slate-800 p-6 rounded-md">
              <h3 className="text-lg font-medium mb-4">Installation Summary</h3>

              <div className="space-y-3 mb-6">
                <div className="flex justify-between">
                  <span className="text-slate-400">Hostname:</span>
                  <span>{formData.hostname}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Admin Port:</span>
                  <span>{formData.adminPort}</span>
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
                <div className="flex justify-between">
                  <span className="text-slate-400">Java Version:</span>
                  <span>{formData.installJava ? formData.javaVersion : "Not installing"}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Auto-start:</span>
                  <span>{formData.autoStart ? "Enabled" : "Disabled"}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Backups:</span>
                  <span>{formData.backupEnabled ? formData.backupInterval : "Disabled"}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Remote Access:</span>
                  <span>{formData.enableRemoteAccess ? "Enabled" : "Disabled"}</span>
                </div>
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
                    {progress >= 20 && progress < 40 && "Installing required packages..."}
                    {progress >= 40 && progress < 60 && "Configuring system..."}
                    {progress >= 60 && progress < 80 && "Setting up Minecraft environment..."}
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
        )}
      </CardContent>
      <CardFooter className="flex justify-between">
        {step > 1 ? (
          <Button variant="outline" onClick={handleBack} disabled={isLoading}>
            Back
          </Button>
        ) : (
          <div></div>
        )}

        {step < 6 ? (
          <Button onClick={handleNextWithValidation}>Next</Button>
        ) : (
          <Button onClick={handleComplete} disabled={isLoading}>
            {isLoading ? "Installing..." : "Complete Setup"}
          </Button>
        )}
      </CardFooter>
    </Card>
  )
}
