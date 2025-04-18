#!/bin/bash
# Start a Minecraft server

SERVER_ID=$1

if [ -z "$SERVER_ID" ]; then
  echo "Usage: $0 <server-id>"
  exit 1
fi

systemctl start minecraft-$SERVER_ID
