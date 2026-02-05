#!/bin/bash
# Raspberry Pi Kiosk - Master Installation Script
# Installs and configures the minimal kiosk display system

set -e

INSTALL_DIR="/opt/kiosk"
REPO_URL="https://github.com/yourusername/razem-kiosk"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  Raspberry Pi Kiosk - Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "WARNING: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Updating system..."
apt-get update
echo ""

echo "Step 2: Installing required packages..."
apt-get install -y fbi kbd
echo ""

echo "Step 3: Creating installation directory..."
mkdir -p "$INSTALL_DIR"/{images,scripts,logs}
echo ""

echo "Step 4: Copying configuration files..."

# Copy scripts
cp "$REPO_ROOT/scripts/image-viewer.sh" "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/image-viewer.sh"

cp "$REPO_ROOT/configs/overlayfs-setup.sh" "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/overlayfs-setup.sh"

# Create symlink for easy access
ln -sf "$INSTALL_DIR/scripts/overlayfs-setup.sh" /usr/local/bin/kiosk-overlay

# Copy systemd service
cp "$REPO_ROOT/systemd/kiosk-display.service" /etc/systemd/system/
systemctl daemon-reload

echo ""
echo "Step 5: Configuring boot parameters..."

# Determine boot directory location (new vs old Raspberry Pi OS)
BOOT_DIR="/boot/firmware"
if [ ! -d "$BOOT_DIR" ]; then
    BOOT_DIR="/boot"
fi

# Backup existing configuration
cp "$BOOT_DIR/cmdline.txt" "$BOOT_DIR/cmdline.txt.backup.$(date +%Y%m%d)"
cp "$BOOT_DIR/config.txt" "$BOOT_DIR/config.txt.backup.$(date +%Y%m%d)"

# Copy cmdline.txt (preserve PARTUUID)
CURRENT_PARTUUID=$(grep -oP 'PARTUUID=\S+' "$BOOT_DIR/cmdline.txt" | head -1)
if [ -n "$CURRENT_PARTUUID" ]; then
    sed "s/PARTUUID=XXXXXXXX-02/$CURRENT_PARTUUID/" "$REPO_ROOT/configs/cmdline.txt" > "$BOOT_DIR/cmdline.txt"
else
    cp "$REPO_ROOT/configs/cmdline.txt" "$BOOT_DIR/cmdline.txt"
fi

# Append config.txt settings (don't overwrite existing)
echo "" >> "$BOOT_DIR/config.txt"
echo "# Kiosk Display Settings - Added by install script" >> "$BOOT_DIR/config.txt"
cat "$REPO_ROOT/configs/config.txt" >> "$BOOT_DIR/config.txt"

echo ""
echo "Step 6: Configuring auto-login..."

# Create autologin directory if it doesn't exist
mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create override file for auto-login
cat > /etc/systemd/system/getty@tty1.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

systemctl enable getty@tty1.service

echo ""
echo "Step 7: Enabling kiosk display service..."
systemctl enable kiosk-display.service

echo ""
echo "Step 8: Disabling console blanking..."
# Disable screen blanking in console
cat > /etc/systemd/system/disable-blanking.service << EOF
[Unit]
Description=Disable console blanking
Before=kiosk-display.service

[Service]
Type=oneshot
ExecStart=/usr/bin/setterm -blank 0 -powerdown 0 -powersave off
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1

[Install]
WantedBy=multi-user.target
EOF

systemctl enable disable-blanking.service

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Add your images to: $INSTALL_DIR/images/"
echo "   Supported formats: .jpg, .jpeg, .png"
echo ""
echo "2. Test the viewer (without reboot):"
echo "   sudo systemctl start kiosk-display.service"
echo ""
echo "3. Check status:"
echo "   sudo systemctl status kiosk-display.service"
echo ""
echo "4. View logs:"
echo "   sudo journalctl -u kiosk-display.service -f"
echo ""
echo "5. When ready for production, enable read-only mode:"
echo "   sudo kiosk-overlay enable"
echo "   sudo reboot"
echo ""
echo "6. To disable read-only mode for maintenance:"
echo "   sudo kiosk-overlay disable"
echo "   sudo reboot"
echo ""
echo "Keyboard controls in viewer:"
echo "  - Left/Right arrows: Navigate images"
echo "  - Space: Next image"
echo "  - Backspace: Previous image"
echo "  - Q or Ctrl+C: Exit viewer (will auto-restart via systemd)"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo "=========================================="
