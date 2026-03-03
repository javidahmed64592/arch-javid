#!/usr/bin/env bash
set -euo pipefail

ROOT_MOUNT="/tmp/calamares-root"

# Rebuild the initramfs in the installed chroot.
# This must run after nvidia.sh has added NVIDIA modules to /etc/mkinitcpio.conf,
# and before the bootloader module creates the boot entry referencing the initramfs.
arch-chroot "$ROOT_MOUNT" mkinitcpio -P linux
