# Raspberry Pi Kiosk - Installation Guide

This guide provides step-by-step instructions for setting up the Raspberry Pi Kiosk display system.

## Distribution Choice

Choose your distribution:
- **Raspberry Pi OS (Debian)** - Best for Pi 4, familiar environment
- **Fedora IoT (RPM)** - Best for Pi 3+, built-in immutability, modern updates

## Installation Methods

Choose the method that best fits your needs:

1. **Pre-Built Image (Recommended)** - Flash and boot, no installation needed
2. **Manual Installation** - Install on existing system

## Hardware Requirements

- **Raspberry Pi**:
  - Raspberry Pi 3B/3B+ (64-bit, 1GB RAM)
  - Raspberry Pi 4 Model B (2GB+ RAM recommended)
  - Raspberry Pi 400
- **SD Card**: 8GB minimum, 16GB recommended
- **Display**: HDMI-compatible monitor or TV
- **USB Keyboard**: For image navigation
- **Power Supply**: Official Raspberry Pi power supply (3A for Pi 4, 2.5A for Pi 3+)

---

## Method 1: Pre-Built Image (Recommended)

### Choose Your Distribution

#### Option A: Raspberry Pi OS Image

Best for Pi 4, familiar Debian environment.

**Step 1: Download the Kiosk Image**

1. Download the latest **razem-kiosk** image:
   - From GitHub Releases: `https://github.com/yourusername/razem-kiosk/releases`
   - File: `razem-kiosk-YYYY-MM-DD.img.zip`

2. Extract the `.img` file from the zip archive

#### Option B: Fedora IoT Image

Best for Pi 3+, built-in immutability, modern updates.

**Step 1: Download the Fedora IoT Kiosk Image**

1. Download the latest **razem-kiosk-fedora** image:
   - From GitHub Releases: `https://github.com/yourusername/razem-kiosk/releases`
   - File: `razem-kiosk-fedora-YYYY-MM-DD.raw.xz`

2. Image is compressed with xz (will extract during flashing)

### Step 2: Flash the Image

#### For Raspberry Pi OS (.img file):

**Using Raspberry Pi Imager (Recommended):**

