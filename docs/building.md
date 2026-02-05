# Building Custom Kiosk Image

This guide explains how to build a custom Raspberry Pi OS image with the kiosk display system pre-installed.

## Overview

The build process uses [pi-gen](https://github.com/RPi-Distro/pi-gen), the official Raspberry Pi OS image builder. This creates a bootable `.img` file that can be flashed directly to an SD card.

**Build outputs:**
- A complete, bootable Raspberry Pi OS image (~2GB compressed)
- Kiosk system pre-installed and configured
- Ready to flash and boot - no manual installation needed

## Prerequisites

### Using Docker (Recommended)

**Required:**
- Linux or macOS (Windows with WSL2 also works)
- Docker installed and running
- ~10GB free disk space
- ~30-60 minutes build time

**Install Docker:**
- Linux: `curl -fsSL https://get.docker.com | sh`
- macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Windows: Install [Docker Desktop with WSL2](https://docs.docker.com/desktop/windows/wsl/)

### Using Native Build

**Required:**
- Debian-based Linux (Ubuntu, Debian, Raspberry Pi OS)
- Build dependencies (installed automatically by pi-gen)
- ~10GB free disk space
- ~30-60 minutes build time

**Note:** Native builds require root access and may modify system configuration. Docker is recommended for isolation.

## Quick Build

1. **Clone repository with submodules:**
   ```bash
   git clone --recursive https://github.com/razem-io/kiosk.git
   cd kiosk
   ```

   If already cloned without submodules:
   ```bash
   git submodule update --init --recursive
   ```

2. **Run build script:**
   ```bash
   ./build.sh
   ```

3. **Wait for build to complete** (~30-60 minutes)

4. **Find output image:**
   ```bash
   ls -lh razem-kiosk-*.img
   ```

That's it! The image is ready to flash.

## Build Configuration

The build is configured via `build-config/config`:

```bash
# Image name and release
IMG_NAME='razem-kiosk'
RELEASE='bookworm'

# Target system
TARGET_HOSTNAME='kiosk'
TIMEZONE_DEFAULT='Europe/Warsaw'
LOCALE_DEFAULT='en_US.UTF-8'

# Enable SSH for maintenance
ENABLE_SSH=1

# Default credentials
FIRST_USER_NAME='pi'
FIRST_USER_PASS='raspberry'

# Minimal image (no desktop)
STAGE_LIST="stage0 stage1 stage2 stage-kiosk"
```

### Customization Options

**Change timezone:**
```bash
TIMEZONE_DEFAULT='America/New_York'
```

**Change hostname:**
```bash
TARGET_HOSTNAME='my-kiosk'
```

**Change default credentials:**
```bash
FIRST_USER_NAME='kiosk'
FIRST_USER_PASS='mypassword'
```

**Disable SSH:**
```bash
ENABLE_SSH=0
```

After changing configuration, rebuild the image.

## Build Process Details

### What Happens During Build

1. **Stage 0:** Bootstrap base Debian system
2. **Stage 1:** Install essential packages
3. **Stage 2:** Configure networking and utilities
4. **Stage Kiosk (custom):**
   - Install `fbi` (framebuffer image viewer) and `kbd`
   - Copy kiosk scripts to `/opt/kiosk/`
   - Install systemd service
   - Configure auto-login
   - Disable screen blanking
   - Configure silent boot
   - Set up hardware configuration
   - Disable unnecessary services
   - Pre-configure overlay filesystem support

### Build Stages Directory

```
pi-gen/
├── stage0/         # Bootstrap
├── stage1/         # Essential packages
├── stage2/         # Networking
└── stage-kiosk/    # Custom kiosk configuration (symlinked from build-config/)
    ├── 00-packages/         # Install fbi, kbd
    ├── 01-kiosk-setup/      # Configure kiosk system
    └── 02-overlay-setup/    # Pre-configure read-only filesystem
```

### Build Artifacts

During build, pi-gen creates:
- `pi-gen/work/` - Intermediate build files (can be deleted after build)
- `pi-gen/deploy/` - Final image files
- Build logs in `pi-gen/work/*/build.log`

Final image is copied to project root: `razem-kiosk-<date>.img`

## Troubleshooting

### Build Fails with "Permission Denied"

**Docker:** Make sure Docker daemon is running and user is in `docker` group:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

**Native:** pi-gen requires root access:
```bash
cd pi-gen && sudo ./build.sh
```

### Build Fails with "No space left on device"

Build requires ~10GB free space:
```bash
df -h .
rm -rf pi-gen/work pi-gen/deploy  # Clean previous builds
```

### Build Hangs or Takes Very Long

Expected build time: 30-60 minutes

Check progress:
```bash
# Watch build logs
tail -f pi-gen/work/*/build.log

# Check if build is active
docker ps  # (if using Docker)
```

### Build Fails at Stage-Kiosk

Check stage logs:
```bash
cat pi-gen/work/*/stage-kiosk/build.log
```

Common issues:
- **Missing files:** Ensure `scripts/`, `configs/`, `systemd/` directories exist
- **Permission errors:** Ensure stage scripts are executable (`chmod +x`)
- **Syntax errors:** Check bash scripts for errors

### Docker Build Fails on ARM (Raspberry Pi)

Building on Raspberry Pi is possible but slow (2-3 hours). Use a faster x86_64 machine if available.

```bash
# On Pi, use native build instead
cd pi-gen
sudo ./build.sh
```

### "Config file not found"

Ensure you're running `./build.sh` from the project root, not from inside `pi-gen/`:
```bash
cd /path/to/kiosk
./build.sh
```

## Testing the Image

After build completes:

1. **Verify image size:**
   ```bash
   ls -lh razem-kiosk-*.img
   # Should be ~3-4GB uncompressed
   ```

2. **Test flash (optional):**
   ```bash
   # Flash to SD card (replace /dev/sdX with your SD card)
   sudo dd if=razem-kiosk-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

3. **Boot test:**
   - Insert SD card in Raspberry Pi 4
   - Connect HDMI display
   - Power on
   - Should boot silently and show kiosk service status

See [installation.md](installation.md) for full testing procedures.

## Advanced: Manual Build Steps

If you need more control, run pi-gen manually:

```bash
cd pi-gen

# Clean
rm -rf work deploy

# Configure
cp ../build-config/config ./config

# Link custom stage
ln -sf ../build-config/stage-kiosk ./stage-kiosk

# Build with Docker
./build-docker.sh

# Or build natively
sudo ./build.sh

# Output in deploy/
ls -lh deploy/
```

## Advanced: Modify Custom Stage

The custom kiosk stage is in `build-config/stage-kiosk/`:

```
stage-kiosk/
├── 00-packages/
│   └── 00-packages.sh          # Install packages
├── 01-kiosk-setup/
│   ├── 00-run.sh               # Main setup script
│   └── files/                  # Files to copy into image
│       ├── opt/kiosk/scripts/
│       ├── etc/systemd/system/
│       └── boot/firmware/
├── 02-overlay-setup/
│   └── 00-run.sh               # Overlay filesystem setup
└── prerun.sh                   # Stage dependencies
```

After modifying, rebuild the image.

## Build Time Optimization

### First Build (Clean)
- ~30-60 minutes (Docker)
- ~45-90 minutes (Native)

### Incremental Builds

pi-gen caches completed stages. If only stage-kiosk changed:
```bash
# Don't clean work directory
cd pi-gen
rm -rf deploy  # Only remove final output
./build-docker.sh
# Will skip stage0-2, only rebuild stage-kiosk (~5 minutes)
```

### Parallel Builds

To build multiple configurations in parallel, use separate directories:
```bash
cp -r . ../kiosk-build-2
cd ../kiosk-build-2
# Modify config
./build.sh
```

## Creating GitHub Releases

To automate builds on release:

1. Tag a release: `git tag v1.0.0 && git push --tags`
2. GitHub Actions can run `./build.sh` automatically
3. Upload resulting `.img.zip` as release asset

See `.github/workflows/build.yml` (if available) for automation setup.

## Next Steps

After successful build:
- [Flash and test the image](installation.md)
- [Add images and configure kiosk](../README.md)
- [Enable overlay protection](installation.md#enabling-read-only-mode)

## Resources

- [pi-gen documentation](https://github.com/RPi-Distro/pi-gen)
- [Raspberry Pi documentation](https://www.raspberrypi.com/documentation/)
- [Custom pi-gen stages tutorial](https://github.com/RPi-Distro/pi-gen/blob/master/README.md#stage-anatomy)
