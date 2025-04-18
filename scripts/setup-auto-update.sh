#!/bin/bash

# Script om de auto-update functionaliteit te installeren

# Zorg ervoor dat de scripts map bestaat
mkdir -p /opt/minecraft/scripts

# Kopieer de auto-update scripts
cp /opt/minecraft/web/scripts/auto-update.sh /opt/minecraft/scripts/
cp /opt/minecraft/web/scripts/install-auto-update.sh /opt/minecraft/scripts/

# Maak ze uitvoerbaar
chmod +x /opt/minecraft/scripts/auto-update.sh
chmod +x /opt/minecraft/scripts/install-auto-update.sh

# Voer het installatie script uit
/opt/minecraft/scripts/install-auto-update.sh

echo "Auto-update functionaliteit is geïnstalleerd en geconfigureerd"
echo "Het systeem zal nu elke 6 uur controleren op updates van de GitHub repository"
