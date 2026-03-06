#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="arch-javid"
iso_label="ARCH_JAVID_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Javid <https://github.com/javid>"
iso_application="Arch Linux Live/Rescue CD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/root/scripts"]="0:0:755"
  ["/root/scripts/arch-install.sh"]="0:0:755"
  ["/root/scripts/system"]="0:0:755"
  ["/root/scripts/system/partition.sh"]="0:0:755"
  ["/root/scripts/system/makefs.sh"]="0:0:755"
  ["/root/scripts/system/mount.sh"]="0:0:755"
  ["/root/scripts/system/unmount.sh"]="0:0:755"
  ["/root/scripts/system/fstab.sh"]="0:0:755"
  ["/root/scripts/chroot"]="0:0:755"
  ["/root/scripts/chroot/timezone.sh"]="0:0:755"
  ["/root/scripts/chroot/locale.sh"]="0:0:755"
  ["/root/scripts/chroot/services.sh"]="0:0:755"
  ["/root/scripts/chroot/nvidia.sh"]="0:0:755"
  ["/root/scripts/chroot/users.sh"]="0:0:755"
  ["/root/scripts/chroot/bootloader.sh"]="0:0:755"
  ["/root/packages.txt"]="0:0:644"
  ["/etc/sddm.conf.d"]="0:0:755"
  ["/etc/sddm.conf.d/autologin.conf"]="0:0:644"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/liveuser"]="0:0:440"
)
