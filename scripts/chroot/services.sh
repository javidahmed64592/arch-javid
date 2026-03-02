#!/bin/bash
set -euo pipefail

# Enable display manager and rebuild initramfs
systemctl enable plasmalogin
mkinitcpio -P linux
