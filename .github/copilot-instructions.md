# Copilot Instructions

## Project Goal

Build a customised Arch Linux installation ISO targeting an Intel-based machine with:

- NVIDIA GPU (open-source DKMS drivers, DRM modesetting enabled for Wayland)
- KDE Plasma desktop on Wayland
- systemd-boot bootloader
- UK locale, keyboard and timezone
- **Calamares GUI installer** — all installation steps are driven by the Calamares
  wizard; no manual shell interaction is required

---

## Repository Structure

```
arch-javid/
├── .github/
│   └── workflows/
│       └── build.yml              # GitHub Actions CI/CD — builds the ISO
├── airootfs/                       # Overlay on the releng airootfs for the live session
│   ├── etc/
│   │   ├── sddm.conf.d/
│   │   │   └── autologin.conf     # SDDM autologin → liveuser (plasmawayland session)
│   │   ├── xdg/autostart/
│   │   │   └── calamares.desktop  # KDE autostart entry — launches Calamares on login
│   │   └── polkit-1/rules.d/
│   │       └── 49-calamares.rules # Polkit rule: allow wheel-group user to run Calamares
│   └── root/
│       └── customize_airootfs.sh  # archiso hook: creates liveuser + enables sddm
├── calamares/
│   ├── settings.conf              # Calamares module sequence (show + exec phases)
│   ├── modules/                   # Per-module configuration overrides
│   │   ├── welcome.conf
│   │   ├── locale.conf            # Default region: Europe / zone: London
│   │   ├── keyboard.conf          # Default layout: gb, model: pc105
│   │   ├── partition.conf         # Erase-disk mode; EFI=2048MiB; root=btrfs; no swap
│   │   ├── mount.conf             # btrfs options: compress=zstd
│   │   ├── shellprocess-multilib-live.conf      # Enables multilib on the live host
│   │   ├── shellprocess-pacstrap.conf           # Runs pacstrap with packages.txt
│   │   ├── shellprocess-multilib-installed.conf # Enables multilib in the installed system
│   │   ├── machineid.conf
│   │   ├── fstab.conf
│   │   ├── localecfg.conf         # Ensures en_GB.UTF-8 is generated
│   │   ├── timezone.conf          # hwClock: UTC
│   │   ├── users.conf             # wheel group, bash shell, setRootPassword: true
│   │   ├── networkcfg.conf        # writeEtcHosts: true
│   │   ├── hwclock.conf
│   │   ├── services-systemd.conf  # Enables NetworkManager + plasmalogin
│   │   ├── shellprocess-nvidia.conf     # Runs nvidia.sh inside the installed chroot
│   │   ├── shellprocess-initramfs.conf  # mkinitcpio -P linux (after nvidia.sh)
│   │   ├── bootloader.conf        # systemd-boot; NVIDIA kernel params; intel-ucode handled automatically
│   │   └── umount.conf
│   └── scripts/                   # Shell helpers invoked by shellprocess modules
│       ├── multilib-live.sh       # sed pacman.conf + pacman -Sy (on host)
│       ├── pacstrap.sh            # pacstrap /tmp/calamares-root using packages.txt
│       ├── multilib-installed.sh  # sed /tmp/calamares-root/etc/pacman.conf (on host)
│       ├── nvidia.sh              # Configures NVIDIA modprobe + mkinitcpio.conf MODULES
│       └── initramfs.sh           # arch-chroot mkinitcpio -P linux
├── live-packages.txt              # Extra packages appended to the releng packages.x86_64
└── packages.txt                   # Full package list consumed by pacstrap during install
```

---

## Architecture Decisions

### Installer

Calamares drives the full installation interactively. The user selects locale, keyboard,
timezone, disk, username and password through the wizard. Calamares handles partitioning,
mounting, package installation (via the `shellprocess@pacstrap` module), fstab, locale,
keyboard, timezone, hostname, user accounts, services, and systemd-boot installation.

The only steps Calamares cannot handle natively are:

