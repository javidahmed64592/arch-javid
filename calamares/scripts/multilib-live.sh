#!/usr/bin/env bash
set -euo pipefail

# Enable the multilib repository on the LIVE ISO host system.
# This is required before running pacstrap so that lib32-* packages resolve correctly.
sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
pacman -Sy --noconfirm
