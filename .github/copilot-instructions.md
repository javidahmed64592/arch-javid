# Copilot Instructions

## Project Goal

Build a customised Arch Linux installation ISO with a **live KDE Plasma desktop** and an **automated installer** targeting:

- Intel CPU + NVIDIA GPU (nvidia-open-dkms, DRM modesetting enabled)
- KDE Plasma desktop on Wayland
- systemd-boot bootloader
- UK locale, keyboard, timezone
- Fully automated installation from desktop icon or terminal

---

## Repository Structure

```
arch-javid/
├── .github/workflows/build.yml   # GitHub Actions: builds ISO
├── airootfs/                     # Live ISO customization
│   ├── etc/
│   │   ├── sddm.conf.d/autologin.conf
│   │   └── sudoers.d/liveuser
│   └── root/customize_airootfs.sh
├── scripts/                      # Installer scripts (embedded in ISO)
│   ├── arch-install.sh           # Main installer orchestrator
│   ├── system/                   # Pre-chroot: partition, makefs, mount, fstab
│   └── chroot/                   # Post-chroot: timezone, locale, services, nvidia, users, bootloader
├── profiledef.sh                 # Archiso profile + file permissions
├── packages.x86_64               # Live ISO packages (must include mkinitcpio-archiso)
└── packages.txt                  # Installed system packages
```

---

## Architecture Decisions

### Partition Layout

| Partition | Type             | Filesystem | Size      |
| --------- | ---------------- | ---------- | --------- |
| EFI       | ESP              | FAT32      | 2048 MiB  |
| Root      | Linux filesystem | Btrfs      | Remainder |

No swap partition — the Btrfs root handles memory pressure via zram/swapfile if needed.

### Boot Stack

- **Bootloader**: systemd-boot (`bootctl install`)
- **Entry**: `/boot/loader/entries/arch.conf`
- **Initrd order**: `intel-ucode.img` (first), then `initramfs-linux.img`
- **Kernel parameters**: `root=UUID=... rw nvidia-drm.modeset=1 nvidia_drm.fbdev=1 quiet splash`

### GPU / Display Stack

- **Driver package**: `nvidia-open-dkms` (requires `linux-headers`)
- **Supporting packages**: `nvidia-utils`, `nvidia-settings`, `lib32-nvidia-utils`
- **Vulkan**: `vulkan-icd-loader`, `lib32-vulkan-icd-loader`, `vulkan-tools`
- `nvidia.sh` writes two modprobe config files:
  - `/etc/modprobe.d/nvidia.conf` — enables `drm.modeset=1` and `fbdev=1`
  - `/etc/modprobe.d/nvidia-power.conf` — preserves VRAM across suspend/resume
- NVIDIA modules (`nvidia`, `nvidia_modeset`, `nvidia_uvm`, `nvidia_drm`) are added to `MODULES=()` in `/etc/mkinitcpio.conf` for early KMS.
- `mkinitcpio -P linux` is called in `services.sh` after all module config is written.

### Desktop Environment

- **Installed system**: KDE Plasma (`plasma-meta`) on Wayland via `plasma-login-manager`
- **Live ISO**: KDE Plasma components + SDDM (auto-login as `liveuser`)
- **Wayland compatibility**: `xorg-xwayland`
- **Audio**: Pipewire (`pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`)
- **Network**: NetworkManager (enabled in `services.sh`)

### Package Lists

**`packages.x86_64`** (Live ISO - used by mkarchiso):

- Base: `base`, `linux`, `linux-firmware`, `sudo`
- **Critical**: `archiso`, `mkinitcpio-archiso` (required for live boot)
- Desktop: KDE Plasma components, `sddm`, `xorg-xwayland`
- Tools: `parted`, `gparted`, `btrfs-progs`, `konsole`, `dolphin`

**`packages.txt`** (Installed system - used by pacstrap):

