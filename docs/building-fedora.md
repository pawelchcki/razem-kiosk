# Building Fedora IoT Kiosk Images

This guide covers building custom Fedora IoT images for the Razem Kiosk system.

## ⚠️ Build Environment Requirement

**Fedora IoT images require native Linux** (Fedora/RHEL preferred).

❌ **Does NOT work on:**
- Windows WSL2 (rpm-ostree limitation)
- macOS (rpm-ostree compatibility)
- Windows native

✅ **Works on:**
- Native Fedora 39+ Linux
- Native RHEL/CentOS Stream 9+
- GitHub Actions (Linux runners)
- Linux VMs on any host

**If you're on WSL2**, see [Build Requirements](BUILDING_REQUIREMENTS.md) for VM or CI/CD alternatives.

## Overview

The Fedora IoT build process uses:
- **Containerfile** for system customization
- **Podman** for container builds
- **bootc-image-builder** to convert containers to bootable images
- **rpm-ostree** for immutable system management

This approach is different from the Raspberry Pi OS build (which uses pi-gen), but shares the same kiosk scripts and configuration.

## Prerequisites

### Required Software

Install on your build system (native Fedora/RHEL Linux):

```bash
# Fedora/RHEL
sudo dnf install podman xz

# Other Linux distributions
# Install podman and xz using your package manager
```

### System Requirements

- **OS**: Linux (Fedora 39+ recommended, but any Linux with Podman works)
- **Podman**: Version 4.0 or later
- **Disk Space**: At least 15GB free
- **RAM**: 4GB minimum (8GB recommended)
- **Time**: 20-40 minutes for full build

### Verify Setup

Run the verification script:

```bash
./verify-build-setup.sh --fedora
```

This checks that all required tools and files are present.

## Build Methods

### Method 1: Quick Build (Recommended)

Use the main build script with the `--fedora` flag:

```bash
./build.sh --fedora
```

For non-interactive builds (CI/CD):

```bash
./build.sh --fedora --yes
```

### Method 2: Direct Build Script

Use the Fedora-specific build script directly:

```bash
./build-fedora.sh
```

Options:
- `--build-only` - Build container only, skip image creation
- `--non-interactive` - Run without prompts
- `-h, --help` - Show help

### Method 3: Manual Container Build

For development and testing:

```bash
# Build container only
podman build -f build-config-fedora/Containerfile -t razem-kiosk-fedora:test .

# Test the container
podman run -it razem-kiosk-fedora:test /bin/bash

# Inside container:
rpm -qa | grep fbida      # Verify packages
systemctl list-units      # Check services
ls -la /opt/kiosk/        # Verify kiosk files
```

## Build Process Details

### Step 1: Container Image Build

The build script:
1. Reads configuration from `build-config-fedora/config`
2. Builds container using `build-config-fedora/Containerfile`
3. Base image: `quay.io/fedora/fedora-iot:41`
4. Installs packages: `fbida`, `kbd`
5. Copies kiosk files from `image-files/`
6. Configures systemd services
7. Applies kernel arguments for silent boot

### Step 2: Bootable Image Creation

Using bootc-image-builder:
1. Converts container to raw disk image
2. Creates partition table (GPT)
3. Installs bootloader (GRUB/U-Boot)
4. Configures ostree for immutability
5. Output: `disk.raw` (~3-4GB)

### Step 3: Compression

```bash
# Compress with xz (level 9, multi-threaded)
xz -9 -T0 disk.raw

# Result: ~1-1.5GB compressed image
```

### Step 4: Packaging

Final output: `razem-kiosk-fedora-YYYY-MM-DD.raw.xz`

Located in project root directory.

## Customization

### Modify Base Image

Edit `build-config-fedora/Containerfile`:

```dockerfile
# Change Fedora IoT version
FROM quay.io/fedora/fedora-iot:42  # Use version 42 instead
```

### Add/Remove Packages

```dockerfile
# Add packages
RUN rpm-ostree install fbida kbd htop vim && ostree container commit

# Remove packages (be careful!)
RUN rpm-ostree override remove packagename && ostree container commit
```

### Modify Kernel Arguments

```dockerfile
# Silent boot arguments
RUN rpm-ostree kargs \
    --append='quiet' \
    --append='loglevel=0' \
    --append='console=tty3'

# GPU memory (for Pi 3+: reduce to 128M)
RUN rpm-ostree kargs \
    --append='gpu_mem=128'
```

### Change Default User

```dockerfile
# Different username and password
RUN useradd -m -G wheel kiosk && \
    echo 'kiosk:secure_password' | chpasswd && \
    mkdir -p /etc/systemd/system/getty@tty1.service.d && \
    echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin kiosk --noclear %I $TERM' \
    > /etc/systemd/system/getty@tty1.service.d/autologin.conf
```

### Disable Auto-login

Remove or comment out the auto-login section in Containerfile:

```dockerfile
# RUN useradd -m -G wheel pi && \
#     echo 'pi:raspberry' | chpasswd && \
#     ...
```

### Add Custom Services

