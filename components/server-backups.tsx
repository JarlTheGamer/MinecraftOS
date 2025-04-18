"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Download, Save, Trash2 } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

type Backup = {
  id: string
  name: string
  date: string
  size: string
  worldName: string
}

export function ServerBackups() {
  const { toast } = useToast()
  const [isCreatingBackup, setIsCreatingBackup] = useState(false)
  const [backupProgress, setBackupProgress] = useState(0)

  // In a real implementation, this would be fetched from the server
  const [backups, setBackups] = useState<Backup[]>([
    {
      id: "1",
      name: "Backup 2023-04-18",
      date: "2023-04-18 10:30",
      size: "1.2 GB",
      worldName: "world",
    },
    {
      id: "2",
      name: "Backup 2023-04-17",
      date: "2023-04-17 09:15",
      size: "1.1 GB",
      worldName: "world",
    },
    {
      id: "3",
      name: "Backup 2023-04-16",
      date: "2023-04-16 22:45",
      size: "1.0 GB",
      worldName: "world",
    },
  ])

  const createBackup = async () => {
    setIsCreatingBackup(true)
    setBackupProgress(0)

    // In a real implementation, this would create a backup of the server
    try {
      // Simulate backup progress
      const interval = setInterval(() => {
        setBackupProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval)
            return 100
          }
          return prev + 10
        })
      }, 300)

      // Simulate backup completion
      setTimeout(() => {
        clearInterval(interval)
        setBackupProgress(100)

        // Add new backup to the list
        const newBackup: Backup = {
          id: String(backups.length + 1),
          name: `Backup ${new Date().toISOString().split("T")[0]}`,
          date: new Date().toLocaleString(),
          size: "1.3 GB",
          worldName: "world",
        }

        setBackups([newBackup, ...backups])

        toast({
          title: "Backup created",
          description: "Server backup has been created successfully.",
        })

        setIsCreatingBackup(false)
      }, 3000)
    } catch (error) {
      toast({
        title: "Failed to create backup",
        description: "An error occurred while creating the backup.",
        variant: "destructive",
      })
      setIsCreatingBackup(false)
    }
  }

  const deleteBackup = (backupId: string) => {
    // In a real implementation, this would delete the backup from the server
    setBackups(backups.filter((backup) => backup.id !== backupId))

    toast({
      title: "Backup deleted",
      description: "Server backup has been deleted.",
    })
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-center">
          <div>
            <CardTitle>Backups</CardTitle>
            <CardDescription>Manage server backups</CardDescription>
          </div>
          <Button onClick={createBackup} disabled={isCreatingBackup}>
            <Save className="h-4 w-4 mr-2" />
            {isCreatingBackup ? "Creating Backup..." : "Create Backup"}
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {isCreatingBackup && (
          <div className="mb-4 space-y-2">
            <div className="flex justify-between text-sm">
              <span>Creating backup...</span>
              <span>{backupProgress}%</span>
            </div>
            <Progress value={backupProgress} />
          </div>
        )}

        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Date</TableHead>
              <TableHead>Size</TableHead>
              <TableHead>World</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {backups.length > 0 ? (
              backups.map((backup) => (
                <TableRow key={backup.id}>
                  <TableCell className="font-medium">{backup.name}</TableCell>
                  <TableCell>{backup.date}</TableCell>
                  <TableCell>{backup.size}</TableCell>
                  <TableCell>{backup.worldName}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button variant="ghost" size="icon">
                        <Download className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => deleteBackup(backup.id)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={5} className="text-center">
                  No backups found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}
