# Copilot Instructions

## Project Goal

Build a customised Arch Linux installation ISO targeting an Intel-based machine with:

- NVIDIA GPU (open-source DKMS drivers, DRM modesetting enabled for Wayland)
- KDE Plasma desktop on Wayland
- systemd-boot bootloader
- UK locale, keyboard and timezone
- Fully automated, hands-off installation from first boot

---

## Repository Structure

```
arch-javid/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions CI/CD — builds the ISO
├── scripts/
│   ├── arch-install.sh        # Main orchestrator; runs all sub-scripts in order
│   ├── system/
│   │   ├── partition.sh       # Create GPT table: EFI (FAT32) + root (Btrfs)
│   │   ├── makefs.sh          # Format EFI as FAT32, root as Btrfs
│   │   ├── mount.sh           # Mount root → /mnt, EFI → /mnt/boot
│   │   ├── unmount.sh         # umount -R /mnt
│   │   └── fstab.sh           # genfstab -U /mnt >> /mnt/etc/fstab
│   └── chroot/
│       ├── timezone.sh        # Symlink localtime, hwclock --systohc
│       ├── locale.sh          # locale.gen, locale.conf, vconsole.conf, X11 keymap
│       ├── services.sh        # Enable NetworkManager, plasmalogin; mkinitcpio -P
│       ├── nvidia.sh          # modprobe.d rules, early initramfs NVIDIA modules
│       ├── users.sh           # Root password, unprivileged user, wheel sudo
│       └── bootloader.sh      # bootctl install, loader.conf, arch.conf entry
└── packages.txt               # Full package list consumed by pacstrap
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
- **Entry file**: `/boot/loader/entries/arch.conf`
- **Required kernel parameters**:
  ```
  root=... rw quiet splash nvidia-drm.modeset=1 nvidia_drm.fbdev=1
  ```
- Intel microcode (`intel-ucode`) is loaded automatically by systemd-boot when the `.conf` entry includes `initrd /intel-ucode.img`.

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

- **Session**: KDE Plasma (`plasma-meta`) on Wayland via `plasmalogin`
- **Wayland compatibility bridge**: `xorg-xwayland`
- **Audio**: Pipewire (`pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`)
- **Networking**: NetworkManager (service enabled in `services.sh`)

### Package Categories (`packages.txt`)

| Category | Key packages                                                        |
| -------- | ------------------------------------------------------------------- |
| Base     | `base`, `linux`, `linux-headers`, `linux-firmware`, `sudo`, `nano`  |
| CPU      | `intel-ucode`                                                       |
| Network  | `networkmanager`                                                    |
| Desktop  | `plasma-meta`, `plasmalogin`, `xorg-xwayland`                       |
| KDE apps | `ark`, `dolphin`, `kate`, `konsole`, `mpv`, …                       |
| Audio    | `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`        |
| NVIDIA   | `nvidia-open-dkms`, `nvidia-utils`, `nvidia-settings`               |
| Vulkan   | `vulkan-icd-loader`, `lib32-vulkan-icd-loader`, `vulkan-tools`      |
| 32-bit   | `lib32-mesa`, `lib32-glibc`, `lib32-gcc-libs`, `lib32-nvidia-utils` |

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

## Installation Script Logic (`arch-install.sh`)

All scripts use `set -euo pipefail`. The orchestrator:

1. Auto-detects the target disk with `lsblk`.
2. Checks whether the disk already has partitions; skips partitioning if so.
3. Calls `system/partition.sh` → `system/makefs.sh` → `system/mount.sh`.
4. Enables the `multilib` repository in `/etc/pacman.conf` for 32-bit libs.
5. Runs `pacstrap /mnt` with `packages.txt`.
6. Calls `system/fstab.sh`.
7. `arch-chroot`s into `/mnt` and executes each `chroot/*.sh` in order:
   `timezone` → `locale` → `services` → `nvidia` → `users` → `bootloader`
8. Calls `system/unmount.sh`.

---

## Coding Conventions

- All shell scripts **must** begin with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Scripts are parameterised exclusively via **environment variables** — no positional arguments.
- Keep each script focused on a single responsibility (one script = one concern).
- New packages go in `packages.txt`; keep entries grouped by category with a blank line between groups.
- Kernel parameters that affect NVIDIA/Wayland (e.g. `nvidia-drm.modeset=1`) must appear in **both** `bootloader.sh` (the installed system entry) and the ISO's bootloader config templates patched in `build.yml`.
- When adding a new modprobe option, add it to `nvidia.sh`; when adding a new kernel module that must load early, add it to the `MODULES` array manipulation in `nvidia.sh` and re-run `mkinitcpio`.

---

## Key Constraints

- Target CPU is **Intel-only**: always include `intel-ucode` and its initrd line in the boot entry.
- The NVIDIA driver is `nvidia-open-dkms` (not `nvidia` or `nvidia-open`); `linux-headers` is required as a build dependency.
- systemd-boot requires a **FAT32 EFI partition mounted at `/boot`**; do not change the mount point.
- The root filesystem is **Btrfs** — do not introduce ext4 or swap partitions.
- Wayland is the **primary** display server; X11/Xwayland is only a compatibility layer.
- `plasmalogin` (not `sddm`/`gdm`) is used as the display manager — ensure the correct service name is enabled.