```dockerfile
# Copy your custom service
COPY my-service.service /etc/systemd/system/

# Enable it
RUN systemctl enable my-service.service
```

## Build Configuration

Edit `build-config-fedora/config`:

```bash
# Image naming
IMAGE_NAME="my-custom-kiosk"
IMAGE_VERSION="2.0"

# Container configuration
CONTAINER_NAME="localhost/${IMAGE_NAME}"
BASE_IMAGE="quay.io/fedora/fedora-iot:41"

# Compression
COMPRESS_XZ=1       # 0 to disable compression
XZ_LEVEL=9          # 1-9 (9 = maximum compression)
XZ_THREADS=0        # 0 = auto-detect CPU cores
```

## Target Platforms

Fedora IoT images support:
- **Raspberry Pi 3B/3B+** (aarch64)
- **Raspberry Pi 4** (aarch64)
- **Raspberry Pi 400** (aarch64)

64-bit ARM only. For 32-bit ARM, use Raspberry Pi OS build.

## Platform Optimization

### Raspberry Pi 3+ (1GB RAM)

Lower memory usage:

```dockerfile
# Reduce GPU memory
RUN rpm-ostree kargs --append='gpu_mem=128'

# Disable more services
RUN systemctl disable zram-swap.service
```

### Raspberry Pi 4 (2GB+ RAM)

Standard configuration works well. Optional optimization:

```dockerfile
# Increase GPU memory for better graphics
RUN rpm-ostree kargs --append='gpu_mem=256'
```

## Troubleshooting

### Build Fails: "No space left on device"

```bash
# Check disk space
df -h

# Clean up old containers and images
podman system prune -a

# Clean up bootc-image-builder cache
sudo rm -rf /var/tmp/bootc-*
```

### Container Build Succeeds, Image Creation Fails

```bash
# Test with --build-only first
./build-fedora.sh --build-only

# Check container storage
podman images

# Try pulling bootc-image-builder manually
podman pull quay.io/centos-bootc/bootc-image-builder:latest
```

### Permission Denied Errors

```bash
# bootc-image-builder needs privileged mode
# Add your user to podman group (Fedora/RHEL)
sudo usermod -aG podman $USER
newgrp podman

# Or run with sudo
sudo ./build-fedora.sh
```

### Slow Build Times

```bash
# Use faster compression
# Edit build-config-fedora/config:
XZ_LEVEL=6          # Faster, larger file
XZ_THREADS=4        # Limit CPU usage

# Or disable compression
COMPRESS_XZ=0
```

### SELinux Errors in Container

If you see SELinux denials in logs:

```dockerfile
# Temporary fix: Add to Containerfile
RUN setenforce 0

# Better: Fix SELinux contexts
RUN restorecon -R /opt/kiosk
```

### Image Won't Boot

1. Check image integrity:
   ```bash
   xz -t razem-kiosk-fedora-*.raw.xz
   ```

2. Verify partitions:
   ```bash
   xz -d razem-kiosk-fedora-*.raw.xz
   fdisk -l razem-kiosk-fedora-*.raw
   ```

3. Try flashing again with verification:
   ```bash
   sudo dd if=razem-kiosk-fedora-*.raw of=/dev/sdX bs=4M conv=fsync status=progress
   sudo sync
   ```

## Advanced Topics

### Cross-Architecture Builds

To build ARM images on x86_64:

```bash
# Install qemu-user-static
sudo dnf install qemu-user-static

# Enable binfmt
sudo systemctl restart systemd-binfmt

# Build normally
./build-fedora.sh
```

### Custom Base Images

Use a different base:

```dockerfile
# Fedora Server instead of IoT
FROM quay.io/fedora/fedora:41

# Fedora CoreOS
FROM quay.io/fedora/fedora-coreos:stable
```

### Layer Caching

Speed up repeated builds:

```dockerfile
# Separate package installation layers
RUN rpm-ostree install fbida && ostree container commit
RUN rpm-ostree install kbd && ostree container commit

# Podman will cache each layer
```

### Testing Images with QEMU

Test before flashing to SD card:

```bash
# Install QEMU
sudo dnf install qemu-system-aarch64

# Run image (requires UEFI firmware)
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -m 2G \
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive file=razem-kiosk-fedora-*.raw,format=raw \
  -nographic
```

## Build Time Estimates

- **Container build**: 10-20 minutes
- **Image creation**: 10-20 minutes
- **Compression**: 5-15 minutes
- **Total**: 25-55 minutes (depending on hardware and network)

Compare to Raspberry Pi OS build: 30-90 minutes

## Next Steps

After successful build:
1. Flash image to SD card: [Installation Guide](installation.md)
2. Boot Raspberry Pi
3. Add images to `/opt/kiosk/images/`
4. Monitor with `systemctl status kiosk-display.service`

## See Also

- [Installation Guide](installation.md) - Flashing and setup
- [Main Building Guide](building.md) - Raspberry Pi OS builds
- [Architecture Overview](../README.md#architecture) - How it works
- [rpm-ostree Documentation](https://coreos.github.io/rpm-ostree/) - System management
- [bootc Documentation](https://containers.github.io/bootc/) - Image format
