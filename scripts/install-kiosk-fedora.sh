#!/bin/bash
# Fedora IoT Kiosk Manual Installation Script
# Installs and configures the kiosk system on an existing Fedora IoT installation

set -e

echo "=== Fedora IoT Kiosk Manual Installer ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Check if running on Fedora IoT
if ! command -v rpm-ostree &> /dev/null; then
    echo "ERROR: This script is for Fedora IoT systems only"
    echo "For Raspberry Pi OS, use: scripts/install-kiosk.sh"
    exit 1
fi

echo "Detected Fedora IoT system"
echo ""

# Step 1: Install required packages
echo "Step 1: Installing required packages..."
echo "  - fbida (contains fbi framebuffer image viewer)"
echo "  - kbd (keyboard tools)"
echo ""

if ! rpm -q fbida &> /dev/null || ! rpm -q kbd &> /dev/null; then
    echo "Installing packages via rpm-ostree..."
    rpm-ostree install fbida kbd
    echo ""
    echo "Packages installed. System needs to reboot to apply changes."
    echo "After reboot, run this script again to continue configuration."
    echo ""
    read -p "Reboot now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl reboot
    else
        echo "Please reboot manually and run this script again."
        exit 0
    fi
else
    echo "Packages already installed."
fi

# Step 2: Create kiosk user
echo ""
echo "Step 2: Creating kiosk user (pi)..."
if ! id "pi" &>/dev/null; then
    useradd -m -G wheel pi
    echo 'pi:raspberry' | chpasswd
    echo "  User 'pi' created with password 'raspberry'"
    echo "  WARNING: Change this password in production!"
else
    echo "  User 'pi' already exists"
fi

# Step 3: Install kiosk scripts and service
echo ""
echo "Step 3: Installing kiosk scripts and service..."

# Create directories
mkdir -p /opt/kiosk/scripts
mkdir -p /opt/kiosk/images
mkdir -p /opt/kiosk/logs

# Copy Fedora-specific scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -d "$PROJECT_ROOT/build-config-fedora/files/opt/kiosk/scripts" ]; then
    cp -r "$PROJECT_ROOT/build-config-fedora/files/opt/kiosk/scripts/"* /opt/kiosk/scripts/
    chmod 755 /opt/kiosk/scripts/*.sh
    echo "  Fedora-specific scripts copied to /opt/kiosk/scripts/"
else
    echo "  ERROR: Fedora scripts not found in $PROJECT_ROOT/build-config-fedora/files/opt/kiosk/scripts"
    exit 1
fi

# Copy systemd service
if [ -f "$PROJECT_ROOT/image-files/etc/systemd/system/kiosk-display.service" ]; then
    cp "$PROJECT_ROOT/image-files/etc/systemd/system/kiosk-display.service" /etc/systemd/system/
    echo "  Service file copied to /etc/systemd/system/"
else
    echo "  ERROR: Service file not found"
    exit 1
fi

# Create symlink for kiosk-overlay command
ln -sf /opt/kiosk/scripts/overlayfs-setup.sh /usr/local/bin/kiosk-overlay
echo "  Symlink created: /usr/local/bin/kiosk-overlay"

# Step 4: Configure auto-login
echo ""
echo "Step 4: Configuring auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

echo "  Auto-login configured for user 'pi' on tty1"

# Step 5: Configure silent boot
echo ""
echo "Step 5: Configuring silent boot (kernel arguments)..."

# Add kernel arguments via rpm-ostree
rpm-ostree kargs \
    --append-if-missing='quiet' \
    --append-if-missing='loglevel=0' \
    --append-if-missing='console=tty3' \
    --append-if-missing='vt.global_cursor_default=0' \
    --append-if-missing='systemd.show_status=false' \
    --append-if-missing='rd.udev.log_level=3'

echo "  Silent boot kernel arguments applied"

# Step 6: Disable unnecessary services
echo ""
echo "Step 6: Disabling unnecessary services..."
systemctl disable bluetooth.service 2>/dev/null || true
systemctl disable avahi-daemon.service 2>/dev/null || true
echo "  Unnecessary services disabled"

# Step 7: Enable kiosk service
echo ""
echo "Step 7: Enabling kiosk display service..."
systemctl daemon-reload
systemctl enable kiosk-display.service
echo "  kiosk-display.service enabled"

# Step 8: Add sample image
echo ""
echo "Step 8: Adding sample image..."
if [ ! -f /opt/kiosk/images/sample.png ]; then
    # Create a simple placeholder text file as a placeholder
    cat > /opt/kiosk/images/README.txt << EOF
Place your .jpg or .png images in this directory.
They will be displayed on the screen when the kiosk service starts.

Example:
  sudo cp my-image.jpg /opt/kiosk/images/
  sudo systemctl restart kiosk-display.service
EOF
    echo "  README.txt created in /opt/kiosk/images/"
    echo "  Please add your own images to /opt/kiosk/images/"
else
    echo "  Images already present"
fi

# Summary
echo ""
echo "==================================="
echo "✓ Installation complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Add your images to /opt/kiosk/images/"
echo "  2. Reboot to apply all changes: sudo systemctl reboot"
echo "  3. After reboot, the kiosk will start automatically"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status kiosk-display.service  # Check service status"
echo "  sudo journalctl -u kiosk-display.service     # View logs"
echo "  sudo kiosk-overlay status                    # Check overlay status"
echo "  rpm-ostree status                            # Check system status"
echo ""
echo "Default login:"
echo "  Username: pi"
echo "  Password: raspberry"
echo "  (Change this password in production!)"
echo ""
