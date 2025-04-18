"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Ban, MessageSquare, UserPlus, X } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

type Player = {
  id: string
  username: string
  status: "online" | "offline"
  joinedAt: string
  lastSeen?: string
  ip: string
}

export function ServerPlayers() {
  const { toast } = useToast()
  const [searchTerm, setSearchTerm] = useState("")

  // In a real implementation, this would be fetched from the server
  const [players, setPlayers] = useState<Player[]>([
    {
      id: "1",
      username: "Steve",
      status: "online",
      joinedAt: "2023-04-18 14:30",
      ip: "192.168.1.100",
    },
    {
      id: "2",
      username: "Alex",
      status: "online",
      joinedAt: "2023-04-18 15:15",
      ip: "192.168.1.101",
    },
    {
      id: "3",
      username: "Notch",
      status: "offline",
      joinedAt: "2023-04-17 10:00",
      lastSeen: "2023-04-17 12:30",
      ip: "192.168.1.102",
    },
  ])

  const filteredPlayers = players.filter((player) => player.username.toLowerCase().includes(searchTerm.toLowerCase()))

  const kickPlayer = (playerId: string) => {
    // In a real implementation, this would kick the player from the server
    setPlayers(
      players.map((player) =>
        player.id === playerId
          ? { ...player, status: "offline" as const, lastSeen: new Date().toLocaleString() }
          : player,
      ),
    )

    toast({
      title: "Player kicked",
      description: `Player has been kicked from the server.`,
    })
  }

  const banPlayer = (playerId: string) => {
    // In a real implementation, this would ban the player from the server
    setPlayers(
      players.map((player) =>
        player.id === playerId
          ? { ...player, status: "offline" as const, lastSeen: new Date().toLocaleString() }
          : player,
      ),
    )

    toast({
      title: "Player banned",
      description: `Player has been banned from the server.`,
    })
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-center">
          <div>
            <CardTitle>Players</CardTitle>
            <CardDescription>Manage players on your server</CardDescription>
          </div>
          <Button>
            <UserPlus className="h-4 w-4 mr-2" />
            Add to Whitelist
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="mb-4">
          <Input placeholder="Search players..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
        </div>

        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Username</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="hidden md:table-cell">Joined</TableHead>
              <TableHead className="hidden md:table-cell">IP Address</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredPlayers.length > 0 ? (
              filteredPlayers.map((player) => (
                <TableRow key={player.id}>
                  <TableCell className="font-medium">{player.username}</TableCell>
                  <TableCell>
                    <Badge variant={player.status === "online" ? "default" : "secondary"}>{player.status}</Badge>
                  </TableCell>
                  <TableCell className="hidden md:table-cell">{player.joinedAt}</TableCell>
                  <TableCell className="hidden md:table-cell">{player.ip}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button variant="ghost" size="icon" disabled={player.status !== "online"}>
                        <MessageSquare className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        disabled={player.status !== "online"}
                        onClick={() => kickPlayer(player.id)}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => banPlayer(player.id)}>
                        <Ban className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={5} className="text-center">
                  No players found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}
