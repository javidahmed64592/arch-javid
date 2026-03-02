#!/bin/bash
set -euo pipefail

# Variables
USERNAME=
PASSWORD=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --username) USERNAME="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
  echo "Usage: $0 --username <username> --password <password>"
  exit 1
fi

# Set root password
echo "root:${PASSWORD}" | chpasswd

# Create user and add to wheel group
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd

# Enable sudo for wheel group
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
