# MinecraftOS Installation: Step-by-Step Guide

This guide describes **every** step and **every** prompt you'll encounter during the MinecraftOS installation process.

## Preparation

1. Start with a fresh Linux installation (Debian/Ubuntu recommended)
2. Make sure you have root access
3. Ensure you have an internet connection

## Step 1: Download the setup script

Open a terminal and execute the following commands:

\`\`\`bash
wget https://raw.githubusercontent.com/minecraft-os/installer/main/setup-os.sh
chmod +x setup-os.sh
\`\`\`

## Step 2: Run the setup script

\`\`\`bash
sudo ./setup-os.sh
\`\`\`

## Step 3: Follow ALL prompts

### Setting the hostname

You'll see:
\`\`\`
Enter hostname [minecraft-server]:
\`\`\`

What to do:
- **Option 1:** Simply press **Enter** to use the default name "minecraft-server"
- **Option 2:** Type a custom name like "my-minecraft" and press **Enter**

### Network Configuration

You'll see:
\`\`\`
Network Configuration
1) DHCP (automatic)
2) Static IP
Select option [1]:
\`\`\`

What to do:
- **Option 1:** Simply press **Enter** to use DHCP (recommended)
- **Option 2:** Type "2" and press **Enter** for a static IP address

### If you choose option 2 (Static IP):

#### IP address

You'll see:
\`\`\`
Enter IP address:
\`\`\`

What to do:
- Type your desired IP address (e.g., "192.168.1.100") and press **Enter**

#### Subnet mask

You'll see:
\`\`\`
Enter subnet mask [255.255.255.0]:
\`\`\`

What to do:
- Press **Enter** to use the default subnet mask
- OR type a custom subnet mask and press **Enter**

#### Gateway

You'll see:
\`\`\`
Enter gateway:
\`\`\`

What to do:
- Type the IP address of your router/gateway (e.g., "192.168.1.1") and press **Enter**

#### DNS server

You'll see:
\`\`\`
Enter DNS server [8.8.8.8]:
\`\`\`

What to do:
- Press **Enter** to use the default Google DNS
- OR type a custom DNS server and press **Enter**

## Step 4: Wait for package installation

You'll see messages about installing packages. **No action required.**

\`\`\`
Installing base packages...
\`\`\`

## Step 5: Firewall configuration

You'll see messages about configuring the firewall. **No action required.**

\`\`\`
Configuring firewall...
\`\`\`

## Step 6: Automatic updates

You'll see messages about configuring automatic updates. **No action required.**

\`\`\`
Configuring automatic updates...
\`\`\`

## Step 7: MinecraftOS installation

The script downloads and installs MinecraftOS. **No action required.**

\`\`\`
Running the main installation script...
\`\`\`

### Possible npm warnings

You might see warnings like:

\`\`\`
npm WARN deprecated [package]: [message]
\`\`\`

**No action required.** These warnings are normal and do not affect the installation.

### Possible npm audit warnings

You might see warnings like:

\`\`\`
X packages are looking for funding
run `npm fund` for details

Y [severity] vulnerabilities
To address all issues, run:
  npm audit fix --force
\`\`\`

**No action required.** These warnings are normal and do not affect the installation.

### Build errors

If you see build errors like:

\`\`\`
Build error occurred
Error: > Couldn't find any `pages` or `app` directory. Please create one under the project root
\`\`\`

**No action required.** The installation script will handle these issues automatically.

## Step 8: Installation completed

You'll see:

\`\`\`
MinecraftOS Setup Complete!
System will now reboot in 10 seconds...
After reboot, access the web interface at http://[hostname]
\`\`\`

**No action required.** The system will automatically restart.

## Step 9: After rebooting

Wait for the system to reboot. This takes approximately 1-2 minutes.

## Step 10: Accessing the web interface

Open a web browser on another device on the same network and go to:

\`\`\`
http://[hostname]:8080
\`\`\`

OR

\`\`\`
http://[IP-address]:8080
\`\`\`

For example:
- http://minecraft-server:8080
- http://192.168.1.100:8080

## Step 11: First-time login

When you first visit the web interface:

1. You'll be greeted with a setup wizard
2. Follow the on-screen instructions to:
   - Create an admin account
   - Configure the Minecraft server
   - Adjust server settings

## Troubleshooting

### If you don't know the IP address:

Log in to the system and run:

\`\`\`bash
ip addr
\`\`\`

Look for the IP address next to "inet" in the eth0 or enp0s3 section.

### If the web interface isn't accessible:

Check if the services are running:

\`\`\`bash
sudo systemctl status minecraftos-web
sudo systemctl status minecraftos-server
\`\`\`

Restart them if needed:

\`\`\`bash
sudo systemctl restart minecraftos-web
sudo systemctl restart minecraftos-server
\`\`\`

### If the firewall is causing issues:

Check the firewall status:

\`\`\`bash
sudo ufw status
\`\`\`

Make sure port 8080 is open:

\`\`\`bash
sudo ufw allow 8080/tcp
\`\`\`

## Important paths

- Web interface: `/opt/minecraft/web`
- Minecraft servers: `/opt/minecraft/servers`
- Configuration: `/opt/minecraft/config`
- Logs: `/opt/minecraft/logs`
