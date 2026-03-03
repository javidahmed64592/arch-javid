#!/usr/bin/env bash
set -euo pipefail

# Create live user (no password, wheel group for passwordless sudo)
useradd -m -G wheel,users -s /bin/bash liveuser
passwd -d liveuser

# Passwordless sudo for the live session
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-nopasswd
chmod 440 /etc/sudoers.d/wheel-nopasswd

# Enable SDDM for graphical autologin
systemctl enable sddm
