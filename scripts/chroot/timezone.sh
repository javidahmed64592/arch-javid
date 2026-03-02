#!/bin/bash
set -euo pipefail

# Variables
LOCAL_ZONE=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --local-zone) LOCAL_ZONE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$LOCAL_ZONE" ]]; then
  echo "Usage: $0 --local-zone <zone>"
  exit 1
fi

# Set timezone and sync hardware clock
ln -sf /usr/share/zoneinfo/${LOCAL_ZONE} /etc/localtime
hwclock --systohc
