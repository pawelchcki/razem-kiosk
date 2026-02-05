# Quick Start Guide - Raspberry Pi Kiosk

## 5-Minute Setup

### Prerequisites
- Raspberry Pi 4 with Raspberry Pi OS Lite installed
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

### Test Navigation
- Press **Right Arrow** → Next image
- Press **Left Arrow** → Previous image
- Press **Space** → Next image
- Press **Backspace** → Previous image

### Make It Permanent

```bash
# Enable auto-start on boot
sudo systemctl enable kiosk-display.service

# Enable immortal mode (read-only filesystem)
sudo kiosk-overlay enable
sudo reboot
```

## That's It! 🎉

Your kiosk is now:
- ✅ Auto-starting on boot
- ✅ Protected from SD card corruption
- ✅ Surviving power loss without damage
- ✅ Displaying your images

## Common Commands

```bash
# View logs
sudo journalctl -u kiosk-display.service -f

# Restart service
sudo systemctl restart kiosk-display.service

# Check overlay status
sudo kiosk-overlay status

# Update images (requires disabling overlay)
sudo kiosk-overlay disable
sudo reboot
# ... copy new images ...
sudo kiosk-overlay enable
sudo reboot
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
