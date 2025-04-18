#!/bin/bash
# Minecraft Server Creation Script
# This script downloads and sets up a Minecraft server

SERVER_PATH=$1
SERVER_TYPE=$2
MC_VERSION=$3
SERVER_PORT=$4
MEMORY=$5

echo "Creating $SERVER_TYPE server version $MC_VERSION in $SERVER_PATH"

# Create directory structure
mkdir -p "$SERVER_PATH"
cd "$SERVER_PATH"

# Download server jar based on type
if [ "$SERVER_TYPE" = "paper" ]; then
  # Download Paper
  echo "Downloading Paper $MC_VERSION..."
  wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/latest/downloads/paper-$MC_VERSION-latest.jar"
elif [ "$SERVER_TYPE" = "spigot" ]; then
  # Download Spigot
  echo "Downloading Spigot $MC_VERSION..."
  wget -O server.jar "https://download.getbukkit.org/spigot/spigot-$MC_VERSION.jar"
elif [ "$SERVER_TYPE" = "forge" ]; then
  # Download Forge (simplified)
  echo "Downloading Forge $MC_VERSION..."
  wget -O server.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/$MC_VERSION-latest/forge-$MC_VERSION-latest-installer.jar"
elif [ "$SERVER_TYPE" = "fabric" ]; then
  # Download Fabric
  echo "Downloading Fabric $MC_VERSION..."
  wget -O server.jar "https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/0.14.21/0.11.2/server/jar"
else
  # Download Vanilla
  echo "Downloading Vanilla $MC_VERSION..."
  wget -O server.jar "https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar"
fi

# Create server.properties
cat > server.properties << EOL
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
motd=A Minecraft Server
query.port=$SERVER_PORT
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
server-port=$SERVER_PORT
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
function-permission-level=2
level-type=minecraft\:normal
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
max-world-size=29999984
EOL

# Create eula.txt
echo "eula=true" > eula.txt

# Create start script
cat > start.sh << EOL
#!/bin/bash
java -Xms${MEMORY}M -Xmx${MEMORY}M -jar server.jar nogui
EOL

chmod +x start.sh

# Create systemd service file
SERVICE_NAME=$(basename "$SERVER_PATH" | tr '.' '-')
cat > /etc/systemd/system/minecraft-$SERVICE_NAME.service << EOL
[Unit]
Description=Minecraft Server - $(basename "$SERVER_PATH")
After=network.target

[Service]
WorkingDirectory=$SERVER_PATH
User=root
Group=root
Restart=always
ExecStart=$SERVER_PATH/start.sh

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd
systemctl daemon-reload
systemctl enable minecraft-$SERVICE_NAME.service

echo "Server setup complete!"
