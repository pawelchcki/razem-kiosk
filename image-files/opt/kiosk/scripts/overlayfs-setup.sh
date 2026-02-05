#!/bin/bash
# Raspberry Pi Kiosk - Read-Only Filesystem Setup
# This script configures the system to use an overlay filesystem for SD card protection

set -e

CMDLINE_FILE="/boot/firmware/cmdline.txt"
# Fallback to old boot location if new one doesn't exist
if [ ! -f "$CMDLINE_FILE" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
fi

echo "=== Raspberry Pi Kiosk - Overlay Filesystem Setup ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Function to enable overlay mode
enable_overlay() {
    echo "Enabling overlay filesystem..."

    # Check if overlay is already enabled
    if grep -q "boot=overlay" "$CMDLINE_FILE"; then
        echo "Overlay mode is already enabled in $CMDLINE_FILE"
        return 0
    fi

    # Backup cmdline.txt
    cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup"

    # Add boot=overlay to cmdline.txt
    sed -i 's/$/ boot=overlay/' "$CMDLINE_FILE"

    echo "Overlay mode enabled. System will boot in read-only mode after reboot."
}

# Function to disable overlay mode
disable_overlay() {
    echo "Disabling overlay filesystem..."

    # Check if overlay is currently enabled
    if ! grep -q "boot=overlay" "$CMDLINE_FILE"; then
        echo "Overlay mode is not currently enabled."
        return 0
    fi

    # Backup cmdline.txt
    cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup"

    # Remove boot=overlay from cmdline.txt
    sed -i 's/ boot=overlay//' "$CMDLINE_FILE"

    echo "Overlay mode disabled. System will boot in read-write mode after reboot."
}

# Function to optimize system for overlay mode
optimize_system() {
    echo "Optimizing system for read-only operation..."

    # Disable swap
    echo "- Disabling swap..."
    systemctl disable dphys-swapfile.service 2>/dev/null || true

    # Configure tmpfs for logs and tmp
    echo "- Configuring tmpfs for volatile directories..."
    if ! grep -q "tmpfs /var/log tmpfs" /etc/fstab; then
        echo "tmpfs /var/log tmpfs nodev,nosuid,size=32M 0 0" >> /etc/fstab
    fi
    if ! grep -q "tmpfs /tmp tmpfs" /etc/fstab; then
        echo "tmpfs /tmp tmpfs nodev,nosuid,size=64M 0 0" >> /etc/fstab
    fi
    if ! grep -q "tmpfs /var/tmp tmpfs" /etc/fstab; then
        echo "tmpfs /var/tmp tmpfs nodev,nosuid,size=16M 0 0" >> /etc/fstab
    fi

    # Disable unnecessary services
    echo "- Disabling unnecessary services..."
    systemctl disable bluetooth.service 2>/dev/null || true
    systemctl disable triggerhappy.service 2>/dev/null || true
    systemctl disable avahi-daemon.service 2>/dev/null || true

    echo "System optimization complete."
}

# Show current status
show_status() {
    echo "=== Current Overlay Status ==="
    if grep -q "boot=overlay" "$CMDLINE_FILE"; then
        echo "Status: ENABLED (read-only mode)"
    else
        echo "Status: DISABLED (read-write mode)"
    fi
    echo ""
}

# Main menu
case "${1:-}" in
    enable)
        enable_overlay
        optimize_system
        echo ""
        echo "IMPORTANT: Reboot required for changes to take effect."
        echo "Run: sudo reboot"
        ;;
    disable)
        disable_overlay
        echo ""
        echo "IMPORTANT: Reboot required for changes to take effect."
        echo "After reboot, you can make changes to the system."
        echo "Run: sudo reboot"
        ;;
    status)
        show_status
        ;;
    optimize)
        optimize_system
        ;;
    *)
        show_status
        echo "Usage: $0 {enable|disable|status|optimize}"
        echo ""
        echo "Commands:"
        echo "  enable   - Enable read-only overlay filesystem (requires reboot)"
        echo "  disable  - Disable overlay, return to read-write mode (requires reboot)"
        echo "  status   - Show current overlay status"
        echo "  optimize - Optimize system for read-only operation"
        echo ""
        echo "Examples:"
        echo "  sudo $0 enable    # Enable immortal mode"
        echo "  sudo $0 disable   # Disable for maintenance"
        exit 1
        ;;
esac
