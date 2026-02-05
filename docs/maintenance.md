# Raspberry Pi Kiosk - Maintenance Guide

This guide covers common maintenance tasks for the Raspberry Pi Kiosk system.

## Table of Contents

1. [Understanding Overlay Mode](#understanding-overlay-mode)
2. [Updating Images](#updating-images)
3. [System Updates](#system-updates)
4. [Monitoring and Logs](#monitoring-and-logs)
5. [Service Management](#service-management)
6. [Configuration Changes](#configuration-changes)
7. [Troubleshooting](#troubleshooting)

---

## Understanding Overlay Mode

### What is Overlay Mode?

Overlay mode creates a **read-only filesystem** with a RAM-based overlay. This means:

- ✅ **All writes go to RAM**, not the SD card
- ✅ **SD card is protected** from wear and corruption
- ✅ **Power loss is safe** - can unplug anytime
- ✅ **Automatic recovery** - reboots restore clean state
- ⚠️ **Changes are temporary** - lost after reboot
- ⚠️ **Updates require disabling overlay** first

### Check Overlay Status

```bash
sudo kiosk-overlay status
```

Output will show:
```
Status: ENABLED (read-only mode)
```
or
```
Status: DISABLED (read-write mode)
```

---

## Updating Images

### Method 1: Via USB Drive (No Network Required)

**Step 1**: Disable overlay mode
```bash
sudo kiosk-overlay disable
sudo reboot
```

**Step 2**: After reboot, copy images
```bash
# Mount USB drive
sudo mkdir -p /mnt/usb
sudo mount /dev/sda1 /mnt/usb

# Remove old images (optional)
sudo rm /opt/kiosk/images/*.jpg /opt/kiosk/images/*.png

# Copy new images
sudo cp /mnt/usb/images/* /opt/kiosk/images/

# Verify
ls -lh /opt/kiosk/images/

# Unmount USB
sudo umount /mnt/usb
```

**Step 3**: Test new images
```bash
sudo systemctl restart kiosk-display.service
# Verify images display correctly
```

**Step 4**: Re-enable overlay mode
```bash
sudo kiosk-overlay enable
sudo reboot
```

### Method 2: Via Network (SCP)

**From your computer**:
```bash
# Copy images to Pi
scp /path/to/images/*.jpg pi@raspberrypi.local:/tmp/
```

**On Raspberry Pi**:
```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# After reboot
sudo mv /tmp/*.jpg /opt/kiosk/images/
sudo chown root:root /opt/kiosk/images/*.jpg
sudo chmod 644 /opt/kiosk/images/*.jpg

# Test
sudo systemctl restart kiosk-display.service

# Re-enable overlay
sudo kiosk-overlay enable
sudo reboot
```

### Method 3: Quick Update (Single Image)

If you only need to add/remove one image:

```bash
# Disable overlay temporarily
sudo kiosk-overlay disable
sudo reboot

# Make changes
sudo cp /mnt/usb/new-image.jpg /opt/kiosk/images/
# or
sudo rm /opt/kiosk/images/old-image.jpg

# Re-enable immediately
sudo kiosk-overlay enable
sudo reboot
```

---

## System Updates

### Update Raspberry Pi OS

**Step 1**: Disable overlay mode
```bash
sudo kiosk-overlay disable
sudo reboot
```

**Step 2**: Update system
```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y  # Optional: major updates
```

**Step 3**: Update firmware (optional)
```bash
sudo rpi-update
```

**Step 4**: Clean up
```bash
sudo apt-get autoremove -y
sudo apt-get autoclean
```

**Step 5**: Re-enable overlay
```bash
sudo kiosk-overlay enable
sudo reboot
```

### Update Kiosk Software

**If using git repository**:

```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# Update repository
cd ~/razem-kiosk
git pull

# Re-run installer (safe to run multiple times)
sudo ./scripts/install-kiosk.sh

# Re-enable overlay
sudo kiosk-overlay enable
sudo reboot
```

---

## Monitoring and Logs

### View Real-Time Logs

```bash
# Follow kiosk service logs
sudo journalctl -u kiosk-display.service -f
```

Press **Ctrl+C** to stop following.

### View Recent Logs

```bash
# Last 50 lines
sudo journalctl -u kiosk-display.service -n 50

# Last 100 lines
sudo journalctl -u kiosk-display.service -n 100

# Since last boot
sudo journalctl -u kiosk-display.service -b

# All logs for today
sudo journalctl -u kiosk-display.service --since today
```

### Check Service Status

```bash
# Service status
sudo systemctl status kiosk-display.service

# Is service running?
systemctl is-active kiosk-display.service

# Is service enabled at boot?
systemctl is-enabled kiosk-display.service
```

### System Health Monitoring

**Check temperature**:
```bash
vcgencmd measure_temp
```

**Check throttling** (voltage/temperature issues):
```bash
vcgencmd get_throttled
```

Output meanings:
- `0x0`: No issues
- `0x50000`: Throttled in the past
- `0x50005`: Currently throttled + under-voltage detected

**Check memory usage**:
```bash
free -h
```

**Check disk space**:
```bash
df -h
```

---

## Service Management

### Start/Stop/Restart Service

```bash
# Start service
sudo systemctl start kiosk-display.service

# Stop service
sudo systemctl stop kiosk-display.service

# Restart service (apply changes)
sudo systemctl restart kiosk-display.service

# Reload systemd configuration
sudo systemctl daemon-reload
```

### Enable/Disable Auto-Start

```bash
# Enable auto-start at boot
sudo systemctl enable kiosk-display.service

# Disable auto-start
sudo systemctl disable kiosk-display.service

# Check if enabled
systemctl is-enabled kiosk-display.service
```

### Manual Testing

To test the viewer script manually:

```bash
# Stop the service first
sudo systemctl stop kiosk-display.service

# Run script directly
sudo /opt/kiosk/scripts/image-viewer.sh
```

Press **Ctrl+C** to exit, then:
```bash
# Restart service
sudo systemctl start kiosk-display.service
```

---

## Configuration Changes

### Change Display Resolution

**Edit boot configuration**:
```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# Edit config
sudo nano /boot/firmware/config.txt
```

**For specific HDMI mode**:
```
hdmi_group=2
hdmi_mode=82  # 1920x1080 @ 60Hz
```

**Common modes**:
- Mode 4: 1280x720 @ 60Hz
- Mode 16: 1024x768 @ 60Hz
- Mode 82: 1920x1080 @ 60Hz

**Save and reboot**:
```bash
sudo kiosk-overlay enable
sudo reboot
```

### Adjust Image Viewer Settings

**Edit viewer script**:
```bash
sudo kiosk-overlay disable
sudo reboot

sudo nano /opt/kiosk/scripts/image-viewer.sh
```

**Useful fbi options**:
- `--timeout 5`: Auto-advance every 5 seconds
- `--once`: Display images once and exit
- `--random`: Random order

**Save and test**:
```bash
sudo systemctl restart kiosk-display.service
```

### Change Image Directory

**Edit service file**:
```bash
sudo nano /etc/systemd/system/kiosk-display.service
```

**Edit script**:
```bash
sudo nano /opt/kiosk/scripts/image-viewer.sh
# Change: IMAGE_DIR="/opt/kiosk/images"
```

**Reload and restart**:
```bash
sudo systemctl daemon-reload
sudo systemctl restart kiosk-display.service
```

---

## Troubleshooting

### Service Keeps Restarting

**Check logs**:
```bash
sudo journalctl -u kiosk-display.service -n 50
```

**Common causes**:
1. No images in directory
2. Incorrect file permissions
3. Corrupted image files

**Fix**:
```bash
# Verify images exist
ls -lh /opt/kiosk/images/

# Fix permissions
sudo chown -R root:root /opt/kiosk/images/
sudo chmod 644 /opt/kiosk/images/*

# Test with known-good image
sudo cp /usr/share/pixmaps/debian-logo.png /opt/kiosk/images/test.png
sudo systemctl restart kiosk-display.service
```

### Screen Blanking

**Disable screen blanking permanently**:
```bash
sudo kiosk-overlay disable
sudo reboot

# Add to /etc/rc.local (before 'exit 0'):
sudo nano /etc/rc.local
```

Add:
```bash
setterm -blank 0 -powerdown 0 -powersave off
```

### Keyboard Not Responding

**Test keyboard**:
```bash
# Switch to console (Alt+F2)
# Login and test:
sudo showkey -a
# Press keys to verify detection
```

**Restart service**:
```bash
sudo systemctl restart kiosk-display.service
```

### Out of Memory (OOM)

**Check memory usage**:
```bash
free -h
sudo dmesg | grep -i "out of memory"
```

**Solutions**:
1. Reduce image sizes (pre-scale images)
2. Increase GPU memory in `/boot/firmware/config.txt`:
   ```
   gpu_mem=512
   ```
3. Reduce number of images loaded at once

### Cannot Disable Overlay Mode

**Force disable via SD card**:
1. Shutdown Pi
2. Remove SD card
3. Insert SD card into computer
4. Edit `cmdline.txt` in boot partition
5. Remove ` boot=overlay` from the line
6. Save, eject, and boot Pi

---

## Backup and Recovery

### Backup Configuration

**Create backup**:
```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# Backup kiosk directory
sudo tar -czf /tmp/kiosk-backup.tar.gz /opt/kiosk

# Copy to USB
sudo mount /dev/sda1 /mnt/usb
sudo cp /tmp/kiosk-backup.tar.gz /mnt/usb/
sudo umount /mnt/usb
```

### Restore Configuration

**Restore backup**:
```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# Restore from USB
sudo mount /dev/sda1 /mnt/usb
sudo tar -xzf /mnt/usb/kiosk-backup.tar.gz -C /
sudo umount /mnt/usb

# Verify
ls -lh /opt/kiosk/images/

# Re-enable overlay
sudo kiosk-overlay enable
sudo reboot
```

### Clone SD Card

**Best practice**: Clone working SD card for backup

1. Shutdown Pi and remove SD card
2. Use disk imaging tool on computer:
   - **Windows**: Win32DiskImager
   - **macOS**: `dd` or Disk Utility
   - **Linux**: `dd` command

**Linux example**:
```bash
# Create image
sudo dd if=/dev/sdX of=kiosk-backup.img bs=4M status=progress

# Compress
gzip kiosk-backup.img

# Restore later
gunzip kiosk-backup.img.gz
sudo dd if=kiosk-backup.img of=/dev/sdX bs=4M status=progress
```

---

## Scheduled Maintenance

### Monthly Checklist

- [ ] Check system logs for errors
- [ ] Verify all images display correctly
- [ ] Check SD card health (if possible)
- [ ] Verify overlay mode is enabled
- [ ] Test keyboard navigation
- [ ] Check display output quality

### Quarterly Checklist

- [ ] Update Raspberry Pi OS (if needed)
- [ ] Check for kiosk software updates
- [ ] Clean dust from Pi and display
- [ ] Verify all cables are secure
- [ ] Test power failure recovery

### Annual Checklist

- [ ] Replace SD card (preventive maintenance)
- [ ] Update to latest Raspberry Pi OS
- [ ] Review and update images
- [ ] Verify backup/restore procedure
- [ ] Document any configuration changes

---

## Support

For assistance:
- Check logs: `sudo journalctl -u kiosk-display.service -f`
- GitHub Issues: https://github.com/yourusername/razem-kiosk/issues
- Documentation: https://github.com/yourusername/razem-kiosk
