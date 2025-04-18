#!/bin/bash

# MinecraftOS Setup Script
# This script configures a minimal Linux installation to become MinecraftOS

# Exit on error
set -e

echo "====================================="
echo "MinecraftOS Setup"
echo "====================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Set hostname
read -p "Enter hostname [minecraft-server]: " HOSTNAME
HOSTNAME=${HOSTNAME:-minecraft-server}
hostnamectl set-hostname $HOSTNAME

# Configure network
echo "Network Configuration"
echo "1) DHCP (automatic)"
echo "2) Static IP"
read -p "Select option [1]: " NETWORK_OPTION
NETWORK_OPTION=${NETWORK_OPTION:-1}

if [ "$NETWORK_OPTION" = "2" ]; then
  read -p "Enter IP address: " IP_ADDRESS
  read -p "Enter subnet mask [255.255.255.0]: " SUBNET_MASK
  SUBNET_MASK=${SUBNET_MASK:-255.255.255.0}
  read -p "Enter gateway: " GATEWAY
  read -p "Enter DNS server [8.8.8.8]: " DNS
  DNS=${DNS:-8.8.8.8}
  
  # Configure network with static IP
  cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address $IP_ADDRESS
  netmask $SUBNET_MASK
  gateway $GATEWAY
  dns-nameservers $DNS
EOF
  
  # Restart networking
  systemctl restart networking
fi

# Install base packages
echo "Installing base packages..."
apt-get update
apt-get install -y curl wget git unzip zip openjdk-17-jre-headless nginx nodejs npm ufw

# Configure firewall
echo "Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 25565/tcp # Minecraft default port
ufw allow 8192/tcp # Remote access port
ufw --force enable

# Set up automatic updates
echo "Configuring automatic updates..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
  "\${distro_id}:\${distro_codename}";
  "\${distro_id}:\${distro_codename}-security";
  "\${distro_id}:\${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Run the main installation script
curl -s https://raw.githubusercontent.com/minecraft-os/installer/main/install.sh | bash

echo "====================================="
echo "MinecraftOS Setup Complete!"
echo "====================================="
echo "System will now reboot in 10 seconds..."
echo "After reboot, access the web interface at http://$HOSTNAME"
echo "====================================="

# Schedule a reboot
(sleep 10 && reboot) &
