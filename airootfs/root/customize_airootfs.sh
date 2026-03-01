#!/usr/bin/env bash
# Run by mkarchiso inside the airootfs chroot during ISO build.

set -euo pipefail

# ── 1. Create the live user ──────────────────────────────────────────────────
useradd -m -s /bin/bash liveuser

# Unlock the account with no password so SDDM autologin works
passwd -d liveuser

# Add to groups needed for a functional desktop live session
usermod -aG wheel,video,audio,network,storage,optical,power liveuser

# ── 2. Calamares autostart in KDE ────────────────────────────────────────────
mkdir -p /home/liveuser/.config/autostart

cat > /home/liveuser/.config/autostart/calamares.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Install Arch Linux
Comment=Launch the graphical Arch Linux installer
Exec=sudo calamares
Icon=calamares
Terminal=false
Categories=System;
X-KDE-autostart-phase=2
EOF

# ── 3. Set KDE/Wayland as the preferred session env ──────────────────────────
mkdir -p /home/liveuser/.config
cat > /home/liveuser/.config/kwinrc << 'EOF'
[Windows]
Placement=Smart
EOF

# ── 4. Fix ownership ─────────────────────────────────────────────────────────
chown -R liveuser:liveuser /home/liveuser
