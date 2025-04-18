#!/bin/bash

# Installeer de auto-update service

# Maak het update script uitvoerbaar
chmod +x /opt/minecraft/scripts/auto-update.sh

# Maak de systemd service aan
cat > /etc/systemd/system/minecraft-auto-update.service << EOF
[Unit]
Description=MinecraftOS Auto Update Service
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/minecraft/scripts/auto-update.sh
User=root
Group=root
EOF

# Maak de systemd timer aan (controleert elke 6 uur)
cat > /etc/systemd/system/minecraft-auto-update.timer << EOF
[Unit]
Description=Run MinecraftOS Auto Update every 6 hours

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h
AccuracySec=5min

[Install]
WantedBy=timers.target
EOF

# Activeer en start de timer
systemctl daemon-reload
systemctl enable minecraft-auto-update.timer
systemctl start minecraft-auto-update.timer

echo "Auto-update service geïnstalleerd en geactiveerd"
