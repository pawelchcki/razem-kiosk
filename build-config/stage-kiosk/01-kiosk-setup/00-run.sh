#!/bin/bash -e

# Main kiosk setup script
# This script configures the kiosk system during image build

# Copy image files from centralized location
# stage-kiosk is symlinked from pi-gen/, so ../image-files points to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_FILES_DIR="$(cd "${SCRIPT_DIR}/../../../image-files" && pwd)"

# Create directory structure in rootfs
mkdir -p "${ROOTFS_DIR}/opt/kiosk/"{images,scripts,logs}
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"

# Copy kiosk scripts
cp "${IMAGE_FILES_DIR}/opt/kiosk/scripts/"*.sh "${ROOTFS_DIR}/opt/kiosk/scripts/"

# Copy systemd service
cp "${IMAGE_FILES_DIR}/etc/systemd/system/kiosk-display.service" "${ROOTFS_DIR}/etc/systemd/system/"

on_chroot << EOF
# Set ownership and permissions
chown -R ${FIRST_USER_NAME}:${FIRST_USER_NAME} /opt/kiosk
chmod 755 /opt/kiosk/scripts/*.sh

# Enable kiosk-display service
systemctl enable kiosk-display.service

# Configure auto-login for console
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${FIRST_USER_NAME} --noclear %I \\\$TERM
AUTOLOGIN

# Disable screen blanking in console
cat >> /home/${FIRST_USER_NAME}/.bashrc <<BASHRC

# Disable screen blanking for kiosk
if [ "\\\$(tty)" = "/dev/tty1" ]; then
    setterm -blank 0 -powerdown 0 -powersave off 2>/dev/null || true
fi
BASHRC

# Disable unnecessary services to speed up boot
systemctl disable bluetooth.service
systemctl disable avahi-daemon.service
systemctl disable triggerhappy.service
systemctl disable apt-daily.service
systemctl disable apt-daily-upgrade.service

# Disable swap (improves performance and SD card longevity)
systemctl disable dphys-swapfile.service

EOF

# Modify boot configuration files
# Note: In pi-gen, /boot/firmware is the boot partition

# Append silent boot parameters to cmdline.txt
if [ -f "${ROOTFS_DIR}/boot/firmware/cmdline.txt" ]; then
    # Read current cmdline
    CMDLINE=$(cat "${ROOTFS_DIR}/boot/firmware/cmdline.txt")

    # Remove any existing quiet/loglevel parameters
    CMDLINE=$(echo "$CMDLINE" | sed 's/quiet//g' | sed 's/loglevel=[0-9]//g' | sed 's/console=tty1//g' | sed 's/logo.nologo//g' | sed 's/vt.global_cursor_default=[0-9]//g' | sed 's/boot_delay=[0-9]//g' | sed 's/disable_splash=[0-9]//g')

    # Add our parameters (console=tty3 to hide boot messages)
    echo "$CMDLINE quiet loglevel=0 console=tty3 logo.nologo vt.global_cursor_default=0 boot_delay=0 disable_splash=1" > "${ROOTFS_DIR}/boot/firmware/cmdline.txt"
fi

# Append hardware configuration to config.txt
cat >> "${ROOTFS_DIR}/boot/firmware/config.txt" <<CONFIGTXT

# Raspberry Pi Kiosk Display Configuration
[all]
# GPU Memory (enough for framebuffer image display)
gpu_mem=256

# HDMI Configuration
hdmi_force_hotplug=1
disable_overscan=1

# Disable unused hardware to speed up boot
dtoverlay=disable-bt
# WiFi is left enabled for remote management via SSH
# Uncomment to disable: dtoverlay=disable-wifi

# Disable audio if not needed
dtparam=audio=off

# Disable camera if not needed
start_x=0

# Boot optimizations
boot_delay=0
disable_splash=1

# Framebuffer configuration
framebuffer_width=1920
framebuffer_height=1080
framebuffer_depth=24
CONFIGTXT

echo "Kiosk setup completed"
