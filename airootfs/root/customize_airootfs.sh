#!/usr/bin/env bash
set -euo pipefail

# Create live user
useradd -m -s /bin/bash liveuser
passwd -d liveuser
usermod -aG wheel,video,audio,network,storage,optical,power liveuser

# Enable services for live environment
systemctl enable NetworkManager
systemctl enable sddm
