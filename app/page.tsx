"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { FirstTimeSetup } from "@/components/first-time-setup"
import { SetupWizard } from "@/components/setup-wizard"
import { ServerList } from "@/components/server-list"
import { RemoteAccessSetup } from "@/components/remote-access-setup"
import { SystemInfo } from "@/components/system-info"
import { NetworkSettings } from "@/components/network-settings"
import { ServerDownloader } from "@/components/server-downloader"
import { useToast } from "@/hooks/use-toast"

export default function Home() {
  const [firstRun, setFirstRun] = useState(true)
  const [setupComplete, setSetupComplete] = useState(false)
  const [activeTab, setActiveTab] = useState("servers")
  const [isLoading, setIsLoading] = useState(true)
  const { toast } = useToast()

  // Check if this is the first run
  useEffect(() => {
    // In a real implementation, this would check if the system has been set up
    const checkFirstRun = async () => {
      try {
        setIsLoading(true)
        const response = await fetch("/api/system/status")
        const data = await response.json()

        if (data.setupComplete) {
          setFirstRun(false)
          setSetupComplete(true)
        }
      } catch (error) {
        console.error("Error checking system status:", error)
      } finally {
        setIsLoading(false)
      }
    }

    checkFirstRun()
  }, [])

  const handleSetupComplete = () => {
    setFirstRun(false)
    setSetupComplete(true)
    toast({
      title: "Setup complete",
      description: "Your Minecraft server OS is ready to use.",
    })
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-slate-950">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500 mx-auto mb-4"></div>
          <h2 className="text-xl font-medium text-white">Loading MinecraftOS</h2>
          <p className="text-slate-400">Please wait while we check your system...</p>
        </div>
      </div>
    )
  }

  if (firstRun) {
    return (
      <main className="min-h-screen bg-slate-950 text-white p-6 flex items-center justify-center">
        <FirstTimeSetup onComplete={handleSetupComplete} />
      </main>
    )
  }

  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <div className="flex">
        {/* Sidebar */}
        <div className="w-64 bg-slate-900 min-h-screen p-4 flex flex-col">
          <div className="flex items-center gap-2 mb-8">
            <div className="w-8 h-8 rounded-full bg-emerald-500 flex items-center justify-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
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
            <h1 className="text-xl font-bold">MinecraftOS</h1>
          </div>

          <nav className="space-y-1">
            <Button
              variant={activeTab === "servers" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("servers")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
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
              Servers
            </Button>
            <Button
              variant={activeTab === "download" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("download")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              Download Server
            </Button>
            <Button
              variant={activeTab === "console" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("console")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="4 17 10 11 4 5"></polyline>
                <line x1="12" y1="19" x2="20" y2="19"></line>
              </svg>
              Console
            </Button>
            <Button
              variant={activeTab === "files" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("files")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
                <polyline points="10 9 9 9 8 9"></polyline>
              </svg>
              Files
            </Button>
            <Button
              variant={activeTab === "backups" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("backups")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="17 8 12 3 7 8"></polyline>
                <line x1="12" y1="3" x2="12" y2="15"></line>
              </svg>
              Backups
            </Button>
            <Button
              variant={activeTab === "mods" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("mods")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path>
              </svg>
              Mods
            </Button>
            <Button
              variant={activeTab === "remote" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("remote")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"></path>
                <polyline points="10 17 15 12 10 7"></polyline>
                <line x1="15" y1="12" x2="3" y2="12"></line>
              </svg>
              Remote Access
            </Button>
            <Button
              variant={activeTab === "network" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("network")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
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
              Network
            </Button>
            <Button
              variant={activeTab === "system" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("system")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="3"></circle>
                <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
              </svg>
              System
            </Button>
            <Button
              variant={activeTab === "terminal" ? "default" : "ghost"}
              className="w-full justify-start"
              onClick={() => setActiveTab("terminal")}
            >
              <svg
                className="mr-2 h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="4 17 10 11 4 5"></polyline>
                <line x1="12" y1="19" x2="20" y2="19"></line>
              </svg>
              Terminal
            </Button>
          </nav>

          <div className="mt-auto">
            <SystemInfo />
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 p-6">
          {activeTab === "servers" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <h2 className="text-2xl font-bold">Minecraft Servers</h2>
                <Button onClick={() => setActiveTab("new-server")}>
                  <svg
                    className="mr-2 h-4 w-4"
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                  </svg>
                  Add Server
                </Button>
              </div>
              <ServerList />
            </div>
          )}

          {activeTab === "download" && (
            <div className="space-y-6">
              <h2 className="text-2xl font-bold">Download Server Software</h2>
              <ServerDownloader />
            </div>
          )}

          {activeTab === "new-server" && (
            <div className="space-y-6">
              <div className="flex items-center gap-2">
                <Button variant="ghost" onClick={() => setActiveTab("servers")}>
                  <svg
                    className="h-4 w-4"
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <line x1="19" y1="12" x2="5" y2="12"></line>
                    <polyline points="12 19 5 12 12 5"></polyline>
                  </svg>
                </Button>
                <h2 className="text-2xl font-bold">Create New Server</h2>
              </div>
              <SetupWizard onComplete={() => setActiveTab("servers")} isNewServer={true} />
            </div>
          )}

          {activeTab === "remote" && (
            <div className="space-y-6">
              <h2 className="text-2xl font-bold">Remote Access</h2>
              <RemoteAccessSetup />
            </div>
          )}

          {activeTab === "network" && (
            <div className="space-y-6">
              <h2 className="text-2xl font-bold">Network Settings</h2>
              <NetworkSettings />
            </div>
          )}

          {activeTab === "system" && (
            <div className="space-y-6">
              <h2 className="text-2xl font-bold">System Information</h2>
              <Card className="bg-slate-900 border-slate-800">
                <CardContent className="p-6">
                  <div className="grid grid-cols-2 gap-6">
                    <div>
                      <h3 className="text-lg font-medium mb-4">System Information</h3>
                      <div className="space-y-2">
                        <div className="flex justify-between">
                          <span className="text-slate-400">OS Version:</span>
                          <span>MinecraftOS 1.0.0</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Kernel:</span>
                          <span>Linux 5.15.0-generic</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Architecture:</span>
                          <span>x86_64</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Hostname:</span>
                          <span>minecraft-server</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Uptime:</span>
                          <span>3 days, 7 hours, 15 minutes</span>
                        </div>
                      </div>
                    </div>

                    <div>
                      <h3 className="text-lg font-medium mb-4">Hardware Information</h3>
                      <div className="space-y-2">
                        <div className="flex justify-between">
                          <span className="text-slate-400">CPU:</span>
                          <span>Intel Core i7-10700K (8 cores)</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Memory:</span>
                          <span>32 GB DDR4</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Storage:</span>
                          <span>1 TB SSD</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Network:</span>
                          <span>1 Gbps Ethernet</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="mt-6">
                    <h3 className="text-lg font-medium mb-4">System Actions</h3>
                    <div className="flex gap-3">
                      <Button variant="outline">Restart System</Button>
                      <Button variant="outline">Shutdown System</Button>
                      <Button variant="outline">Check for Updates</Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}

          {activeTab === "terminal" && (
            <div className="space-y-6">
              <h2 className="text-2xl font-bold">Terminal</h2>
              <Card className="bg-slate-900 border-slate-800">
                <CardContent className="p-0">
                  <div className="bg-black text-green-400 font-mono text-sm p-4 rounded-md h-[600px] overflow-y-auto">
                    <div>root@minecraft-server:~# uname -a</div>
                    <div>Linux minecraft-server 5.15.0-generic #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux</div>
                    <div>root@minecraft-server:~# df -h</div>
                    <div>Filesystem Size Used Avail Use% Mounted on</div>
                    <div>/dev/sda1 932G 124G 808G 14% /</div>
                    <div>tmpfs 16G 0 16G 0% /dev/shm</div>
                    <div>root@minecraft-server:~# systemctl status minecraft-server</div>
                    <div>● minecraft-server.service - Minecraft Server</div>
                    <div>
                      {" "}
                      Loaded: loaded (/etc/systemd/system/minecraft-server.service; enabled; vendor preset: enabled)
                    </div>
                    <div> Active: active (running) since Mon 2023-04-17 14:30:45 UTC; 3 days ago</div>
                    <div> Main PID: 1234 (java)</div>
                    <div> Tasks: 43 (limit: 4915)</div>
                    <div> Memory: 2.4G</div>
                    <div> CGroup: /system.slice/minecraft-server.service</div>
                    <div> └─1234 /usr/bin/java -Xmx4G -Xms1G -jar server.jar nogui</div>
                    <div>root@minecraft-server:~# _</div>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </div>
    </main>
  )
}
