#!/bin/bash
set -euo pipefail

# Enable services and rebuild initramfs
systemctl enable NetworkManager
systemctl enable plasmalogin
mkinitcpio -P linux
