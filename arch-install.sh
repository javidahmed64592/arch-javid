#!/bin/bash
set -euo pipefail

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
parted $DISK --script mklabel gpt

EFI_PART="${DISK}1"
SWAP_PART="${DISK}2"
ROOT_PART="${DISK}3"

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

# ==== 2. Make filesystems ====
mkfs.fat -F32 $EFI_PART
mkswap $SWAP_PART
swapon $SWAP_PART
mkfs.ext4 $ROOT_PART

# ==== 3. Mount Partitions ====
mount $ROOT_PART /mnt
mkdir /mnt/boot
mount $EFI_PART /mnt/boot

# ==== 4. Install base system ====
pacstrap /mnt base linux linux-firmware sudo nano intel-ucode networkmanager

# ==== 5. Generate fstab ====
genfstab -U /mnt >> /mnt/etc/fstab

# ==== 6. Chroot and configure ====
arch-chroot /mnt /bin/bash <<EOF
# Set time
ln -sf /usr/share/zoneinfo/${LOCAL_ZONE} /etc/localtime
hwclock --systohc

# Localization
sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Network configuration
echo ${HOSTNAME} > /etc/hostname
systemctl enable NetworkManager

# Initramfs
mkinitcpio -P linux

# Set root password
echo "root:${PASSWORD}" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd

# Enable sudo for wheel group
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install systemd-boot
mkdir -p /boot/loader/entries
ROOT_UUID=\$(blkid -s UUID -o value $ROOT_PART)
cat <<EOL > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=\$ROOT_UUID rw
EOL

echo "default arch.conf" > /boot/loader/loader.conf
sed -i "s/^#timeout 3/timeout 3/" /boot/loader/loader.conf
sed -i "s/^#editor no/editor no/" /boot/loader/loader.conf
sed -i "s/^#console-mode keep/console-mode keep/" /boot/loader/loader.conf

bootctl install
EOF

# ==== 7. Cleanup ====
swapoff $SWAP_PART
umount -R /mnt
