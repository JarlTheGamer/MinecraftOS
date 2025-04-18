#!/bin/bash

# This script installs MinecraftOS and its dependencies.

# Update package lists
echo "Updating package lists..."
apt update

# Install required packages
echo "Installing required packages..."
apt install -y git screen unzip openjdk-17-jre-headless

# Create Minecraft directory
echo "Creating Minecraft directory..."
mkdir -p /opt/minecraft

# Download and install Paperclip (Paper fork)
echo "Downloading and installing Paperclip..."
cd /opt/minecraft
wget -q https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/809/downloads/paper-1.20.4-809.jar -O paper.jar

# Create server.properties file
echo "Creating server.properties file..."
cat > server.properties << EOF
#Minecraft server properties
#Generated $(date)
enable-jmx-monitoring=false
rcon.port=25575
level-seed=
gamemode=survival
enable-command-block=false
enable-query=false
generator-settings={}
enforce-secure-profile=true
level-name=world
motd=A MinecraftOS Server
query.port=25565
pvp=true
generate-structures=true
max-chained-neighbor-updates=1000000
difficulty=easy
network-compression-threshold=256
max-tick-time=60000
require-resource-pack=false
use-native-transport=true
max-players=20
online-mode=true
enable-status=true
allow-flight=false
broadcast-rcon-to-ops=true
view-distance=10
server-ip=
resource-pack-prompt=
allow-nether=true
server-port=25565
enable-rcon=false
sync-chunk-writes=true
op-permission-level=4
prevent-proxy-connections=false
hide-online-players=false
resource-pack=
entity-broadcast-range-percentage=100
simulation-distance=10
rcon.password=
player-idle-timeout=0
force-gamemode=false
rate-limit=0
hardcore=false
white-list=false
broadcast-console-to-ops=true
spawn-npcs=true
spawn-animals=true
snooper-enabled=true
resource-pack-sha1=
level-type=default
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
max-world-size=29999984
EOF

# Create eula.txt file
echo "Creating eula.txt file..."
echo "eula=true" > eula.txt

# Create start.sh script
echo "Creating start.sh script..."
cat > start.sh << EOF
#!/bin/bash
while true; do
  java -Xms2G -Xmx4G -jar paper.jar nogui
  echo "Server crashed. Restarting in 5 seconds..."
  sleep 5
done
EOF
chmod +x start.sh

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

# Install nodejs and npm
echo "Installing nodejs and npm..."
apt install -y nodejs npm

# Install web interface dependencies
echo "Installing web interface dependencies..."
cd /opt/minecraft/web
npm install

# Build web interface
echo "Building web interface..."
npm run build

# Create systemd service file
echo "Creating systemd service file..."
cat > /etc/systemd/system/minecraft.service << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=/opt/minecraft
User=root
Group=root
Restart=always
ExecStart=/opt/minecraft/start.sh

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Minecraft server
echo "Enabling and starting the Minecraft server..."
systemctl enable minecraft.service
systemctl start minecraft.service

echo "MinecraftOS installation complete!"
