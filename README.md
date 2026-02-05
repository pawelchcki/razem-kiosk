# Razem Kiosk - Raspberry Pi Display System

A minimal, robust image slideshow system for Raspberry Pi that boots directly to a framebuffer image viewer with no desktop environment. Designed for reliability, simplicity, and "immortal" operation with read-only filesystem protection.

Perfect for digital signage, information displays, and kiosk applications.

## Features

- 🚀 **Fast Boot**: Boots directly to image display in seconds
- 🛡️ **Immortal Mode**: Read-only filesystem survives power loss and SD card corruption
- ⌨️ **Manual Navigation**: Arrow keys control image browsing (no auto-advance)
- 🎯 **Minimal**: No desktop environment, X11, or unnecessary services
- 📦 **Lightweight**: Runs on Raspberry Pi OS Lite with minimal packages
- 🔧 **Easy Maintenance**: Simple scripts for updates and configuration changes

## Hardware Requirements

- **Raspberry Pi 4** (Model B recommended)
- **SD Card**: 8GB minimum, 16GB recommended
- **Display**: HDMI-compatible monitor or TV
- **USB Keyboard**: For image navigation
- **Power Supply**: Official Raspberry Pi 4 power supply

## Quick Start

### 1. Flash Raspberry Pi OS Lite

Download and flash **Raspberry Pi OS Lite (64-bit)** to your SD card:
https://www.raspberrypi.com/software/operating-systems/

### 2. Boot and Install

Boot your Raspberry Pi and run:

```bash
# Clone repository
git clone https://github.com/razem/razem-kiosk.git
cd razem-kiosk
sudo ./scripts/install-kiosk.sh
```

### 3. Add Images

Copy your images to the kiosk:

```bash
sudo cp /path/to/images/*.jpg /opt/kiosk/images/
```

### 4. Test

Start the viewer:

```bash
sudo systemctl start kiosk-display.service
```

Use **arrow keys** to navigate images.

### 5. Enable Immortal Mode

Once everything works, enable read-only filesystem:

```bash
sudo kiosk-overlay enable
sudo reboot
```

Your kiosk is now immortal - it can survive power loss without corruption!

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

- **[Installation Guide](docs/installation.md)**: Complete step-by-step setup instructions
- **[Maintenance Guide](docs/maintenance.md)**: Updating images, system updates, troubleshooting

## Directory Structure

```
razem-kiosk/
├── README.md                    # This file
├── docs/
│   ├── installation.md          # Detailed installation guide
│   └── maintenance.md           # Maintenance and troubleshooting
├── configs/
│   ├── cmdline.txt              # Boot parameters (silent boot)
│   ├── config.txt               # Pi hardware configuration
│   └── overlayfs-setup.sh       # Read-only filesystem management
├── scripts/
│   ├── install-kiosk.sh         # Master installation script
│   └── image-viewer.sh          # FBI wrapper with keyboard handling
├── systemd/
│   └── kiosk-display.service    # Auto-start service definition
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
- [ ] Pre-built SD card images

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
