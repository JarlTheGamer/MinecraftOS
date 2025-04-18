# MinecraftOS Installatie Handleiding

Deze handleiding beschrijft hoe je MinecraftOS kunt installeren en configureren op een Linux-systeem.

## Vereisten

- Een Linux-systeem (Debian/Ubuntu aanbevolen)
- Root-toegang
- Internetverbinding
- Minimaal 2GB RAM
- Minimaal 10GB vrije schijfruimte

## Installatie Stappen

### 1. Download het setup script

\`\`\`bash
wget https://raw.githubusercontent.com/minecraft-os/installer/main/setup-os.sh
chmod +x setup-os.sh
\`\`\`

### 2. Voer het setup script uit als root

\`\`\`bash
sudo ./setup-os.sh
\`\`\`

### 3. Volg de prompts

#### Hostname instellen
- Bij de prompt "Enter hostname [minecraft-server]:" kun je:
  - Direct op Enter drukken om de standaardnaam "minecraft-server" te gebruiken (aanbevolen)
  - OF een aangepaste hostnaam invoeren (bijv. "mijn-minecraft-server")

#### Netwerkconfiguratie
- Bij de prompt "Select option [1]:" kun je:
  - Optie 1: DHCP (automatisch) - Aanbevolen voor de meeste gebruikers
    - Druk gewoon op Enter om DHCP te gebruiken
  - Optie 2: Statisch IP - Voor geavanceerde gebruikers
    - Als je optie 2 kiest, moet je het volgende invoeren:
      - IP-adres (bijv. 192.168.1.100)
      - Subnetmasker (standaard is 255.255.255.0)
      - Gateway (bijv. 192.168.1.1)
      - DNS-server (standaard is 8.8.8.8)

### 4. Wacht tot de installatie is voltooid

Het script zal:
1. Basispakketten installeren
2. De firewall configureren
3. Automatische updates instellen
4. MinecraftOS installeren
5. De server herstarten

## Na de installatie

Na het herstarten kun je de MinecraftOS webinterface bereiken via:

\`\`\`
http://[jouw-hostnaam]:8080
\`\`\`

of

\`\`\`
http://[IP-adres]:8080
\`\`\`

### Standaard poorten

- Webinterface: 8080
- Minecraft server: 25565
- SSH: 22

## Problemen oplossen

### Webinterface niet bereikbaar

1. Controleer of de services actief zijn:
\`\`\`bash
sudo systemctl status minecraftos-web
sudo systemctl status minecraftos-server
\`\`\`

2. Controleer de firewall-instellingen:
\`\`\`bash
sudo ufw status
\`\`\`

3. Controleer de logs:
\`\`\`bash
sudo journalctl -u minecraftos-web
\`\`\`

### Server start niet op

1. Controleer de server logs:
\`\`\`bash
sudo journalctl -u minecraftos-server
\`\`\`

2. Controleer de server configuratie:
\`\`\`bash
cat /opt/minecraft/servers/default/server.properties
\`\`\`

### Handmatig herstarten

Om de services handmatig te herstarten:

\`\`\`bash
sudo systemctl restart minecraftos-web
sudo systemctl restart minecraftos-server
\`\`\`

## Automatische updates

MinecraftOS is geconfigureerd om automatisch systeemupdates te installeren. Je kunt de instellingen aanpassen in:

\`\`\`
/etc/apt/apt.conf.d/50unattended-upgrades
\`\`\`

## Bestanden en mappen

- Webinterface: `/opt/minecraft/web`
- Minecraft servers: `/opt/minecraft/servers`
- Downloads: `/opt/minecraft/downloads`
- Backups: `/opt/minecraft/backups`
- Configuratie: `/opt/minecraft/config`
- Logs: `/opt/minecraft/logs`

## Licentie

Dit project is gelicenseerd onder de MIT-licentie.
