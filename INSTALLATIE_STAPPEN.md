# MinecraftOS Installatie: Stap-voor-Stap Handleiding

Deze handleiding beschrijft **elke** stap en **elke** prompt die je tegenkomt tijdens het installeren van MinecraftOS.

## Voorbereiding

1. Start met een verse Linux-installatie (Debian/Ubuntu aanbevolen)
2. Zorg dat je root-toegang hebt
3. Zorg voor een internetverbinding

## Stap 1: Download het setup script

Open een terminal en voer de volgende commando's uit:

\`\`\`bash
wget https://raw.githubusercontent.com/minecraft-os/installer/main/setup-os.sh
chmod +x setup-os.sh
\`\`\`

## Stap 2: Voer het setup script uit

\`\`\`bash
sudo ./setup-os.sh
\`\`\`

## Stap 3: Volg ALLE prompts

### Hostname instellen

Je ziet:
\`\`\`
Enter hostname [minecraft-server]:
\`\`\`

Wat je moet doen:
- **Optie 1:** Druk gewoon op **Enter** om de standaardnaam "minecraft-server" te gebruiken
- **Optie 2:** Typ een aangepaste naam zoals "mijn-minecraft" en druk op **Enter**

### Netwerkconfiguratie

Je ziet:
\`\`\`
Network Configuration
1) DHCP (automatic)
2) Static IP
Select option [1]:
\`\`\`

Wat je moet doen:
- **Optie 1:** Druk gewoon op **Enter** om DHCP te gebruiken (aanbevolen)
- **Optie 2:** Typ "2" en druk op **Enter** voor een statisch IP-adres

### Als je optie 2 (Statisch IP) kiest:

#### IP-adres

Je ziet:
\`\`\`
Enter IP address:
\`\`\`

Wat je moet doen:
- Typ het gewenste IP-adres (bijv. "192.168.1.100") en druk op **Enter**

#### Subnetmasker

Je ziet:
\`\`\`
Enter subnet mask [255.255.255.0]:
\`\`\`

Wat je moet doen:
- Druk op **Enter** om het standaard subnetmasker te gebruiken
- OF typ een aangepast subnetmasker en druk op **Enter**

#### Gateway

Je ziet:
\`\`\`
Enter gateway:
\`\`\`

Wat je moet doen:
- Typ het IP-adres van je router/gateway (bijv. "192.168.1.1") en druk op **Enter**

#### DNS-server

Je ziet:
\`\`\`
Enter DNS server [8.8.8.8]:
\`\`\`

Wat je moet doen:
- Druk op **Enter** om de standaard Google DNS te gebruiken
- OF typ een aangepaste DNS-server en druk op **Enter**

## Stap 4: Wacht op pakketinstallatie

Je ziet berichten over het installeren van pakketten. **Geen actie vereist.**

\`\`\`
Installing base packages...
\`\`\`

## Stap 5: Firewall configuratie

Je ziet berichten over het configureren van de firewall. **Geen actie vereist.**

\`\`\`
Configuring firewall...
\`\`\`

## Stap 6: Automatische updates

Je ziet berichten over het configureren van automatische updates. **Geen actie vereist.**

\`\`\`
Configuring automatic updates...
\`\`\`

## Stap 7: MinecraftOS installatie

Het script downloadt en installeert MinecraftOS. **Geen actie vereist.**

\`\`\`
Running the main installation script...
\`\`\`

### Mogelijke npm waarschuwingen

Je kunt waarschuwingen zien zoals:

\`\`\`
npm WARN deprecated [package]: [message]
\`\`\`

**Geen actie vereist.** Deze waarschuwingen zijn normaal en beïnvloeden de installatie niet.

### Mogelijke npm audit waarschuwingen

Je kunt waarschuwingen zien zoals:

\`\`\`
X packages are looking for funding
run `npm fund` for details

Y [severity] vulnerabilities
To address all issues, run:
  npm audit fix --force
\`\`\`

**Geen actie vereist.** Deze waarschuwingen zijn normaal en beïnvloeden de installatie niet.

## Stap 8: Installatie voltooid

Je ziet:

\`\`\`
MinecraftOS Setup Complete!
System will now reboot in 10 seconds...
After reboot, access the web interface at http://[hostname]
\`\`\`

**Geen actie vereist.** Het systeem zal automatisch herstarten.

## Stap 9: Na het herstarten

Wacht tot het systeem opnieuw is opgestart. Dit duurt ongeveer 1-2 minuten.

## Stap 10: Toegang tot de webinterface

Open een webbrowser op een ander apparaat in hetzelfde netwerk en ga naar:

\`\`\`
http://[hostname]:8080
\`\`\`

OF

\`\`\`
http://[IP-adres]:8080
\`\`\`

Bijvoorbeeld:
- http://minecraft-server:8080
- http://192.168.1.100:8080

## Stap 11: Eerste keer inloggen

Bij het eerste bezoek aan de webinterface:

1. Je wordt begroet met een setup wizard
2. Volg de instructies op het scherm om:
   - Een admin-account aan te maken
   - De Minecraft server te configureren
   - Serverinstellingen aan te passen

## Problemen oplossen

### Als je het IP-adres niet weet:

Log in op het systeem en voer uit:

\`\`\`bash
ip addr
\`\`\`

Zoek naar het IP-adres naast "inet" in de eth0 of enp0s3 sectie.

### Als de webinterface niet bereikbaar is:

Controleer of de services draaien:

\`\`\`bash
sudo systemctl status minecraftos-web
sudo systemctl status minecraftos-server
\`\`\`

Start ze indien nodig opnieuw:

\`\`\`bash
sudo systemctl restart minecraftos-web
sudo systemctl restart minecraftos-server
\`\`\`

### Als de firewall problemen veroorzaakt:

Controleer de firewall-status:

\`\`\`bash
sudo ufw status
\`\`\`

Zorg ervoor dat poort 8080 open is:

\`\`\`bash
sudo ufw allow 8080/tcp
\`\`\`

## Belangrijke paden

- Webinterface: `/opt/minecraft/web`
- Minecraft servers: `/opt/minecraft/servers`
- Configuratie: `/opt/minecraft/config`
- Logs: `/opt/minecraft/logs`
