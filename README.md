# arch-javid

Custom Arch Linux installation ISO with KDE Plasma, NVIDIA drivers, and automated installation.

## Features

### Live Environment

The ISO boots into a **live KDE Plasma desktop** with:
- **Username**: `liveuser`
- **Password**: None (auto-login)
- **Sudo access**: Enabled (passwordless)
- **Desktop**: KDE Plasma on Wayland via SDDM
- **Network**: NetworkManager enabled

### Automated Installer

An automated installer script is available on the desktop (or via terminal) that installs:

- **Partitioning**: GPT with EFI (FAT32, 2048 MiB) + Btrfs root
- **Bootloader**: systemd-boot with Intel microcode
- **GPU**: NVIDIA open-source DKMS drivers with Wayland support
- **Desktop**: KDE Plasma on Wayland via plasma-login-manager
- **Audio**: PipeWire
- **Locale**: UK (en_GB.UTF-8, uk keyboard, Europe/London timezone)
- **User**: Customizable username with sudo access

## Usage

### Running the Live Environment

1. Boot from the ISO
2. Automatically logs in to KDE Plasma as `liveuser`
3. Full desktop environment with networking, browser, file manager, etc.

### Installing to Disk

**Option 1**: Double-click the "Arch Installer" desktop icon

**Option 2**: Open Konsole and run:
```bash
sudo /root/scripts/arch-install.sh
```

The installer will:
1. Detect and partition the disk
2. Install all packages (base system, KDE, NVIDIA, applications)
3. Configure locale, timezone, and keyboard layout
4. Set up NVIDIA drivers with Wayland/DRM support
5. Install systemd-boot bootloader
6. Create your user account
7. Reboot into the installed system

### Customization

Build-time configuration is set in [.github/workflows/build.yml](.github/workflows/build.yml):

```yaml
env:
  EFI_SIZE: 2048              # EFI partition size in MiB
  LOCAL_ZONE: Europe/London   # Timezone
  LOCALE: en_GB.UTF-8         # System locale
  KEYMAP: uk                  # Console keymap
  X11_KEYMAP: gb              # X11/Wayland keymap
  HOSTNAME: arch-javid        # Hostname for installed system
  USERNAME: javid             # Username for installed system
  PASSWORD: password          # User password for installed system
```

## Architecture

### Package Lists

The project uses **two separate package lists**:

1. **`packages.x86_64`** - Live ISO packages (used by `mkarchiso`)
   - Minimal base system + SDDM + KDE Plasma desktop
   - Basic applications and partitioning tools
   - **Critical**: Must include `mkinitcpio-archiso` for live boot

2. **`packages.txt`** - Installed system packages (used by `pacstrap`)
   - Full system with NVIDIA drivers + complete KDE suite
   - Uses `plasma-login-manager` instead of SDDM

### Repository Structure

```
arch-javid/
├── .github/workflows/
│   └── build.yml                  # GitHub Actions: builds the ISO
├── airootfs/                      # Live ISO customization files
│   ├── etc/
│   │   ├── sddm.conf.d/
│   │   │   └── autologin.conf     # Auto-login config for live user
│   │   └── sudoers.d/
│   │       └── liveuser           # Sudo permissions for live user
│   └── root/
│       └── customize_airootfs.sh  # Live environment setup script
├── scripts/                       # Installer scripts (for installed system)
│   ├── arch-install.sh            # Main installer orchestrator
│   ├── system/                    # Pre-chroot scripts
│   │   ├── partition.sh           # Partition disk (GPT: EFI + root)
│   │   ├── makefs.sh              # Format partitions
│   │   ├── mount.sh               # Mount filesystems
│   │   ├── unmount.sh             # Unmount filesystems
│   │   └── fstab.sh               # Generate fstab
│   └── chroot/                    # Post-chroot configuration
│       ├── timezone.sh            # Set timezone and hardware clock
│       ├── locale.sh              # Configure locale and keyboard
│       ├── services.sh            # Enable services, rebuild initramfs
│       ├── nvidia.sh              # Configure NVIDIA drivers
│       ├── users.sh               # Create user, set passwords
│       └── bootloader.sh          # Install systemd-boot
├── profiledef.sh                  # Archiso profile definition
├── packages.x86_64                # Package list for live ISO
└── packages.txt                   # Package list for installed system
```

### System Specifications

| Component         | Live ISO              | Installed System                          |
|-------------------|-----------------------|-------------------------------------------|
| **CPU**           | Intel                 | Intel (intel-ucode)                       |
| **GPU**           | Generic (mesa)        | NVIDIA (nvidia-open-dkms + Wayland/DRM)   |
| **Kernel**        | linux                 | linux + linux-headers                     |
| **Filesystem**    | squashfs (read-only)  | Btrfs (root), FAT32 (EFI)                 |
| **Bootloader**    | systemd-boot (ISO)    | systemd-boot                              |
| **Desktop**       | KDE Plasma            | KDE Plasma (Wayland)                      |
| **Display Manager**| SDDM (auto-login)    | plasma-login-manager                      |
| **Audio**         | PipeWire              | PipeWire                                  |

### Boot Parameters

Kernel command line includes:
```
nvidia-drm.modeset=1 nvidia_drm.fbdev=1 quiet splash
```

### NVIDIA Configuration

- **Driver**: `nvidia-open-dkms` (requires `linux-headers`)
- **Modules**: Early loading via initramfs (`MODULES` in `/etc/mkinitcpio.conf`)
- **Modprobe config**:
  - DRM modesetting enabled (`/etc/modprobe.d/nvidia.conf`)
  - VRAM preservation across suspend (`/etc/modprobe.d/nvidia-power.conf`)

## Building the ISO

The ISO is built automatically via GitHub Actions on every push to `main`. To build locally:

```bash
# On Arch Linux:
sudo pacman -S archiso
sudo mkarchiso -v -w work -o out .
```

## License

See [LICENSE](LICENSE)
