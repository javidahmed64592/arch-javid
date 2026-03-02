#!/bin/bash
set -euo pipefail

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Root directories
SYSTEM_SCRIPT_DIR="/root/scripts/system"
CHROOT_SCRIPT_DIR="/root/scripts/chroot"

# Variables
EFI_SIZE=
SWAP_SIZE=

LOCAL_ZONE=""
LOCALE=""
KEYMAP=""

HOSTNAME=""
USERNAME=""
PASSWORD=""

# ==== 1. Partition Disk ====
DISK=$(lsblk -dpno NAME,TYPE | awk '$2=="disk" {print $1; exit}')
echo -e "Detected disk: ${BLUE}${DISK}${NC}"

if lsblk -dpno NAME,TYPE | grep -q "${DISK}part"; then
  echo -e "${YELLOW}Disk already has partitions. Skipping partitioning.${NC}"
else
  echo -e "Partitioning disk with EFI size ${BLUE}${EFI_SIZE} MiB${NC} and swap size ${BLUE}${SWAP_SIZE} MiB${NC}..."
  "${SYSTEM_SCRIPT_DIR}/partition.sh" --disk ${DISK} --efi-size ${EFI_SIZE} --swap-size ${SWAP_SIZE}
fi

# ==== 2. Make filesystems ====
EFI_PART="${DISK}1"
SWAP_PART="${DISK}2"
ROOT_PART="${DISK}3"

echo -e "Creating filesystems on ${BLUE}${EFI_PART}${NC}, ${BLUE}${SWAP_PART}${NC}, and ${BLUE}${ROOT_PART}${NC}..."
"${SYSTEM_SCRIPT_DIR}/makefs.sh" --efi-part ${EFI_PART} --swap-part ${SWAP_PART} --root-part ${ROOT_PART}

# ==== 3. Mount Partitions ====
echo -e "Mounting ${BLUE}${ROOT_PART}${NC} to ${BLUE}/mnt${NC} and ${BLUE}${EFI_PART}${NC} to ${BLUE}/mnt/boot${NC}..."
"${SYSTEM_SCRIPT_DIR}/mount.sh" --efi-part ${EFI_PART} --root-part ${ROOT_PART}

# ==== 4. Install base system ====
echo -e "Installing base system with packages from ${BLUE}packages.txt${NC}..."
PACKAGES=$(grep -v '^\s*#' /root/packages.txt | grep -v '^\s*$' | tr '\n' ' ')
pacstrap /mnt $PACKAGES

# ==== 5. Generate fstab ====
echo -e "Generating ${BLUE}/etc/fstab${NC}..."
"${SYSTEM_SCRIPT_DIR}/fstab.sh"

# ==== 6. Chroot and configure ====
echo -e "Copying chroot scripts to ${BLUE}/mnt${CHROOT_SCRIPT_DIR}${NC}..."
mkdir -p /mnt${CHROOT_SCRIPT_DIR}
cp "${CHROOT_SCRIPT_DIR}/"*.sh /mnt${CHROOT_SCRIPT_DIR}/
chmod +x /mnt${CHROOT_SCRIPT_DIR}/*.sh

echo -e "Configuring system inside chroot..."
arch-chroot /mnt /bin/bash <<EOF
echo ${HOSTNAME} > /etc/hostname
${CHROOT_SCRIPT_DIR}/timezone.sh --local-zone ${LOCAL_ZONE}
${CHROOT_SCRIPT_DIR}/locale.sh --locale ${LOCALE} --keymap ${KEYMAP}
${CHROOT_SCRIPT_DIR}/services.sh
${CHROOT_SCRIPT_DIR}/users.sh --username ${USERNAME} --password ${PASSWORD}
${CHROOT_SCRIPT_DIR}/bootloader.sh --root-part ${ROOT_PART}
EOF

# ==== 7. Cleanup ====
echo "Installation complete! Unmounting partitions..."
"${SYSTEM_SCRIPT_DIR}/unmount.sh" --swap-part ${SWAP_PART}
