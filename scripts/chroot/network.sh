#!/bin/bash
set -euo pipefail

# Variables
HOSTNAME=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hostname) HOSTNAME="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$HOSTNAME" ]]; then
  echo "Usage: $0 --hostname <hostname>"
  exit 1
fi

# Configure hostname and enable network manager
echo ${HOSTNAME} > /etc/hostname
systemctl enable NetworkManager
