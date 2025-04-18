#!/bin/bash
# Stop a Minecraft server

SERVER_ID=$1

if [ -z "$SERVER_ID" ]; then
  echo "Usage: $0 <server-id>"
  exit 1
fi

systemctl stop minecraft-$SERVER_ID
