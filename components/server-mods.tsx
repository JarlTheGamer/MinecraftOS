"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Download, Search, Trash2, Upload } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

type ServerModsProps = {
  serverId: string
  serverType: string
}

type Mod = {
  id: string
  name: string
  version: string
  mcVersion: string
  author: string
  status: "enabled" | "disabled"
  size: string
}

export function ServerMods({ serverId, serverType }: ServerModsProps) {
  const [searchTerm, setSearchTerm] = useState("")
  const [isUploading, setIsUploading] = useState(false)
  const [isInstalling, setIsInstalling] = useState(false)
  const { toast } = useToast()

  // In a real implementation, this would be fetched from the server
  const [installedMods, setInstalledMods] = useState<Mod[]>([
    {
      id: "1",
      name: "JourneyMap",
      version: "5.9.0",
      mcVersion: "1.19.2",
      author: "techbrew",
      status: "enabled",
      size: "3.2 MB",
    },
    {
      id: "2",
      name: "OptiFine",
      version: "HD_U_H9",
      mcVersion: "1.19.2",
      author: "sp614x",
      status: "enabled",
      size: "5.8 MB",
    },
    {
      id: "3",
      name: "Biomes O' Plenty",
      version: "1.19.2-17.1.1.162",
      mcVersion: "1.19.2",
      author: "Forstride",
      status: "enabled",
      size: "8.4 MB",
    },
  ])

  const [availableMods] = useState<Mod[]>([
    {
      id: "4",
      name: "Just Enough Items",
      version: "11.5.0.297",
      mcVersion: "1.19.2",
      author: "mezz",
      status: "enabled",
      size: "4.1 MB",
    },
    {
      id: "5",
      name: "Create",
      version: "0.5.0.i",
      mcVersion: "1.19.2",
      author: "simibubi",
      status: "enabled",
      size: "12.6 MB",
    },
    {
      id: "6",
      name: "Waystones",
      version: "11.3.1",
      mcVersion: "1.19.2",
      author: "BlayTheNinth",
      status: "enabled",
      size: "2.8 MB",
    },
  ])

  const filteredInstalledMods = installedMods.filter(
    (mod) =>
      mod.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      mod.author.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const filteredAvailableMods = availableMods.filter(
    (mod) =>
      mod.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      mod.author.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const toggleModStatus = (modId: string) => {
    setInstalledMods((mods) =>
      mods.map((mod) =>
        mod.id === modId ? { ...mod, status: mod.status === "enabled" ? "disabled" : "enabled" } : mod,
      ),
    )

    toast({
      title: "Mod status updated",
      description: "The mod status has been updated. Server restart required.",
    })
  }

  const deleteMod = (modId: string) => {
    setInstalledMods((mods) => mods.filter((mod) => mod.id !== modId))

    toast({
      title: "Mod removed",
      description: "The mod has been removed from the server.",
    })
  }

  const installMod = (mod: Mod) => {
    setIsInstalling(true)

    // Simulate installation
    setTimeout(() => {
      setInstalledMods((mods) => [...mods, mod])
      setIsInstalling(false)

      toast({
        title: "Mod installed",
        description: `${mod.name} has been installed successfully.`,
      })
    }, 2000)
  }

  const handleUpload = () => {
    setIsUploading(true)

    // Simulate upload
    setTimeout(() => {
      setIsUploading(false)

      toast({
        title: "Mod uploaded",
        description: "Your mod has been uploaded successfully.",
      })
    }, 2000)
  }

  return (
    <Card className="bg-slate-900 border-slate-800">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>Mods Manager</CardTitle>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleUpload} disabled={isUploading}>
            <Upload className="h-4 w-4 mr-2" />
            {isUploading ? "Uploading..." : "Upload Mod"}
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="mb-4">
          <div className="relative">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-slate-500" />
            <Input
              placeholder="Search mods..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-8 bg-slate-800 border-slate-700"
            />
          </div>
        </div>

        <Tabs defaultValue="installed" className="w-full">
          <TabsList className="bg-slate-800 border-slate-700 mb-4">
            <TabsTrigger value="installed">Installed ({installedMods.length})</TabsTrigger>
            <TabsTrigger value="browse">Browse Mods</TabsTrigger>
            <TabsTrigger value="modpacks">Modpacks</TabsTrigger>
          </TabsList>

          <TabsContent value="installed">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Name</TableHead>
                  <TableHead>Version</TableHead>
                  <TableHead>Author</TableHead>
                  <TableHead>Size</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredInstalledMods.length > 0 ? (
                  filteredInstalledMods.map((mod) => (
                    <TableRow key={mod.id} className="hover:bg-slate-800/50">
                      <TableCell className="font-medium">{mod.name}</TableCell>
                      <TableCell>{mod.version}</TableCell>
                      <TableCell>{mod.author}</TableCell>
                      <TableCell>{mod.size}</TableCell>
                      <TableCell>
                        <Badge variant={mod.status === "enabled" ? "default" : "secondary"}>{mod.status}</Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button variant="ghost" size="sm" onClick={() => toggleModStatus(mod.id)}>
                            {mod.status === "enabled" ? "Disable" : "Enable"}
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => deleteMod(mod.id)}>
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center">
                      {searchTerm ? "No mods match your search" : "No mods installed"}
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TabsContent>

          <TabsContent value="browse">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Name</TableHead>
                  <TableHead>Version</TableHead>
                  <TableHead>Author</TableHead>
                  <TableHead>Size</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredAvailableMods.length > 0 ? (
                  filteredAvailableMods.map((mod) => (
                    <TableRow key={mod.id} className="hover:bg-slate-800/50">
                      <TableCell className="font-medium">{mod.name}</TableCell>
                      <TableCell>{mod.version}</TableCell>
                      <TableCell>{mod.author}</TableCell>
                      <TableCell>{mod.size}</TableCell>
                      <TableCell className="text-right">
                        <Button variant="outline" size="sm" onClick={() => installMod(mod)} disabled={isInstalling}>
                          <Download className="h-4 w-4 mr-2" />
                          {isInstalling ? "Installing..." : "Install"}
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center">
                      {searchTerm ? "No mods match your search" : "No mods available"}
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TabsContent>

          <TabsContent value="modpacks">
            <div className="grid grid-cols-3 gap-4">
              {[
                "RLCraft",
                "All The Mods 7",
                "Better Minecraft",
                "Create Above & Beyond",
                "Vault Hunters",
                "SkyFactory 4",
              ].map((pack, index) => (
                <Card key={index} className="bg-slate-800 border-slate-700">
                  <CardContent className="p-4">
                    <div className="aspect-video bg-slate-700 rounded-md mb-3 flex items-center justify-center">
                      <span className="text-xs text-slate-400">Modpack Image</span>
                    </div>
                    <h3 className="font-medium mb-1">{pack}</h3>
                    <p className="text-xs text-slate-400 mb-3">A popular modpack with over 100 mods</p>
                    <Button size="sm" className="w-full">
                      Install
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  )
}
