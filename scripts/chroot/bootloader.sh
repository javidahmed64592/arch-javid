#!/bin/bash
set -euo pipefail

# Variables
ROOT_PART=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root-part) ROOT_PART="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$ROOT_PART" ]]; then
  echo "Usage: $0 --root-part <root partition>"
  exit 1
fi

# Create bootloader entry
mkdir -p /boot/loader/entries
ROOT_UUID=$(blkid -s UUID -o value ${ROOT_PART})
cat <<EOL > /boot/loader/entries/arch.conf
title   Arch Javid
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw nvidia-drm.modeset=1 nvidia_drm.fbdev=1 quiet splash
EOL

# Configure loader
cat <<EOL > /boot/loader/loader.conf
default arch.conf
timeout 3
editor no
console-mode keep
EOL

bootctl install
