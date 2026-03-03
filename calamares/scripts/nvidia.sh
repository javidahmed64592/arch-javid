#!/usr/bin/env bash
set -euo pipefail

ROOT_MOUNT="/tmp/calamares-root"

# Copy the canonical nvidia.sh (preserved from the original installer) into the chroot,
# execute it, then clean up.
cp /root/scripts/chroot/nvidia.sh "$ROOT_MOUNT/tmp/nvidia.sh"
chmod +x "$ROOT_MOUNT/tmp/nvidia.sh"
arch-chroot "$ROOT_MOUNT" /tmp/nvidia.sh
rm -f "$ROOT_MOUNT/tmp/nvidia.sh"