- Base: `base`, `linux`, `linux-headers`, `linux-firmware`, `intel-ucode`
- Desktop: `plasma-meta`, `plasma-login-manager`, `xorg-xwayland`
- NVIDIA: `nvidia-open-dkms`, `nvidia-utils`, `nvidia-settings`
- Vulkan: `vulkan-icd-loader`, `lib32-vulkan-icd-loader`, `vulkan-tools`
- Apps: `firefox`, `ark`, `dolphin`, `kate`, `konsole`, `mpv`, etc.

---

## Build Workflow (GitHub Actions)

**File**: `.github/workflows/build.yml`

**Triggers**: push to `main`, PRs to `main`, manual `workflow_dispatch`.

**Environment variables injected at build time via `sed`**:

```
EFI_SIZE=2048         # MiB
LOCAL_ZONE=Europe/London
LOCALE=en_GB.UTF-8
KEYMAP=uk             # console keymap (vconsole.conf)
X11_KEYMAP=gb         # X11/Wayland keymap (xorg.conf.d)
HOSTNAME=arch-javid
USERNAME=javid
PASSWORD=password
```

**Step-by-step build process**:

1. Check out repository on `archlinux:latest` runner.
2. Restore pacman package cache (GitHub Actions cache).
3. Install `archiso` on the runner.
4. Copy the upstream `releng` profile: `cp -r /usr/share/archiso/configs/releng/ .`
5. Embed scripts:
   - Copy `scripts/` → `airootfs/root/scripts/`
   - Use `sed` to inject all env vars into `arch-install.sh`
   - `chmod +x` every `.sh` file
   - Copy `packages.txt` → `airootfs/root/packages.txt`
6. Patch `profiledef.sh` to declare correct file permissions for embedded scripts.
7. Build: `mkarchiso -v -w /root/work -o /root/out .`
8. Upload the resulting `.iso` as a GitHub Actions artifact.

---

## Installation Script Logic

`arch-install.sh` orchestrates the full installation:

1. Auto-detect disk via `lsblk`; skip partitioning if partitions exist
2. Call `system/partition.sh` → `makefs.sh` → `mount.sh`
3. Enable `multilib` in `/etc/pacman.conf`
4. Run `pacstrap /mnt` with packages from `packages.txt`
5. Generate fstab via `system/fstab.sh`
6. `arch-chroot` and run: `timezone.sh` → `locale.sh` → `services.sh` → `nvidia.sh` → `users.sh` → `bootloader.sh`
7. Unmount via `system/unmount.sh`

All scripts use `set -euo pipefail` and are parameterized via environment variables.

---

## Coding Conventions

- All shell scripts begin with `#!/bin/bash` and `set -euo pipefail`
- Scripts use command-line arguments (e.g., `--disk`, `--efi-size`), not environment variables for parameters
- `arch-install.sh` uses environment variables (injected at build time) and passes args to subscripts
- Keep each script focused on a single responsibility
- Live ISO packages → `packages.x86_64`; installed system packages → `packages.txt`
- **Critical**: `packages.x86_64` must include `mkinitcpio-archiso` for live boot to work
- Kernel params affecting NVIDIA/Wayland in `bootloader.sh` must include: `nvidia-drm.modeset=1 nvidia_drm.fbdev=1 quiet splash`
- `bootloader.sh` must load `intel-ucode.img` before `initramfs-linux.img`

---

## Key Constraints

- **CPU**: Intel-only; `intel-ucode` must be loaded first in bootloader entry
- **NVIDIA**: `nvidia-open-dkms` (requires `linux-headers`); early KMS via `MODULES` in mkinitcpio
- **Bootloader**: systemd-boot with FAT32 EFI partition mounted at `/boot`
- **Filesystem**: Btrfs root (no ext4/swap partitions)
- **Display**: Wayland primary; `xorg-xwayland` for compatibility
- **Display Manager**: Live ISO uses `sddm`; installed system uses `plasma-login-manager`
- **Live boot**: `packages.x86_64` must include `mkinitcpio-archiso` or ISO won't boot