1. Download and install [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Insert SD card into your computer
3. Open Raspberry Pi Imager
4. Click **"Choose OS"** → **"Use custom"**
5. Select the extracted `razem-kiosk-*.img` file
6. Click **"Choose Storage"** → Select your SD card
7. Click **"Write"** and wait for completion

**Using Command Line (Linux/macOS):**

```bash
# Find your SD card device
lsblk  # or diskutil list on macOS

# Flash image (replace /dev/sdX with your SD card)
sudo dd if=razem-kiosk-*.img of=/dev/sdX bs=4M status=progress conv=fsync

# On macOS:
sudo dd if=razem-kiosk-*.img of=/dev/rdiskX bs=4m
```

#### For Fedora IoT (.raw.xz file):

**Using Command Line (Recommended):**

```bash
# Find your SD card device
lsblk  # Look for your SD card (e.g., /dev/sdb)

# Option 1: Extract then flash
xz -d razem-kiosk-fedora-*.raw.xz
sudo dd if=razem-kiosk-fedora-*.raw of=/dev/sdX bs=4M status=progress conv=fsync

# Option 2: Stream directly (saves disk space)
xz -dc razem-kiosk-fedora-*.raw.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync

# Sync to ensure all data is written
sudo sync
```

**Using Balena Etcher (All Images):**

1. Download [Balena Etcher](https://www.balena.io/etcher/)
2. Select image file (.img or .raw.xz)
3. Select SD card
4. Click "Flash!" (Etcher handles compressed files automatically)

### Step 3: First Boot

1. Insert SD card into Raspberry Pi
2. Connect HDMI display and USB keyboard
3. Connect power supply
4. Wait for boot (silent boot, no console messages)
5. System will display a message that no images are found

**Default Credentials (Both Distributions):**
- Username: `pi`
- Password: `raspberry`
- Hostname: `kiosk.local`

⚠️ **IMPORTANT**: Change the default password on first login!

**Boot Differences:**
- **Raspberry Pi OS**: ~20-30 seconds to kiosk display
- **Fedora IoT**: ~30-45 seconds first boot (ostree setup), ~20 seconds subsequent boots

### Step 4: Add Your Images

**Via SSH (Recommended):**

```bash
# From your computer, connect via SSH
ssh pi@kiosk.local

# Change password
passwd

# Copy images from USB drive
sudo mount /dev/sda1 /mnt
sudo cp /mnt/images/*.jpg /opt/kiosk/images/
sudo umount /mnt

# Or copy via SCP from your computer:
# scp *.jpg pi@kiosk.local:/tmp/
# sudo mv /tmp/*.jpg /opt/kiosk/images/
```

**Via USB Drive (No Network):**

1. Press **Alt+F2** to switch to console
2. Login as `pi`
3. Mount USB drive:
   ```bash
   sudo mount /dev/sda1 /mnt
   sudo cp /mnt/images/*.jpg /opt/kiosk/images/
   sudo umount /mnt
   ```
4. Restart service:
   ```bash
   sudo systemctl restart kiosk-display.service
   ```
5. Press **Alt+F1** to return to viewer

### Step 5: Enable Read-Only Protection

#### Raspberry Pi OS:

After testing that everything works:

```bash
ssh pi@kiosk.local
sudo kiosk-overlay enable
sudo reboot
```

Your kiosk is now in immortal mode (read-only overlay filesystem)!

#### Fedora IoT:

System is **already immutable** via rpm-ostree! No additional setup needed.

To check immutability status:

```bash
ssh pi@kiosk.local
sudo kiosk-overlay status
# or
rpm-ostree status
```

Your kiosk is ready for production use!

---

## Method 2: Manual Installation on Existing OS

### Option A: Install on Raspberry Pi OS

#### Part 1: Prepare the SD Card

**Step 1: Download Raspberry Pi OS Lite**

1. Download **Raspberry Pi OS Lite (64-bit)** from:
   https://www.raspberrypi.com/software/operating-systems/

2. Use **Raspberry Pi Imager** or **Balena Etcher** to write the image to your SD card

### Option B: Install on Fedora IoT

#### Part 1: Prepare the SD Card

**Step 1: Download Fedora IoT ARM**

1. Download **Fedora IoT ARM aarch64** from:
   https://fedoraproject.org/iot/download

2. Extract and flash to SD card:
   ```bash
   xz -d Fedora-IoT-*.raw.xz
   sudo dd if=Fedora-IoT-*.raw of=/dev/sdX bs=4M status=progress conv=fsync
   ```

#### Step 2: Configure Initial Settings (Optional)

If you want SSH access for remote installation:

1. After writing the image, remount the SD card
2. Create an empty file named `ssh` in the boot partition
3. For WiFi access, create `wpa_supplicant.conf`:

```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourNetworkName"
    psk="YourPassword"
}
```

#### Step 3: Boot the Raspberry Pi

1. Insert the SD card into your Raspberry Pi
2. Connect keyboard, display, and power
3. Wait for boot to complete
4. Login with default credentials:
   - Username: `pi`
   - Password: `raspberry`

5. Change the default password:
   ```bash
   passwd
   ```

---

### Part 2: Install Kiosk Software

#### For Raspberry Pi OS:

**Automated Installation (Recommended):**

If the repository is publicly available:

```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/yourusername/razem-kiosk/main/scripts/install-kiosk.sh | sudo bash
```

**Manual Installation:**

If installing from a local copy:

```bash
# Install git
sudo apt-get update
sudo apt-get install -y git

# Clone repository
git clone https://github.com/yourusername/razem-kiosk.git
cd razem-kiosk

# Run installer
sudo ./scripts/install-kiosk.sh
```

#### For Fedora IoT:

**Manual Installation (Required):**

```bash
# Install git (if not present)
sudo rpm-ostree install git
sudo systemctl reboot

# After reboot, clone repository
git clone https://github.com/yourusername/razem-kiosk.git
cd razem-kiosk

# Run Fedora installer
sudo ./scripts/install-kiosk-fedora.sh

# Reboot to apply rpm-ostree changes
sudo systemctl reboot

# After reboot, run installer again to complete setup
cd razem-kiosk
sudo ./scripts/install-kiosk-fedora.sh
```

**Note for Fedora IoT**: The installer must be run twice - once to install packages (requires reboot), then again to configure the system.
sudo apt-get install -y git

# Clone repository
cd ~
git clone https://github.com/yourusername/razem-kiosk.git

# Run installer
cd razem-kiosk
sudo ./scripts/install-kiosk.sh
```

#### Option C: USB Drive Installation (No Internet Required)

1. Copy the entire `razem-kiosk` folder to a USB drive
2. Insert USB drive into Raspberry Pi
3. Mount the drive:
   ```bash
   sudo mkdir -p /mnt/usb
   sudo mount /dev/sda1 /mnt/usb
   ```
4. Run installer:
   ```bash
   cd /mnt/usb/razem-kiosk
   sudo ./scripts/install-kiosk.sh
   ```

---

### Part 3: Add Your Images

### Step 1: Prepare Images

- **Supported formats**: JPG, JPEG, PNG
- **Recommended resolution**: Match your display (e.g., 1920x1080 for Full HD)
- **File naming**: Images are displayed in alphabetical order
  - Use numeric prefixes for specific order: `001-image.jpg`, `002-image.jpg`, etc.

### Step 2: Copy Images to Kiosk

**Via USB drive:**
```bash
sudo mount /dev/sda1 /mnt/usb
sudo cp /mnt/usb/images/*.jpg /opt/kiosk/images/
sudo umount /mnt/usb
```

**Via SCP (from another computer):**
```bash
scp *.jpg pi@raspberrypi.local:/tmp/
ssh pi@raspberrypi.local
sudo mv /tmp/*.jpg /opt/kiosk/images/
```

**Via network share:**
```bash
# On Raspberry Pi, install smbclient
sudo apt-get install -y smbclient

# Copy from network share
sudo smbclient //server/share -U username -c "cd folder; mget *.jpg" -D /opt/kiosk/images/
```

### Step 3: Verify Images

```bash
# Check image count
ls -lh /opt/kiosk/images/

# Verify permissions
sudo chown -R root:root /opt/kiosk/images/
sudo chmod -R 644 /opt/kiosk/images/*.jpg
```

---

### Part 4: Test the System

### Step 1: Test Image Viewer Manually

```bash
# Start the viewer service
sudo systemctl start kiosk-display.service

# Check status
sudo systemctl status kiosk-display.service

# View logs in real-time
sudo journalctl -u kiosk-display.service -f
```

**Test keyboard controls:**
- Press **Left/Right arrow keys** to navigate
- Press **Space** for next image
- Press **Backspace** for previous image

### Step 2: Stop for Configuration Adjustments

```bash
# Stop the service
sudo systemctl stop kiosk-display.service
```

### Step 3: Test Auto-Start

```bash
# Reboot to test auto-start
sudo reboot
```

After reboot, the image viewer should start automatically.

---

### Part 5: Enable Read-Only Mode (Production)

⚠️ **IMPORTANT**: Only enable read-only mode after thoroughly testing!

### Why Read-Only Mode?

- **SD Card Protection**: Prevents wear from repeated writes
- **Corruption Prevention**: Survives power loss without filesystem damage
- **"Immortal" Operation**: Can be unplugged anytime without consequences

### Enable Overlay Filesystem

```bash
# Enable read-only overlay mode
sudo kiosk-overlay enable

# Reboot to activate
sudo reboot
```

### Verify Read-Only Mode

After reboot:
```bash
# Check overlay status
sudo kiosk-overlay status

# Try to create a test file (should fail or be temporary)
touch /home/pi/test.txt
ls -l /home/pi/
sudo reboot
ls -l /home/pi/  # File should be gone after reboot
```

---

## Maintenance (Both Methods)

### Updating Images (With Overlay Enabled)

```bash
# Disable overlay mode
sudo kiosk-overlay disable
sudo reboot

# After reboot, copy new images
sudo cp /mnt/usb/new-images/*.jpg /opt/kiosk/images/

# Re-enable overlay mode
sudo kiosk-overlay enable
sudo reboot
```

### System Updates

```bash
# Disable overlay
sudo kiosk-overlay disable
sudo reboot

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Re-enable overlay
sudo kiosk-overlay enable
sudo reboot
```

### Viewing Logs

```bash
# Real-time logs
sudo journalctl -u kiosk-display.service -f

# Last 50 lines
sudo journalctl -u kiosk-display.service -n 50

# Since last boot
sudo journalctl -u kiosk-display.service -b
```

### Emergency Access

If you need console access while viewer is running:

1. Press **Alt+F2** to switch to another virtual terminal
2. Login as `pi`
3. Make changes
4. Press **Alt+F1** to return to viewer

---

## Troubleshooting

### Black Screen After Boot

**Problem**: System boots but screen stays black.

**Solutions**:
1. Check HDMI cable connection
2. Try different HDMI port on Pi 4 (use port closest to power)
3. Add to `/boot/firmware/config.txt`:
   ```
   hdmi_force_hotplug=1
   hdmi_drive=2
   ```

### Images Don't Display

**Problem**: Viewer starts but shows error or blank screen.

**Solutions**:
1. Check if images exist:
   ```bash
   ls -lh /opt/kiosk/images/
   ```
2. Verify image format (fbi supports JPG, PNG, BMP, GIF)
3. Check permissions:
   ```bash
   sudo chmod 644 /opt/kiosk/images/*
   ```
4. Check logs:
   ```bash
   sudo journalctl -u kiosk-display.service -n 50
   ```

### Keyboard Not Working

**Problem**: Arrow keys don't navigate images.

**Solutions**:
1. Ensure USB keyboard is connected before boot
2. Try different USB port
3. Test keyboard in console (Alt+F2):
   ```bash
   sudo showkey  # Press keys to see if detected
   ```

### Service Fails to Start

**Problem**: `systemctl status kiosk-display.service` shows failed.

**Solutions**:
1. Check logs for specific error:
   ```bash
   sudo journalctl -u kiosk-display.service -xe
   ```
2. Test script manually:
   ```bash
   sudo /opt/kiosk/scripts/image-viewer.sh
   ```
3. Verify fbi is installed:
   ```bash
   which fbi
   ```
   **Raspberry Pi OS**: Should show `/usr/bin/fbi`
   **Fedora IoT**: Should show `/usr/bin/fbi`

   If not found:
   - Raspberry Pi OS: `sudo apt-get install fbi`
   - Fedora IoT: `sudo rpm-ostree install fbida && sudo systemctl reboot`

### Can't Boot After Enabling Overlay (Raspberry Pi OS Only)

**Problem**: System won't boot after enabling read-only mode.

**Solutions**:
1. Boot with overlay disabled:
   - Insert SD card into another computer
   - Edit `cmdline.txt` in boot partition
   - Remove ` boot=overlay` from the line
   - Save and boot normally

2. Or add kernel parameter at boot:
   - Press Shift during boot to access boot menu

**Note**: Fedora IoT doesn't use boot=overlay. System immutability is managed via rpm-ostree and cannot cause boot failures.

### Fedora IoT Specific Issues

#### Framebuffer Device Not Found

**Problem**: `ERROR: No framebuffer device found` in logs.

**Solution**:
Check if VC4 graphics driver is loaded:
```bash
# Check for framebuffer
ls -la /dev/fb*

# Check kernel modules
lsmod | grep vc4

# If missing, add to /etc/modules-load.d/vc4.conf
echo "vc4" | sudo tee /etc/modules-load.d/vc4.conf
sudo systemctl reboot
```

#### SELinux Denials

**Problem**: Service fails with "Permission denied" errors.

**Solution**:
```bash
# Check SELinux status
getenforce

# View denials
sudo ausearch -m avc -ts recent

# Fix contexts
sudo restorecon -R /opt/kiosk/

# If persistent issues, create policy or set permissive mode (not recommended for production)
# sudo setenforce 0
```

#### rpm-ostree Package Installation Failed

**Problem**: `rpm-ostree install` fails or hangs.

**Solution**:
```bash
# Check rpm-ostree status
rpm-ostree status

# Cancel pending deployment
rpm-ostree cleanup -p

# Try installation again
sudo rpm-ostree install fbida kbd
sudo systemctl reboot
```

#### System Updates Breaking Kiosk

**Problem**: After `rpm-ostree upgrade`, kiosk stops working.

**Solution**:
```bash
# Rollback to previous deployment
rpm-ostree rollback
sudo systemctl reboot

# After reboot, check what changed
rpm-ostree db diff

# Fix issues, then upgrade again
sudo rpm-ostree upgrade
```
   - Add `nooverlay` to kernel command line

---

## Performance Optimization

### Reduce Boot Time

Already configured by installer, but you can further optimize:

```bash
# Disable unused services
sudo systemctl disable bluetooth.service
sudo systemctl disable ModemManager.service
sudo systemctl disable wpa_supplicant.service  # Only if no WiFi needed
```

### Improve Image Quality

For best quality, pre-scale images to exact display resolution:

```bash
# Example: Batch resize to 1920x1080
sudo apt-get install -y imagemagick
cd /path/to/original/images
for img in *.jpg; do
    convert "$img" -resize 1920x1080^ -gravity center -extent 1920x1080 "/opt/kiosk/images/$img"
done
```

---

## Advanced Configuration

### Change Display Resolution

Edit `/boot/firmware/config.txt`:
```
hdmi_group=2
hdmi_mode=82  # 1920x1080 @ 60Hz

# Or force specific resolution:
hdmi_cvt=1920 1080 60
hdmi_group=2
hdmi_mode=87
```

### Disable WiFi/Bluetooth Completely

Edit `/boot/firmware/config.txt`:
```
dtoverlay=disable-wifi
dtoverlay=disable-bt
```

### Add Boot Splash Screen

1. Create a splash image: `/opt/kiosk/splash.png` (1920x1080)
2. Install plymouth:
   ```bash
   sudo apt-get install -y plymouth plymouth-themes
   ```
3. Configure splash (advanced, requires custom theme)

---

## Uninstall

To completely remove the kiosk system:

```bash
# Stop and disable service
sudo systemctl stop kiosk-display.service
sudo systemctl disable kiosk-display.service

# Remove files
sudo rm /etc/systemd/system/kiosk-display.service
sudo rm /etc/systemd/system/disable-blanking.service
sudo rm -rf /opt/kiosk
sudo rm /usr/local/bin/kiosk-overlay

# Restore boot configuration
sudo mv /boot/firmware/cmdline.txt.backup.* /boot/firmware/cmdline.txt
sudo mv /boot/firmware/config.txt.backup.* /boot/firmware/config.txt

# Remove auto-login
sudo rm -rf /etc/systemd/system/getty@tty1.service.d

# Reload systemd
sudo systemctl daemon-reload

# Reboot
sudo reboot
```

---

## Support

For issues, questions, or contributions:
- GitHub Issues: https://github.com/yourusername/razem-kiosk/issues
- Documentation: https://github.com/yourusername/razem-kiosk

---

## License

[Specify your license here]
