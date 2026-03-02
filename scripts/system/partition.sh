#!/bin/bash
set -euo pipefail

# Variables
DISK=
EFI_SIZE=
SWAP_SIZE=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)      DISK="$2";     shift 2 ;;
    --efi-size)  EFI_SIZE="$2"; shift 2 ;;
    --swap-size) SWAP_SIZE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$EFI_SIZE" || -z "$SWAP_SIZE" || -z "$DISK" ]]; then
  echo "Usage: $0 --disk <disk> --efi-size <MiB> --swap-size <MiB>"
  exit 1
fi

# Create GPT partition table and partitions
parted $DISK --script mklabel gpt

# Calculate partition start/end in MiB
EFI_START=1
EFI_END=$((EFI_START + EFI_SIZE))
SWAP_START=$EFI_END
SWAP_END=$((SWAP_START + SWAP_SIZE))
ROOT_START=$SWAP_END
ROOT_END=100%

# EFI system partition
parted $DISK --script mkpart primary fat32 ${EFI_START}MiB ${EFI_END}MiB
parted $DISK --script set 1 boot on

# Swap partition
parted $DISK --script mkpart primary linux-swap ${SWAP_START}MiB ${SWAP_END}MiB

# Root partition
parted $DISK --script mkpart primary ext4 ${ROOT_START}MiB ${ROOT_END}