1. **Multilib enablement** — done via `shellprocess@multilib-live` (on the host before
   pacstrap) and `shellprocess@multilib-installed` (in the target after pacstrap).
2. **NVIDIA driver configuration** — done via `shellprocess@nvidia`, which configures
   modprobe options and mkinitcpio MODULES directly on the target.
3. **Initramfs rebuild** — done via `shellprocess@initramfs` after the NVIDIA modules
   have been added to `mkinitcpio.conf`.

### Calamares Exec Sequence (ordering is mandatory)

```
partition → mount
→ shellprocess@multilib-live       (multilib on host — BEFORE pacstrap)
→ shellprocess@pacstrap            (install packages into target)
→ shellprocess@multilib-installed  (multilib in target — AFTER pacstrap)
→ machineid → fstab → localecfg → keyboard → timezone
→ networkcfg → hwclock → users
→ services-systemd                 (enable NetworkManager + plasmalogin)
→ shellprocess@nvidia              (NVIDIA config — BEFORE initramfs)
→ shellprocess@initramfs           (mkinitcpio — BEFORE bootloader)
→ bootloader
→ umount
```

### Live ISO Session

The live ISO runs KDE Plasma on Wayland via SDDM. SDDM autologins as `liveuser`
(created by `customize_airootfs.sh`). Calamares launches automatically via the KDE
autostart mechanism (`/etc/xdg/autostart/calamares.desktop`). Root privileges are
granted via passwordless sudo for the `wheel` group, which `liveuser` belongs to.

The live ISO display manager is **SDDM** (for the live session only). The **installed
system** uses **plasmalogin** (`plasma-login-manager`), enabled by the `services-systemd`
Calamares module. These two DMs do not conflict because they are installed in entirely
separate environments (the live ISO's `packages.x86_64` vs. the installed system via
`packages.txt` / pacstrap).

### Partition Layout

| Partition | Type             | Filesystem | Size      |
| --------- | ---------------- | ---------- | --------- |
| EFI       | ESP              | FAT32      | 2048 MiB  |
| Root      | Linux filesystem | Btrfs      | Remainder |

No swap partition. The Calamares `partition.conf` sets `userSwapChoices: [none]`.
Btrfs is mounted with `compress=zstd`.

### Boot Stack

- **Bootloader**: systemd-boot (`bootctl install`)
- **Entry file**: `/boot/loader/entries/arch.conf`
- **Required kernel parameters**:
  ```
  quiet nvidia-drm.modeset=1 nvidia_drm.fbdev=1
  ```
- Calamares prepends `root=UUID=<uuid> rw` automatically.
- Calamares auto-detects `/boot/intel-ucode.img` and inserts `initrd /intel-ucode.img`
  before the main initrd line — this fixes the omission that existed in the old
  `bootloader.sh` script.

### GPU / Display Stack

- **Driver package**: `nvidia-open-dkms` (requires `linux-headers`)
- `calamares/scripts/nvidia.sh` writes:
  - `/etc/modprobe.d/nvidia.conf` — `nvidia_drm modeset=1 fbdev=1`
  - `/etc/modprobe.d/nvidia-power.conf` — `NVreg_PreserveVideoMemoryAllocations=1`
- Same script sets `MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)` in
  `/etc/mkinitcpio.conf` for early KMS.
- `mkinitcpio -P linux` is called in `shellprocess@initramfs` **after** the MODULES edit.

### Desktop Environment

- **Session**: KDE Plasma (`plasma-meta`) on Wayland via `plasmalogin`
- **Wayland compatibility bridge**: `xorg-xwayland`
- **Audio**: Pipewire (`pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`)
- **Networking**: NetworkManager (enabled by `services-systemd` module)

### Package Categories (`packages.txt` — installed system)

