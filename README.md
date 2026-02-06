# Razem Kiosk - Raspberry Pi Display System

[![Nix CI](https://github.com/pawelchcki/razem-kiosk/workflows/Nix%20CI/badge.svg)](https://github.com/pawelchcki/razem-kiosk/actions/workflows/nix.yml)
[![Build Images](https://github.com/pawelchcki/razem-kiosk/workflows/Build%20Kiosk%20Images/badge.svg)](https://github.com/pawelchcki/razem-kiosk/actions/workflows/build-images.yml)

A minimal, robust image slideshow system for Raspberry Pi that boots directly to a framebuffer image viewer with no desktop environment. Designed for reliability, simplicity, and "immortal" operation with read-only filesystem protection.

Perfect for digital signage, information displays, and kiosk applications.

## Features

- 🚀 **Fast Boot**: Boots directly to image display in seconds
- 🛡️ **Immortal Mode**: Read-only filesystem survives power loss and SD card corruption
- ⌨️ **Manual Navigation**: Arrow keys control image browsing (no auto-advance)
- 🎯 **Minimal**: No desktop environment, X11, or unnecessary services
- 📦 **Lightweight**: Runs on Raspberry Pi OS Lite or Fedora IoT with minimal packages
- 🔧 **Easy Maintenance**: Simple scripts for updates and configuration changes
- 🐧 **Two Distributions**: Choose Raspberry Pi OS (Debian) or Fedora IoT (RPM-based)

## Hardware Requirements

- **Raspberry Pi**:
  - Raspberry Pi 3B/3B+ (64-bit, 1GB RAM)
  - Raspberry Pi 4 Model B (2GB+ RAM recommended)
  - Raspberry Pi 400
- **SD Card**: 8GB minimum, 16GB recommended
- **Display**: HDMI-compatible monitor or TV
- **USB Keyboard**: For image navigation
- **Power Supply**: Official Raspberry Pi power supply (3A for Pi 4, 2.5A for Pi 3+)

## Quick Start

### Option 1: Pre-Built Image (Recommended)

**Fastest way to get started - just flash and boot!**

Choose your distribution:

#### Raspberry Pi OS (Debian-based)
Best for Pi 4, familiar Debian environment

1. **Download**: [razem-kiosk-YYYY-MM-DD.img.zip](https://github.com/razem/razem-kiosk/releases)
2. **Flash** using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
3. **Boot** your Raspberry Pi
4. **Add images** via SSH:
   ```bash
   ssh pi@kiosk.local  # password: raspberry
   sudo cp /path/to/images/*.jpg /opt/kiosk/images/
   sudo systemctl restart kiosk-display.service
   ```
5. **Enable immortal mode**:
   ```bash
   sudo kiosk-overlay enable
   sudo reboot
   ```

#### Fedora IoT (RPM-based)
Best for Pi 3+, built-in immutability, modern updates

1. **Download**: [razem-kiosk-fedora-YYYY-MM-DD.raw.xz](https://github.com/razem/razem-kiosk/releases)
2. **Flash** to SD card:
   ```bash
   xz -d razem-kiosk-fedora-*.raw.xz
   sudo dd if=razem-kiosk-fedora-*.raw of=/dev/sdX bs=4M status=progress conv=fsync
   ```
3. **Boot** your Raspberry Pi
4. **Add images** via SSH:
   ```bash
   ssh pi@kiosk.local  # password: raspberry
   sudo cp /path/to/images/*.jpg /opt/kiosk/images/
   sudo systemctl restart kiosk-display.service
   ```
5. **System is already immutable** (rpm-ostree) - no additional setup needed!

Done! Your kiosk is ready and immortal.

### Option 2: Manual Installation

If you prefer to install on existing system:

#### On Raspberry Pi OS:
1. **Flash Raspberry Pi OS Lite (64-bit)**: https://www.raspberrypi.com/software/
2. **Boot and install**:
   ```bash
   git clone https://github.com/razem/razem-kiosk.git
   cd razem-kiosk
   sudo ./scripts/install-kiosk.sh
   ```
3. **Add images** and **enable immortal mode** (see above)

#### On Fedora IoT:
1. **Flash Fedora IoT ARM**: https://fedoraproject.org/iot/
2. **Boot and install**:
   ```bash
   git clone https://github.com/razem/razem-kiosk.git
   cd razem-kiosk
   sudo ./scripts/install-kiosk-fedora.sh
   ```
3. **Reboot** to apply rpm-ostree changes, then run installer again
4. **Add images** (system is already immutable via rpm-ostree)

## Building Custom Image

Want to customize the image or build your own?

### Build Raspberry Pi OS Image
```bash
# Clone with submodules
git clone --recursive https://github.com/razem/razem-kiosk.git
cd razem-kiosk

# Build image (requires Docker, ~30-60 minutes)
./build.sh

# Output: razem-kiosk-YYYY-MM-DD.img
```

### Build Fedora IoT Image
```bash
# Clone repository
git clone https://github.com/razem/razem-kiosk.git
cd razem-kiosk

# Build image (requires Podman, ~20-40 minutes)
./build.sh --fedora

# Or use Fedora-specific script
./build-fedora.sh

# Output: razem-kiosk-fedora-YYYY-MM-DD.raw.xz
```

See [Building Documentation](docs/building.md) for Raspberry Pi OS or [Fedora IoT Building Guide](docs/building-fedora.md) for detailed instructions.
```

See [Building Guide](docs/building.md) for detailed instructions.

## How It Works

### Architecture

```
Raspberry Pi Boot
       ↓
Silent Boot (no console text)
       ↓
Auto-Login to Console
       ↓
Systemd launches kiosk-display.service
       ↓
FBI Framebuffer Image Viewer
       ↓
Images displayed full-screen
       ↓
User navigates with keyboard
```

### Key Components

1. **Boot Configuration** (`configs/cmdline.txt`, `configs/config.txt`)
   - Silent boot (no text/logos)
   - Optimized hardware settings
   - Fast boot parameters

2. **Image Viewer** (`scripts/image-viewer.sh`)
   - Wrapper around `fbi` (framebuffer image viewer)
   - Auto-scales images to display resolution
   - Handles keyboard input
   - Error handling and logging

3. **Overlay Filesystem** (`configs/overlayfs-setup.sh`)
   - Enables read-only root filesystem
   - RAM-based overlay for writes
   - SD card protection
   - Power-loss resilience

4. **Systemd Service** (`systemd/kiosk-display.service`)
   - Auto-starts viewer on boot
   - Restarts on failure
   - Proper TTY handling

## Usage

### Keyboard Controls

- **Left Arrow / Backspace**: Previous image
- **Right Arrow / Space**: Next image
- **Q or Ctrl+C**: Exit viewer (systemd will restart it)

### Common Tasks

**View logs:**
```bash
sudo journalctl -u kiosk-display.service -f
```

**Restart viewer:**
```bash
sudo systemctl restart kiosk-display.service
```

**Check overlay status:**
```bash
sudo kiosk-overlay status
```

**Update images:**
```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# Copy new images
sudo cp /mnt/usb/images/*.jpg /opt/kiosk/images/

# Re-enable overlay
sudo kiosk-overlay enable
sudo reboot
```

## Documentation

- **[Installation Guide](docs/installation.md)**: Complete setup instructions (both pre-built image and manual)
- **[Building Guide](docs/building.md)**: How to build custom images using pi-gen
- **[Maintenance Guide](docs/maintenance.md)**: Updating images, system updates, troubleshooting
- **[Nix Guide](docs/nix.md)**: Using Nix for development and code formatting

## Directory Structure

```
razem-kiosk/
├── README.md                    # This file
├── build.sh                     # Image builder wrapper script
├── verify-build-setup.sh        # Verification script for build setup
├── docs/
│   ├── installation.md          # Installation guide (image + manual)
│   ├── building.md              # Image building guide
│   └── maintenance.md           # Maintenance and troubleshooting
├── build-config/                # pi-gen build configuration
│   ├── config                   # Main pi-gen settings
│   └── stage-kiosk/             # Custom kiosk stage
│       ├── 00-packages/         # Package installation
│       ├── 01-kiosk-setup/      # Kiosk configuration (copies from image-files/)
│       └── 02-overlay-setup/    # Read-only filesystem setup
├── image-files/                 # Files that go into the built image
│   ├── opt/kiosk/scripts/       # Kiosk scripts (image-viewer.sh, overlayfs-setup.sh)
│   └── etc/systemd/system/      # Systemd service (kiosk-display.service)
├── pi-gen/                      # Official Pi image builder (submodule)
├── configs/                     # Reference boot configurations
│   ├── cmdline.txt              # Boot parameters reference
│   └── config.txt               # Pi hardware configuration reference
├── scripts/
│   └── install-kiosk.sh         # Manual installation script
└── images/
    └── .gitkeep                 # Placeholder for image directory
```

## File Locations After Installation

- **Images**: `/opt/kiosk/images/`
- **Scripts**: `/opt/kiosk/scripts/`
- **Logs**: `/var/log/kiosk-display.log` (in RAM when overlay enabled)
- **Service**: `/etc/systemd/system/kiosk-display.service`
- **Overlay Tool**: `/usr/local/bin/kiosk-overlay`

## Technical Details

### Software Stack

- **OS**: Raspberry Pi OS Lite (64-bit, Bookworm or later)
- **Image Viewer**: `fbi` (framebuffer image viewer)
- **Init System**: systemd
- **Filesystem**: ext4 with overlayfs

### Boot Optimizations

- Silent boot (no console text or logos)
- Disabled unnecessary services (Bluetooth, Avahi, etc.)
- Fast HDMI initialization
- Minimal GPU memory allocation (256MB)

### Overlay Filesystem

When enabled:
- Root filesystem becomes read-only
- All writes go to RAM (lost on reboot)
- SD card is never written to during operation
- Survives sudden power loss without corruption
- Can be disabled for maintenance

### Image Requirements

- **Formats**: JPG, JPEG, PNG, BMP, GIF
- **Resolution**: Any (auto-scaled to fit display)
- **Naming**: Alphabetical order determines display sequence
  - Tip: Use numeric prefixes: `001-first.jpg`, `002-second.jpg`, etc.

## Troubleshooting

### Black Screen After Boot

Check HDMI connection and try adding to `/boot/firmware/config.txt`:
```
hdmi_force_hotplug=1
hdmi_drive=2
```

### No Images Displayed

Verify images exist and have correct permissions:
```bash
ls -lh /opt/kiosk/images/
sudo chmod 644 /opt/kiosk/images/*
```

### Service Won't Start

Check logs for specific error:
```bash
sudo journalctl -u kiosk-display.service -xe
```

### Can't Update System

Make sure overlay mode is disabled:
```bash
sudo kiosk-overlay disable
sudo reboot
```

See [Maintenance Guide](docs/maintenance.md) for more troubleshooting steps.

## Performance

- **Boot Time**: ~10-15 seconds from power-on to image display
- **Memory Usage**: ~100-150MB total system RAM
- **SD Card Writes**: Zero (when overlay enabled)
- **Image Transition**: Instant (fbi pre-loads images)

## Security Considerations

- Auto-login enabled (not suitable for public-accessible environments)
- SSH enabled by default (disable if not needed)
- Root filesystem read-only (prevents tampering when overlay enabled)
- No network services exposed by default

## Limitations

- No auto-advance slideshow (manual navigation only)
- No remote control support (keyboard required)
- No video playback (images only)
- Changes require overlay disable + reboot

## Future Enhancements

Possible improvements (not currently implemented):

- [ ] Auto-advance timer option
- [ ] Remote control support (IR receiver)
- [ ] Web interface for image management
- [ ] WiFi-based image sync
- [ ] Video playback support
- [ ] Multi-display support
- [x] Pre-built SD card images (available now!)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test on actual Raspberry Pi hardware
4. Submit a pull request

## License

This project is open source and available for use by Razem party and associated organizations.

## Support

- **Documentation**: See [docs/](docs/) folder
- **Issues**: Report issues through your project management system

## Acknowledgments

- Built on Raspberry Pi OS
- Uses `fbi` (framebuffer image viewer) from the ImageMagick suite
- Designed for reliable digital signage and information displays

---

**Made for Razem party kiosk displays**
