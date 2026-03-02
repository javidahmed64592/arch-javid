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
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw
EOL

# Configure loader
echo "default arch.conf" > /boot/loader/loader.conf
sed -i "s/^#timeout 3/timeout 3/" /boot/loader/loader.conf
sed -i "s/^#editor no/editor no/" /boot/loader/loader.conf
sed -i "s/^#console-mode keep/console-mode keep/" /boot/loader/loader.conf

bootctl install