| Category | Key packages                                                        |
| -------- | ------------------------------------------------------------------- |
| Base     | `base`, `linux`, `linux-headers`, `linux-firmware`, `sudo`, `nano`  |
| CPU      | `intel-ucode`                                                       |
| Network  | `networkmanager`                                                    |
| Desktop  | `plasma-meta`, `plasma-login-manager`, `xorg-xwayland`              |
| KDE apps | `ark`, `dolphin`, `kate`, `konsole`, `mpv`, …                       |
| Audio    | `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`        |
| NVIDIA   | `nvidia-open-dkms`, `nvidia-utils`, `nvidia-settings`               |
| Vulkan   | `vulkan-icd-loader`, `lib32-vulkan-icd-loader`, `vulkan-tools`      |
| 32-bit   | `lib32-mesa`, `lib32-glibc`, `lib32-gcc-libs`, `lib32-nvidia-utils` |

### Live ISO Extra Packages (`live-packages.txt` — appended to releng `packages.x86_64`)

`calamares`, `kpmcore`, `sddm`, `plasma-desktop`, `kwin`, `breeze`, `konsole`,
`polkit-kde-agent`, `plasma-pa`, `pipewire`, `pipewire-pulse`, `wireplumber`,
`xorg-xwayland`

---

## Build Workflow (GitHub Actions)

**File**: `.github/workflows/build.yml`

**Triggers**: push to `main`, PRs to `main`, manual `workflow_dispatch`.

**No build-time environment variables** — all user-specific values (locale, timezone,
hostname, username, password) are collected interactively by the Calamares wizard.

**Step-by-step build process**:

1. Check out repository on `archlinux:latest` runner.
2. Restore pacman package cache (GitHub Actions cache).
3. Install `archiso` and `calamares` on the build runner.
4. Copy the upstream `releng` profile.
5. Append `live-packages.txt` to `packages.x86_64`.
6. Copy `calamares/` → `airootfs/etc/calamares/` and copy `packages.txt` alongside.
   Copy branding; borrow `logo.png` / `welcome.png` from the installed calamares default.
7. Merge `airootfs/` overlay on top of the releng airootfs.
8. Patch `profiledef.sh` with correct permissions for all new files.
9. Build: `mkarchiso -v -w /root/work -o /root/out .`
10. Upload the resulting `.iso` as a GitHub Actions artifact.

---

## Coding Conventions

- All shell scripts **must** begin with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Keep each script focused on a single responsibility (one script = one concern).
- New packages installed in the target system go in `packages.txt`; keep entries grouped
  by category with a blank line between groups.
- New packages required only in the live ISO go in `live-packages.txt`.
- Kernel parameters that affect NVIDIA/Wayland (`nvidia-drm.modeset=1`) must appear in
  `calamares/modules/bootloader.conf` under `kernelLine`.
- When adding a new modprobe option, add it to `calamares/scripts/nvidia.sh`.
- When adding a new kernel module for early loading, add it to the `MODULES=()` sed
  command in `calamares/scripts/nvidia.sh` and ensure `shellprocess@initramfs` runs after.

---

## Key Constraints

- Target CPU is **Intel-only**: `intel-ucode` is in `packages.txt`; Calamares bootloader
  module auto-adds `initrd /intel-ucode.img`.
- The NVIDIA driver is `nvidia-open-dkms` (not `nvidia` or `nvidia-open`); `linux-headers`
  is required as a build dependency.
- systemd-boot requires a **FAT32 EFI partition mounted at `/boot`**; do not change the
  mount point.
- The root filesystem is **Btrfs** — do not introduce ext4 or swap partitions.
- Wayland is the **primary** display server; X11/Xwayland is only a compatibility layer.
- **Installed system DM**: `plasmalogin` (from `plasma-login-manager`) — enabled via
  `services-systemd.conf`. Do **not** use `sddm` or `gdm` for the installed system.
- **Live ISO DM**: `sddm` (for live-session autologin only) — this does not conflict
  with `plasmalogin` because they live in separate package environments.
- All Calamares shellprocess scripts use `/tmp/calamares-root` as the target mount point.
  If this changes in a future Calamares release, update every script in `calamares/scripts/`.
