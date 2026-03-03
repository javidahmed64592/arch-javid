#!/bin/bash
set -euo pipefail

# Configure NVIDIA DRM modesetting + fbdev for Wayland/KDE (required on Linux 6.11+)
echo "Configuring NVIDIA modeset..."
mkdir -p /etc/modprobe.d
echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf

# Preserve video memory across suspend/resume (required for Wayland suspend support)
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" > /etc/modprobe.d/nvidia-power.conf

# Add NVIDIA modules to dracut for early loading and omit nouveau
echo "Adding NVIDIA drivers to dracut..."
mkdir -p /etc/dracut.conf.d
echo 'add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "' > /etc/dracut.conf.d/nvidia.conf
echo 'omit_drivers+=" nouveau "' >> /etc/dracut.conf.d/nvidia.conf
dracut -f
