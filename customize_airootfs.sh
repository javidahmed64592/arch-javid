#!/usr/bin/env bash
set -euo pipefail

# Create liveuser with sudo privileges for live desktop environment
# This script runs during the ISO build process (chrooted into airootfs)

# Create the liveuser
useradd -m -G wheel,audio,video,storage,optical,power -s /bin/bash liveuser

# Set a simple password for liveuser
echo "liveuser:liveuser" | chpasswd

# Enable sudo for wheel group (no password required in live environment)
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Enable NetworkManager service
systemctl enable NetworkManager.service

# Enable plasmalogin (SDDM) service for graphical login
systemctl enable plasmalogin.service

# Set up autologin for liveuser
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << 'EOF'
[Autologin]
User=liveuser
Session=plasma

[General]
DisplayServer=wayland
EOF

# Ensure proper ownership
chown -R liveuser:liveuser /home/liveuser

# Create a desktop entry for the installer (optional - can be run manually)
mkdir -p /home/liveuser/Desktop
cat > /home/liveuser/Desktop/arch-installer.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Arch Installer
Comment=Install Arch Linux to disk
Icon=system-software-install
Exec=konsole -e sudo /root/scripts/arch-install.sh
Terminal=false
Categories=System;
EOF

chmod +x /home/liveuser/Desktop/arch-installer.desktop
chown liveuser:liveuser /home/liveuser/Desktop/arch-installer.desktop
