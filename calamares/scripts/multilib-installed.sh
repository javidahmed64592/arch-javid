#!/usr/bin/env bash
set -euo pipefail

ROOT_MOUNT="/tmp/calamares-root"

# Enable the multilib repository in the INSTALLED system's pacman.conf.
# pacstrap creates a fresh pacman.conf in the target that does not have multilib enabled.
sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' "$ROOT_MOUNT/etc/pacman.conf"
