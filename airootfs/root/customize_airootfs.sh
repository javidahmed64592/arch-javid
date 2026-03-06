#!/usr/bin/env bash
set -euo pipefail

# Create live user
useradd -m -s /bin/bash liveuser
passwd -d liveuser
usermod -aG wheel,video,audio,network,storage,optical,power liveuser

# Enable services for live environment
systemctl enable NetworkManager
systemctl enable sddm

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
