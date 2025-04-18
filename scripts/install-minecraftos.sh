#!/bin/bash

# MinecraftOS Installation Script
# This script installs and configures the MinecraftOS system

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Installation"
echo "====================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get install -y curl wget git unzip zip openjdk-17-jre-headless nginx nodejs npm ufw screen

# Create directory structure
echo "Creating directory structure..."
MINECRAFT_DIR="/opt/minecraft"
WEB_DIR="${MINECRAFT_DIR}/web"
SERVERS_DIR="${MINECRAFT_DIR}/servers"
DOWNLOADS_DIR="${MINECRAFT_DIR}/downloads"
BACKUPS_DIR="${MINECRAFT_DIR}/backups"
CONFIG_DIR="${MINECRAFT_DIR}/config"
LOGS_DIR="${MINECRAFT_DIR}/logs"
SCRIPTS_DIR="${MINECRAFT_DIR}/scripts"

mkdir -p ${MINECRAFT_DIR}
mkdir -p ${WEB_DIR}
mkdir -p ${SERVERS_DIR}
mkdir -p ${DOWNLOADS_DIR}
mkdir -p ${BACKUPS_DIR}
mkdir -p ${CONFIG_DIR}
mkdir -p ${LOGS_DIR}
mkdir -p ${SCRIPTS_DIR}

# Download web interface setup script
echo "Downloading web interface setup script..."
curl -o ${SCRIPTS_DIR}/web-interface-setup.sh https://raw.githubusercontent.com/minecraft-os/minecraftos/main/scripts/web-interface-setup.sh
chmod +x ${SCRIPTS_DIR}/web-interface-setup.sh

# Run web interface setup
echo "Running web interface setup..."
${SCRIPTS_DIR}/web-interface-setup.sh

# Start the Minecraft server in a screen session
echo "Starting the Minecraft server..."
cd ${MINECRAFT_DIR}
screen -dmS minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui

echo "====================================="
echo "MinecraftOS Installation Complete"
echo "====================================="
echo "You can now access the web interface at http://localhost:8080"
echo "====================================="
