#!/bin/bash
# Backup a Minecraft server

SERVER_ID=$1
BACKUP_PATH=${2:-/opt/minecraft/backups}

if [ -z "$SERVER_ID" ]; then
  echo "Usage: $0 <server-id> [backup-path]"
  exit 1
fi

SERVER_PATH="/opt/minecraft/servers/$SERVER_ID"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_PATH/${SERVER_ID}_${TIMESTAMP}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_PATH"

# Check if server exists
if [ ! -d "$SERVER_PATH" ]; then
  echo "Server $SERVER_ID not found"
  exit 1
fi

# Create backup
echo "Creating backup of server $SERVER_ID to $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C "$SERVER_PATH" .

echo "Backup complete: $BACKUP_FILE"
