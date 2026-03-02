#!/bin/bash
set -euo pipefail

# Variables
SWAP_PART=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --swap-part) SWAP_PART="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$SWAP_PART" ]]; then
  echo "Usage: $0 --swap-part <swap partition>"
  exit 1
fi

# Unmount partitions
swapoff $SWAP_PART
umount -R /mnt
