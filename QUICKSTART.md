# Quick Start Guide - Raspberry Pi Kiosk

## Choose Your Distribution

### Raspberry Pi OS (Debian-based)
Best for Pi 4, familiar environment

### Fedora IoT (RPM-based)
Best for Pi 3+, built-in immutability

---

## 5-Minute Setup - Raspberry Pi OS

### Prerequisites
- Raspberry Pi 3+ or 4 with Raspberry Pi OS Lite installed
- USB keyboard connected
- Display connected via HDMI
- Images ready to display

### Installation Steps

```bash
# 1. Clone repository
git clone https://github.com/razem/razem-kiosk.git
cd razem-kiosk

# 2. Run installer
sudo ./scripts/install-kiosk.sh

# 3. Copy images (replace with your image path)
sudo cp /path/to/your/images/*.jpg /opt/kiosk/images/

# 4. Start the viewer
sudo systemctl start kiosk-display.service
```

---

## 5-Minute Setup - Fedora IoT

### Prerequisites
- Raspberry Pi 3+ or 4 with Fedora IoT installed
- USB keyboard connected
- Display connected via HDMI
- Images ready to display

### Installation Steps

```bash
# 1. Clone repository
git clone https://github.com/razem/razem-kiosk.git
cd razem-kiosk

# 2. Run installer (installs packages)
sudo ./scripts/install-kiosk-fedora.sh

# 3. Reboot to apply rpm-ostree changes
sudo systemctl reboot

# 4. After reboot, run installer again to complete setup
cd razem-kiosk
sudo ./scripts/install-kiosk-fedora.sh

# 5. Copy images (replace with your image path)
sudo cp /path/to/your/images/*.jpg /opt/kiosk/images/

# 6. Reboot to start kiosk
sudo systemctl reboot
```

---

### Test Navigation
- Press **Right Arrow** → Next image
- Press **Left Arrow** → Previous image
- Press **Space** → Next image
- Press **Backspace** → Previous image

### Make It Permanent

#### Raspberry Pi OS:

```bash
# Enable auto-start on boot
sudo systemctl enable kiosk-display.service

# Enable immortal mode (read-only filesystem)
sudo kiosk-overlay enable
sudo reboot
```

#### Fedora IoT:

```bash
# Service is already enabled
# System is already immutable via rpm-ostree
# No additional setup needed!
```

## That's It! 🎉

Your kiosk is now:
- ✅ Auto-starting on boot
- ✅ Protected from SD card corruption
- ✅ Surviving power loss without damage
- ✅ Displaying your images

## Common Commands

### Both Distributions:

```bash
# View logs
sudo journalctl -u kiosk-display.service -f

# Restart service
sudo systemctl restart kiosk-display.service

# Check overlay/immutability status
sudo kiosk-overlay status
```

### Raspberry Pi OS Only:

```bash
# Update images (requires disabling overlay)
sudo kiosk-overlay disable
sudo reboot
# ... copy new images ...
sudo kiosk-overlay enable
sudo reboot
```

### Fedora IoT Only:

```bash
# Update images (no overlay to disable)
sudo cp new-images/*.jpg /opt/kiosk/images/
sudo systemctl restart kiosk-display.service

# Update system packages
sudo rpm-ostree upgrade
sudo systemctl reboot

# Rollback to previous deployment
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Need Help?

- **Full guide**: See [docs/installation.md](docs/installation.md)
- **Maintenance**: See [docs/maintenance.md](docs/maintenance.md)
- **Troubleshooting**: Check logs with `sudo journalctl -u kiosk-display.service`

## Image Tips

- Use **numeric prefixes** for ordering: `001-first.jpg`, `002-second.jpg`
- **Supported formats**: JPG, PNG, BMP, GIF
- **Resolution**: Any (auto-scaled to screen)
- **Location**: `/opt/kiosk/images/`

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Right Arrow | Next image |
| Left Arrow | Previous image |
| Space | Next image |
| Backspace | Previous image |
| Q | Exit (will restart) |
| Alt+F2 | Switch to console |
| Alt+F1 | Return to viewer |
