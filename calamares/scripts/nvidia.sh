#!/usr/bin/env bash
set -euo pipefail

ROOT_MOUNT="${1:?ERROR: root mount point not provided}"

# Configure NVIDIA DRM modesetting + fbdev for Wayland/KDE (required on Linux 6.11+)
echo "Configuring NVIDIA modeset..."
mkdir -p "$ROOT_MOUNT/etc/modprobe.d"
echo "options nvidia_drm modeset=1 fbdev=1" > "$ROOT_MOUNT/etc/modprobe.d/nvidia.conf"

# Preserve video memory across suspend/resume (required for Wayland suspend support)
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" > "$ROOT_MOUNT/etc/modprobe.d/nvidia-power.conf"

# Add NVIDIA modules to mkinitcpio for early loading
echo "Adding NVIDIA drivers to mkinitcpio..."
sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$ROOT_MOUNT/etc/mkinitcpio.conf"
