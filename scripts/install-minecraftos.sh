#!/bin/bash

# Set up MinecraftOS

# Update and install necessary packages
echo "Updating and installing necessary packages..."
apt update
apt install -y git nodejs npm screen

# Create Minecraft directory
echo "Creating Minecraft directory..."
mkdir -p /opt/minecraft

# Set up Minecraft server
echo "Setting up Minecraft server..."
cd /opt/minecraft
wget https://launcher.mojang.com/v1/objects/125e5adf40c7e8423cb80a72958253a2e48d3b11/server.jar -O server.jar
echo "eula=true" > eula.txt

# Clone the MinecraftOS web interface
echo "Setting up MinecraftOS web interface..."
cd /opt/minecraft/web
git clone https://github.com/JarlTheGamer/MinecraftOS.git . || {
  echo "GitHub repository not available, creating placeholder web interface"
  mkdir -p /opt/minecraft/web
  cat > /opt/minecraft/web/package.json << EOF
{
  "name": "minecraft-os",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^13.4.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOF
}

# Install web interface dependencies
echo "Installing web interface dependencies..."
npm install

# Start the Minecraft server in a screen session
echo "Starting the Minecraft server..."
screen -dmS minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui

echo "MinecraftOS setup complete!"
